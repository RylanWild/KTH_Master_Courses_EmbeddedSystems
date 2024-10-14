/* Cruise control skeleton for the IL 2206 embedded lab
 *
 * Maintainers:  Rodolfo Jordao (jordao@kth.se), George Ungereanu (ugeorge@kth.se)
 *
 * Description:
 *
 *   In this file you will find the "model" for the vehicle that is being simulated on top
 *   of the RTOS and also the stub for the control task that should ideally control its
 *   velocity whenever a cruise mode is activated.
 *
 *   The missing functions and implementations in this file are left as such for
 *   the students of the IL2206 course. The goal is that they get familiriazed with
 *   the real time concepts necessary for all implemented herein and also with Sw/Hw
 *   interactions that includes HAL calls and IO interactions.
 *
 *   If the prints prove themselves too heavy for the final code, they can
 *   be exchanged for alt_printf where hexadecimals are supported and also
 *   quite readable. This modification is easily motivated and accepted by the course
 *   staff.
 */
#include <stdio.h>
#include "system.h"
#include "includes.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"
#include "sys/alt_alarm.h"

#define DEBUG 1

#define HW_TIMER_PERIOD 100 /* 100ms */

/* Button Patterns */

#define GAS_PEDAL_FLAG      0x08
#define BRAKE_PEDAL_FLAG    0x04
#define CRUISE_CONTROL_FLAG 0x02
/* Switch Patterns */

#define TOP_GEAR_FLAG       0x00000002
#define ENGINE_FLAG         0x00000001
#define LOAD_MASK           0x000003F0

/* LED Patterns */

#define LED_RED_0 0x00000001 // Engine
#define LED_RED_1 0x00000002 // Top Gear
#define LED_RED_12 0x00001000
#define LED_RED_13 0x00002000
#define LED_RED_14 0x00004000
#define LED_RED_15 0x00008000
#define LED_RED_16 0x00010000
#define LED_RED_17 0x00020000

#define LED_GREEN_0 0x0001 // Cruise Control activated
#define LED_GREEN_2 0x0004 // Cruise Control Button
#define LED_GREEN_4 0x0010 // Brake Pedal
#define LED_GREEN_6 0x0040 // Gas Pedal

/*
 * Definition of Tasks
 */

#define TASK_STACKSIZE 2048

OS_STK StartTask_Stack[TASK_STACKSIZE]; 
OS_STK ControlTask_Stack[TASK_STACKSIZE]; 
OS_STK VehicleTask_Stack[TASK_STACKSIZE];
OS_STK ButtonIOTask_Stack[TASK_STACKSIZE];
OS_STK SwitchIOTask_Stack[TASK_STACKSIZE];
OS_STK ExtraLoadTask_Stack[TASK_STACKSIZE];
OS_STK WatchdogTask_Stack[TASK_STACKSIZE];
OS_STK OverloadTask_Stack[TASK_STACKSIZE];

// Task Priorities

#define STARTTASK_PRIO     5
#define WATCHDOGTASK_PRIO  6
#define VEHICLETASK_PRIO  10
#define CONTROLTASK_PRIO  12
#define BUTTONIOTASK_PRIO  13
#define SWITCHIOTASK_PRIO  14
#define EXTRALOADTASK_PRIO 15
#define OVERLOADTASK_PRIO 16

// Task Periods

#define CONTROL_PERIOD  300
#define VEHICLE_PERIOD  300

/*
 * Definition of Kernel Objects 
 */

// Mailboxes
OS_EVENT *Mbox_Throttle;
OS_EVENT *Mbox_Velocity;
OS_EVENT *Mbox_Brake;
OS_EVENT *Mbox_Engine;
OS_EVENT *Mbox_Gas;
OS_EVENT *Mbox_Gear;
OS_EVENT *Mbox_Load;

// Semaphores
OS_EVENT *VehicleTask_Semaphore; //Create Semaphore for vehicle task periodic calling
OS_EVENT *ControlTask_Semaphore; //Create Semaphore for control task periodic calling
OS_EVENT *Watchdog_Semaphore;;

// SW-Timer
OS_TMR *VehicleTask_Timer;  //Create a countdown timer for vehicle task
OS_TMR *ControlTask_Timer;  //Create a countdown timer for control task
OS_TMR *Watchdog_Timer;
BOOLEAN status;


/*
 * Types
 */
enum active {on = 2, off = 1};
enum active cruise_command = off; //Global variable of CRUISE_SIGNAL to be used called from Task ButtonIO

/*
 * Global variables
 */
int delay; // Delay of HW-timer 
INT16U led_green = 0; // Green LEDs
INT32U led_red = 0;   // Red LEDs
INT8U extra_load = 0;
INT8U check_signal = 0;
INT8U signal = 0;
INT16U detector_counter = 0;

void VehicleTask_Timer_Callback (void *p_arg)
{
  OSSemPost(VehicleTask_Semaphore); //Signal a semaphore to run vehicle task
}
void ControlTask_Timer_Callback (void *p_arg)
{
  OSSemPost(ControlTask_Semaphore); //Signal a semaphore to run control task
}
void Watchdog_Timer_Callback(void *p_arg)
{
  OSSemPost(Watchdog_Semaphore);
}

/*
 * Helper functions
 */

int buttons_pressed(void)
{
  return ~IORD_ALTERA_AVALON_PIO_DATA(D2_PIO_KEYS4_BASE);    
}

int switches_pressed(void)
{
  return IORD_ALTERA_AVALON_PIO_DATA(DE2_PIO_TOGGLES18_BASE);    
}

/*
 * ISR for HW Timer
 */
alt_u32 alarm_handler(void* context)
{
  OSTmrSignal(); /* Signals a 'tick' to the SW timers */

  return delay;
}

static int b2sLUT[] = {0x40, //0
  0x79, //1
  0x24, //2
  0x30, //3
  0x19, //4
  0x12, //5
  0x02, //6
  0x78, //7
  0x00, //8
  0x18, //9
  0x3F, //-
};

/*
 * convert int to seven segment display format
 */
int int2seven(int inval){
  return b2sLUT[inval];
}

/*
 * output current velocity on the seven segement display
 */
void show_velocity_on_sevenseg(INT8S velocity){
  int tmp = velocity;
  int out;
  INT8U out_high = 0;
  INT8U out_low = 0;
  INT8U out_sign = 0;

  if(velocity < 0){
    out_sign = int2seven(10);
    tmp *= -1;
  }else{
    out_sign = int2seven(0);
  }

  out_high = int2seven(tmp / 10);
  out_low = int2seven(tmp - (tmp/10) * 10);

  out = int2seven(0) << 21 |
    out_sign << 14 |
    out_high << 7  |
    out_low;
  IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_HEX_LOW28_BASE,out);
}

/*
 * shows the target velocity on the seven segment display (HEX5, HEX4)
 * when the cruise control is activated (0 otherwise)
 */
void show_target_velocity(INT8S target_vel)
{
  int tmp = target_vel;
  int out;
  INT8U out_high = 0;
  INT8U out_low = 0;
  INT8U out_sign = 0;

  if(target_vel < 0){
    out_sign = int2seven(10);
    tmp *= -1;
  }else{
    out_sign = int2seven(0);
  }

  out_high = int2seven(tmp / 10);
  out_low = int2seven(tmp - (tmp/10) * 10);

  out = int2seven(0) << 21 |
    out_sign << 14 |
    out_high << 7  |
    out_low;
  IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_HEX_HIGH28_BASE,out);
}

/*
 * indicates the position of the vehicle on the track with the four leftmost red LEDs
 * LEDR17: [0m, 400m)
 * LEDR16: [400m, 800m)
 * LEDR15: [800m, 1200m)
 * LEDR14: [1200m, 1600m)
 * LEDR13: [1600m, 2000m)
 * LEDR12: [2000m, 2400m]
 */
void show_position(INT16U position)
{
  if ((position >= 0) && (position < 400))
  {
    led_red |= LED_RED_17;  
    led_red &= ~(LED_RED_12|LED_RED_13|LED_RED_14|LED_RED_15|LED_RED_16);
  }
  else if (position >= 400  && position < 800)
  {
    led_red |= LED_RED_16;
    led_red &= ~(LED_RED_12|LED_RED_13|LED_RED_14|LED_RED_15|LED_RED_17);
  }
  else if (position >= 800 && position < 1200)
  {
    led_red |= LED_RED_15;
    led_red &= ~(LED_RED_12|LED_RED_13|LED_RED_14|LED_RED_16|LED_RED_17);
  }
  else if (position >= 1200 && position < 1600)
  {
    led_red |= LED_RED_14;
    led_red &= ~(LED_RED_12|LED_RED_13|LED_RED_15|LED_RED_16|LED_RED_17);
  }
  else if (position >= 1600 && position < 2000)
  {
    led_red |= LED_RED_13;
    led_red &= ~(LED_RED_12|LED_RED_14|LED_RED_15|LED_RED_16|LED_RED_17);
  }
  else if (position >= 2000 && position <= 2400)
  {
    led_red |= LED_RED_12;
    led_red &= ~(LED_RED_13|LED_RED_14|LED_RED_15|LED_RED_16|LED_RED_17);
  }
  IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE,led_red);
}

void ButtonIO(void* pdata)
{
  enum active gas_button = off;
  enum active brake_button = off;

  while(1)
  {
    int active_button  = buttons_pressed();  //Detect button pressed
    if (active_button != 0) //If there is a button being pressed
    {
      if (active_button & GAS_PEDAL_FLAG) //Check if it is GAS_PEDAL Button
      {
        gas_button = on;
        led_green |= LED_GREEN_6;
        OSMboxPost(Mbox_Gas,(void*)gas_button);
      } else
      {
        gas_button = off;
        led_green &= ~LED_GREEN_6;
        OSMboxPost(Mbox_Gas,(void*)gas_button);
      }
      
      if (active_button & BRAKE_PEDAL_FLAG) //Check if it is BRAKE_PEDAL Button
      {
        brake_button = on;
        led_green |= LED_GREEN_4;
        OSMboxPost(Mbox_Brake,(void*)brake_button);
      } else
      {
        brake_button = off;
        led_green &= ~LED_GREEN_4;
        OSMboxPost(Mbox_Brake,(void*)brake_button);
      }

      if ((active_button & CRUISE_CONTROL_FLAG) && (cruise_command == off)) //Check if it is CRUISE_CONTROL Button, and make sure it only can be turned on if we are not in cruise control
      {
        led_green |= LED_GREEN_2;
        cruise_command = on; //turn on cruise control command, we want to activate the cruise control by just pressing the button once not by holding it.
      } else
      {
        led_green &= ~LED_GREEN_2;
      } 
    } else
    {
      gas_button = off;
      brake_button = off;
      OSMboxPost(Mbox_Brake,(void*)brake_button);
      OSMboxPost(Mbox_Gas,(void*)gas_button);
      led_green &= ~(LED_GREEN_4|LED_GREEN_6); //Set the buttons to off state and set the corresponding LED off.
    }

    IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE,led_green); //write the state of the  green led
    OSTimeDlyHMSM(0,0,0,5);
  }
}

void SwitchIO(void* pdata)
{
  enum active engine_switch = off;
  enum active gear_switch = off;
  int switch_load = 0;

  while(1)
  {
    int active_switch  = switches_pressed(); //Detect active switches
    if (active_switch != 0)
    {
      if (active_switch & ENGINE_FLAG) //check if the engine switch is active
      {
        led_red |= LED_RED_0;
        engine_switch = on;
        OSMboxPost(Mbox_Engine, (void*) engine_switch);
        if(!(active_switch & TOP_GEAR_FLAG)) //also check if the gear switch is not active
        {
          led_red &= ~LED_RED_1;
          gear_switch = off;
          OSMboxPost(Mbox_Gear, (void*) gear_switch);  
        }
      }
      if (active_switch & TOP_GEAR_FLAG) //check if the gear switch is active
      {
        led_red |= LED_RED_1;
        gear_switch = on;
        OSMboxPost(Mbox_Gear, (void*) gear_switch);
        if(!(active_switch & ENGINE_FLAG)) //check if the engine switch is not active
        {
          led_red &= ~LED_RED_0;
          engine_switch = off;
          OSMboxPost(Mbox_Engine, (void*) engine_switch);  
        }
      }
      if (active_switch & LOAD_MASK)
      {
        switch_load = active_switch & LOAD_MASK;
        switch_load = switch_load >> 4;
        //OSMboxPost(Mbox_Load, (void *) switch_load);
        extra_load = (INT8U)switch_load;
        if(!(active_switch & ENGINE_FLAG)) //check if the engine switch is not active
        {
          led_red &= ~LED_RED_0;
          engine_switch = off;
          OSMboxPost(Mbox_Engine, (void*) engine_switch);  
        }
        if(!(active_switch & TOP_GEAR_FLAG)) //also check if the gear switch is not active
        {
          led_red &= ~LED_RED_1;
          gear_switch = off;
          OSMboxPost(Mbox_Gear, (void*) gear_switch);  
        } 
      }
            
    }
    else
    {
      gear_switch = off;
      engine_switch = off;
      OSMboxPost(Mbox_Engine, (void*) engine_switch);
      OSMboxPost(Mbox_Gear, (void*) gear_switch);
      led_red &= ~(LED_RED_0 | LED_RED_1); //Set the switches to off state and set the corresponding LED off.
    }
    IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_REDLED18_BASE,led_red);
    OSTimeDlyHMSM(0,0,0,5);
  }
}

void ExtraLoadTask(void* pdata)
{
  unsigned int load_delay_ms = 0;
  int i = 0;
  while (1)
  {
    load_delay_ms = (unsigned int) extra_load;
    for (i = 0; i <= 300*load_delay_ms; i++);    
    OSTimeDlyHMSM(0,0,0,20);
  }
}

void Watchdog(void* pdata)
{
  INT8U err;
  while(1)
  {
    OSSemPend(Watchdog_Semaphore,0,&err);
    if (detector_counter > 0)
    {
      detector_counter = 0;
      printf("OK!\n");
    }
    else
    {
      printf("Overload!\n");
    }
  }
}

void OverloadDetection(void* pdata)
{
  while(1)
  {
    detector_counter++;
    OSTimeDlyHMSM(0,0,0,1);
  }
}

/*
 * The task 'VehicleTask' is the model of the vehicle being simulated. It updates variables like
 * acceleration and velocity based on the input given to the model.
 * 
 * The car model is equivalent to moving mass with linear resistances acting upon it.
 * Therefore, if left one, it will stably stop as the velocity converges to zero on a flat surface.
 * You can prove that easily via basic LTI systems methods.
 */
void VehicleTask(void* pdata)
{ 
  // constants that should not be modified
  const unsigned int wind_factor = 1;
  const unsigned int brake_factor = 4;
  const unsigned int gravity_factor = 2;
  // variables relevant to the model and its simulation on top of the RTOS
  INT8U err;  
  void* msg;
  INT8U* throttle; 
  INT16S acceleration;  
  INT16U position = 0; 
  INT16S velocity = 0; 
  enum active brake_pedal = off;
  enum active engine = off;

  printf("Vehicle task created!\n");

  while(1)
  {
    OSSemPend(VehicleTask_Semaphore,0,&err);
    err = OSMboxPost(Mbox_Velocity, (void *) &velocity);

    //OSTimeDlyHMSM(0,0,0,VEHICLE_PERIOD); 

    /* Non-blocking read of mailbox: 
       - message in mailbox: update throttle
       - no message:         use old throttle
       */
    msg = OSMboxPend(Mbox_Throttle, 1, &err); 
    if (err == OS_NO_ERR) 
      throttle = (INT8U*) msg;
    /* Same for the brake signal that bypass the control law */
    msg = OSMboxPend(Mbox_Brake, 1, &err); 
    if (err == OS_NO_ERR) 
      brake_pedal = (enum active) msg;
    /* Same for the engine signal that bypass the control law */
    msg = OSMboxPend(Mbox_Engine, 1, &err); 
    if (err == OS_NO_ERR) 
      engine = (enum active) msg;


    // vehichle cannot effort more than 80 units of throttle
    if (*throttle > 80) *throttle = 80;

    // brakes + wind
    if (brake_pedal == off)
    {
      // wind resistance
      acceleration = - wind_factor*velocity;
      // actuate with engines
      if (engine == on)
        acceleration += (*throttle);

      // gravity effects
      if (400 <= position && position < 800)
        acceleration -= gravity_factor; // traveling uphill
      else if (800 <= position && position < 1200)
        acceleration -= 2*gravity_factor; // traveling steep uphill
      else if (1600 <= position && position < 2000)
        acceleration += 2*gravity_factor; //traveling downhill
      else if (2000 <= position)
        acceleration += gravity_factor; // traveling steep downhill
    }
    // if the engine and the brakes are activated at the same time,
    // we assume that the brake dynamics dominates, so both cases fall
    // here.
    else 
      acceleration = - brake_factor*velocity;

    printf("Position: %d m\n", position);
    printf("Velocity: %d m/s\n", velocity);
    printf("Accell: %d m/s2\n", acceleration);
    printf("Throttle: %d V\n", *throttle);

    position = position + velocity * VEHICLE_PERIOD / 1000;
    velocity = velocity  + acceleration * VEHICLE_PERIOD / 1000.0;
    // reset the position to the beginning of the track
    if(position > 2400)
      position = 0;

    show_velocity_on_sevenseg((INT8S) velocity);
    show_position(position); //turn the corresponding LED to indicate our position on track
  }
} 

/*
 * The task 'ControlTask' is the main task of the application. It reacts
 * on sensors and generates responses.
 */

void ControlTask(void* pdata)
{
  INT8U err;
  INT8U throttle = 0; /* Value between 0 and 80, which is interpreted as between 0.0V and 8.0V */
  void* msg;
  INT16S* current_velocity; //pointer to velocity value that being sent to control task from the vehicle task
  INT16S  target_velocity = 0; //to capture the target velocity to maintain when the cruise control is being executed
  INT16S  error;  //error between target velocity and the current velocity reading
  INT16S  integral = 0; //accumulate error for steady state error correction
  INT8U  do_once = 1; //a flag to capture the speed we want to maintain when the cruise control is being activated

  enum active gas_pedal = off;
  enum active top_gear = off;

  printf("Control Task created!\n");

  while(1)
  {
    OSSemPend(ControlTask_Semaphore,0,&err);
    msg = OSMboxPend(Mbox_Velocity, 0, &err);
    current_velocity = (INT16S*) msg;
    msg = OSMboxPend(Mbox_Gas, 0, &err);
    gas_pedal = (enum active) msg;
    msg = OSMboxPend(Mbox_Gear, 0, &err);
    top_gear = (enum active) msg;
    // Here you can use whatever technique or algorithm that you prefer to control
    // the velocity via the throttle. There are no right and wrong answer to this controller, so
    // be free to use anything that is able to maintain the cruise working properly. You are also
    // allowed to store more than one sample of the velocity. For instance, you could define
    //
    // INT16S previous_vel;
    // INT16S pre_previous_vel;
    // ...
    //
    // If your control algorithm/technique needs them in order to function. 

    if (gas_pedal == on) //check if the GAS_PEDAL Button being pressed
    {
      throttle = 60; //if so we can increase our throttle manualy
      cruise_command = off; //we don't want cruise control to be active when the GAS_PEDAL Button being pressed.
      show_target_velocity((INT8S)target_velocity); //show the target velocity and should be zero
    }
    else //The GAS_PEDAL is not being pressed
    {
      if(cruise_command == on) //Check if the cruise command is being activated
      {
        if ((*current_velocity >= 20) && (top_gear != off)) //executes cruise control only if the speed is above 20 and the top gear condition is high, release the GAS_PEDAL Button then press the CRUISE_CONTROL Button
        {
          if(do_once)// Capture the target velocity to maintain when the cruise control being activated
          {
            target_velocity = *current_velocity;  
            do_once = 0;
          }
          led_green |= LED_GREEN_0; //Light up the LED indicating we are in cruise control
          show_target_velocity((INT8S)target_velocity); //Display the target velocity in the 7Segment (HEX5 and HEX4)
          error = target_velocity - *current_velocity; //Calculates the error with respect to the target velocity and
          integral += error; //Accumulates the error for steady state correction
          throttle = ((5*error) + (1*integral)); // Implement PI Controller
          if(throttle <= 0) throttle = 0; //Limit the throttle output to 0 for non zero value
        } else
        {
          //if BRAKE_PEDAL Button is pressed (the speed drops directly below 20 when the BREAK_PEDAL Button is pressed, so it satisfies the requirement), or the TOP_GEAR Switch is switched to low, deactivates the cruise control
          cruise_command = off;
          target_velocity = 0;  
          show_target_velocity((INT8S)target_velocity);
        }
      }else
      {
        //resets everything related to cruise control, and set the  throttle  value back to manual control
        led_green &= ~LED_GREEN_0;
        do_once = 1;
        throttle = 0;
        target_velocity = 0;
        show_target_velocity((INT8S)target_velocity);
      }
    }
    IOWR_ALTERA_AVALON_PIO_DATA(DE2_PIO_GREENLED9_BASE, led_green);  
    err = OSMboxPost(Mbox_Throttle, (void *) &throttle);
  }
}

/* 
 * The task 'StartTask' creates all other tasks kernel objects and
 * deletes itself afterwards.
 */ 

void StartTask(void* pdata)
{
  INT8U err;
  void* context;

  static alt_alarm alarm;     /* Is needed for timer ISR function */

  /* Base resolution for SW timer : HW_TIMER_PERIOD ms */
  delay = alt_ticks_per_second() * HW_TIMER_PERIOD / 1000; 
  printf("delay in ticks %d\n", delay); // 100 tick according to the first run

  /* 
   * Create Hardware Timer with a period of 'delay' 
   */
  if (alt_alarm_start (&alarm,
        delay,
        alarm_handler,
        context) < 0)
  {
    printf("No system clock available!n");
  }

  /* 
   * Create and start Software Timer 
   */
  VehicleTask_Timer = OSTmrCreate(0,
                                  (VEHICLE_PERIOD/delay),
                                  OS_TMR_OPT_PERIODIC,
                                  VehicleTask_Timer_Callback,
                                  NULL,
                                  NULL,
                                  &err);
  if (err == OS_ERR_NONE)
  {
    printf("Vehicle Task Timer Created.\n");
  }
  status = OSTmrStart(VehicleTask_Timer,&err);
  if (err == OS_ERR_NONE)
  {
    printf("Vehicle Task Timer Started.\n");  
  }

  ControlTask_Timer = OSTmrCreate(0,
                                  (CONTROL_PERIOD/delay),
                                  OS_TMR_OPT_PERIODIC,
                                  ControlTask_Timer_Callback,
                                  NULL,
                                  NULL,
                                  &err);
  if (err == OS_ERR_NONE)
  {
    printf("Control Task Timer Created.\n");
  }
  status = OSTmrStart(ControlTask_Timer,&err);
  if (err == OS_ERR_NONE)
  {
    printf("Control Task Timer Started.\n");  
  }

  Watchdog_Timer = OSTmrCreate(0,
                               3,
                               OS_TMR_OPT_PERIODIC,
                               Watchdog_Timer_Callback,
                               NULL,
                               NULL,
                               &err);
  if (err == OS_ERR_NONE)
  {
    printf("Watchdog Timer Created.\n");
  }
  status = OSTmrStart(Watchdog_Timer,&err);
  if (err == OS_ERR_NONE)
  {
    printf("Watchdog Timer Started.\n");  
  }
  

  /*
   * Creation of Kernel Objects
   */

  // Mailboxes
  Mbox_Throttle = OSMboxCreate((void*) 0); /* Empty Mailbox - Throttle */
  Mbox_Velocity = OSMboxCreate((void*) 0); /* Empty Mailbox - Velocity */
  Mbox_Brake = OSMboxCreate((void*) 1); /* Empty Mailbox - Velocity */
  Mbox_Engine = OSMboxCreate((void*) 1); /* Empty Mailbox - Engine */
  Mbox_Gear = OSMboxCreate((void*) 0);
  Mbox_Gas = OSMboxCreate((void*) 0);

  /*
   * Create statistics task
   */

  OSStatInit();

  /* 
   * Creating Tasks in the system 
   */  

  err = OSTaskCreateExt(
      ControlTask, // Pointer to task code
      NULL,        // Pointer to argument that is
      // passed to task
      &ControlTask_Stack[TASK_STACKSIZE-1], // Pointer to top
      // of task stack
      CONTROLTASK_PRIO,
      CONTROLTASK_PRIO,
      (void *)&ControlTask_Stack[0],
      TASK_STACKSIZE,
      (void *) 0,
      OS_TASK_OPT_STK_CHK);

  err = OSTaskCreateExt(
      VehicleTask, // Pointer to task code
      NULL,        // Pointer to argument that is
      // passed to task
      &VehicleTask_Stack[TASK_STACKSIZE-1], // Pointer to top
      // of task stack
      VEHICLETASK_PRIO,
      VEHICLETASK_PRIO,
      (void *)&VehicleTask_Stack[0],
      TASK_STACKSIZE,
      (void *) 0,
      OS_TASK_OPT_STK_CHK);

  err = OSTaskCreateExt(
      ButtonIO, // Pointer to task code
      NULL,        // Pointer to argument that is
      // passed to task
      &ButtonIOTask_Stack[TASK_STACKSIZE-1], // Pointer to top
      // of task stack
      BUTTONIOTASK_PRIO,
      BUTTONIOTASK_PRIO,
      (void *)&ButtonIOTask_Stack[0],
      TASK_STACKSIZE,
      (void *) 0,
      OS_TASK_OPT_STK_CHK);
  
    err = OSTaskCreateExt(
      SwitchIO, // Pointer to task code
      NULL,        // Pointer to argument that is
      // passed to task
      &SwitchIOTask_Stack[TASK_STACKSIZE-1], // Pointer to top
      // of task stack
      SWITCHIOTASK_PRIO,
      SWITCHIOTASK_PRIO,
      (void *)&SwitchIOTask_Stack[0],
      TASK_STACKSIZE,
      (void *) 0,
      OS_TASK_OPT_STK_CHK);
      
    err = OSTaskCreateExt(
      ExtraLoadTask, // Pointer to task code
      NULL,        // Pointer to argument that is
      // passed to task
      &ExtraLoadTask_Stack[TASK_STACKSIZE-1], // Pointer to top
      // of task stack
      EXTRALOADTASK_PRIO,
      EXTRALOADTASK_PRIO,
      (void *)&ExtraLoadTask_Stack[0],
      TASK_STACKSIZE,
      (void *) 0,
      OS_TASK_OPT_STK_CHK);

    err = OSTaskCreateExt(
      Watchdog, // Pointer to task code
      NULL,        // Pointer to argument that is
      // passed to task
      &WatchdogTask_Stack[TASK_STACKSIZE-1], // Pointer to top
      // of task stack
      WATCHDOGTASK_PRIO,
      WATCHDOGTASK_PRIO,
      (void *)&WatchdogTask_Stack[0],
      TASK_STACKSIZE,
      (void *) 0,
      OS_TASK_OPT_STK_CHK);

    err = OSTaskCreateExt(
      OverloadDetection, // Pointer to task code
      NULL,        // Pointer to argument that is
      // passed to task
      &OverloadTask_Stack[TASK_STACKSIZE-1], // Pointer to top
      // of task stack
      OVERLOADTASK_PRIO,
      OVERLOADTASK_PRIO,
      (void *)&OverloadTask_Stack[0],
      TASK_STACKSIZE,
      (void *) 0,
      OS_TASK_OPT_STK_CHK);

  printf("All Tasks and Kernel Objects generated!\n");

  /* Task deletes itself */

  OSTaskDel(OS_PRIO_SELF);
}

/*
 *
 * The function 'main' creates only a single task 'StartTask' and starts
 * the OS. All other tasks are started from the task 'StartTask'.
 *
 */

int main(void) {

  printf("Lab: Cruise Control\n");
  VehicleTask_Semaphore = OSSemCreate(0);
  ControlTask_Semaphore = OSSemCreate(0);
  Watchdog_Semaphore = OSSemCreate(1);

  OSTaskCreateExt(
      StartTask, // Pointer to task code
      NULL,      // Pointer to argument that is
      // passed to task
      (void *)&StartTask_Stack[TASK_STACKSIZE-1], // Pointer to top
      // of task stack 
      STARTTASK_PRIO,
      STARTTASK_PRIO,
      (void *)&StartTask_Stack[0],
      TASK_STACKSIZE,
      (void *) 0,  
      OS_TASK_OPT_STK_CHK | OS_TASK_OPT_STK_CLR);

  OSStart();

  return 0;
}
