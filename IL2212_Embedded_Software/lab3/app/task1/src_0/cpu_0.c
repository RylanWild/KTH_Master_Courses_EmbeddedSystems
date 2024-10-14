// Skeleton for lab 2
// 
// Task 1 writes periodically RGB-images to the shared memory
//
// No guarantees provided - if bugs are detected, report them in the Issue tracker of the github repository!

//SHARED_ONCHIP_BASE --> Shared memory of all cpu's



#include <stdio.h>
#include <stdlib.h>
#include "altera_avalon_performance_counter.h"
#include "includes.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"
#include "sys/alt_alarm.h"
#include "system.h"
#include "io.h"

#include "images.h"
#include "ascii_gray.h"

#define DEBUG 1

#define HW_TIMER_PERIOD 100 /* 100ms */

/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    task1_stk[TASK_STACKSIZE];
OS_STK    task2_stk[TASK_STACKSIZE];
OS_STK    task3_stk[TASK_STACKSIZE];		
OS_STK    StartTask_Stack[TASK_STACKSIZE]; 

/* Definition of Task Priorities */

#define STARTTASK_PRIO      1
#define TASK1_PRIORITY      7
#define TASK2_PRIORITY		9
#define TASK3_PRIORITY		8			//Higher priority
	
/* Definition of Task Periods (ms) */
#define TASK1_PERIOD 10000

#define SECTION_1 1



/*
 * Example function for copying a p3 image from sram to the shared on-chip mempry
 */
void sram2sm_p3(unsigned char* base)
{
	int x, y;
	unsigned char* shared;

	shared = (unsigned char*) SHARED_ONCHIP_BASE;

	int size_x = *base++;
	int size_y = *base++;
	int max_col= *base++;
	*shared++  = size_x;
	*shared++  = size_y;
	*shared++  = max_col;
	printf("The image is: %d x %d!! \n", size_x, size_y);
	for(y = 0; y < size_y; y++)
	for(x = 0; x < size_x; x++)
	{
		*shared++ = *base++; 	// R
		*shared++ = *base++;	// G
		*shared++ = *base++;	// B
	}
}

/*
 * Global variables
 */
int delay; // Delay of HW-timer 

/*
 * ISR for HW Timer
 */
alt_u32 alarm_handler(void* context)
{
  OSTmrSignal(); /* Signals a 'tick' to the SW timers */
  
  return delay;
}

// Semaphores
OS_EVENT *Task1TmrSem;

// Message Queues
OS_EVENT *Comm12Q;
OS_EVENT *Comm23Q;

void *Comm12Msg[1];
void *Comm23Msg[1];

// SW-Timer
OS_TMR *Task1Tmr;

void asciiSDF(int x, int y, unsigned char* pix, unsigned char* ascii){

	//Copy code from lab2
	//number of ascii values
	int nlevels = sizeof(asciiChars) / sizeof(char);

	//assign grayscale values to ascii
	int n = 0;	
	for(n = 0; n < x*y; n++){
		int leveln = pix[n] / nlevels;
		ascii[n] = asciiChars[leveln];
	}
} 

void conversion(unsigned char* rgb, unsigned char* gray){

	*gray = rgb[0] * 0.3125 + rgb[1] * 0.5625 + rgb[2] * 0.125;
}


void graySDF(int x, int y, unsigned char* rgb_pix, unsigned char* gray_pix){

	//Copy code from lab2
	// split into arrays of 3 [rgb]
	// apply conversion of each array
	// re-combine all arrays into single array	
	// return an array of doubles	
	int n = 0;
	for(n = 0; n < x*y; n++){
		conversion(rgb_pix + 3*n, gray_pix + n);
	}
}


/* Timer Callback Functions */ 
void Task1TmrCallback (void *ptmr, void *callback_arg){
  OSSemPost(Task1TmrSem);
}

void task1(void* pdata)
{
	INT8U err;
	INT8U value=0;
	INT8U current_image=0;
	unsigned char* img = (unsigned char*) SHARED_ONCHIP_BASE;

	while (1)
	{ 

		printf("Task1 start\n");

		PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
		PERF_START_MEASURING (PERFORMANCE_COUNTER_0_BASE);
		PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, SECTION_1);
		
		/* Measurement here */
//		sram2sm_p3(image_sequence[current_image]);

		unsigned char* img1 = image_sequence[current_image];

		// Send to Task2 message queue
		INT8U err1 = OS_ERR_Q_FULL;
		while(err1 == OS_ERR_Q_FULL){
 			err1 =  OSQPost(Comm12Q, img1);
		}

		OSSemPend(Task1TmrSem, 0, &err);

		/* Increment the image pointer */
		current_image=(current_image+1) % sequence_length;

		PERF_END(PERFORMANCE_COUNTER_0_BASE, SECTION_1);  

		/* Print report */
		perf_print_formatted_report
		(PERFORMANCE_COUNTER_0_BASE,            
		ALT_CPU_FREQ,        // defined in "system.h"
		1,                   // How many sections to print
		"task 1"        // Display-name of section(s).
		);  

		printf("Task1 complete\n");
	}
}




void task2_graySDF(){

	// Read message queue
	INT8U err;
	
	while(1){
		printf("Task2 start\n");

		unsigned char* img = OSQPend(Comm12Q, 0, &err);

		PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
		PERF_START_MEASURING (PERFORMANCE_COUNTER_0_BASE);
		PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, SECTION_1);

		int h = *img;
		int w = *(img + 1);
		unsigned char* data = (int*)(img + 3);
		//printf("w,h = %d,%d\n", w, h);

		// Call graysdf
		unsigned char* gray_pix = (unsigned char*)malloc(sizeof(unsigned char)*((w*h)+3));

		graySDF(w, h, data, gray_pix + 3);
	
		gray_pix[0] = h;
		gray_pix[1] = w;


		PERF_END(PERFORMANCE_COUNTER_0_BASE, SECTION_1);  

		/* Print report */
		perf_print_formatted_report
		(PERFORMANCE_COUNTER_0_BASE,            
		ALT_CPU_FREQ,        // defined in "system.h"
		1,                   // How many sections to print
		"task 2"        // Display-name of section(s).
		);  


		// Send to task3_asciiSDF
		INT8U err = OS_ERR_Q_FULL;
		while(err == OS_ERR_Q_FULL){
 			err =  OSQPost(Comm23Q, gray_pix);
		}

		printf("Task2 complete\n");
	}

}



void task3_asciiSDF(){

	//Read message queue
	INT8U err;

	while(1){

		printf("Task3 start\n");

		unsigned char* img2 = OSQPend(Comm23Q, 0, &err);

		PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
		PERF_START_MEASURING (PERFORMANCE_COUNTER_0_BASE);
		PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, SECTION_1);

		int h = *img2;
		int w = *(img2 + 1);
		unsigned char* data1 = img2 + 3;
		
		//Call asciSDF
		unsigned char* ascii_pix = (unsigned char*)malloc(sizeof(unsigned char)*((w*h)+3));

		//convert gray scale to ascii
		asciiSDF(h, w , data1, ascii_pix);

		//Print
		printAscii(ascii_pix, h, w);

		free(ascii_pix);
		free(img2);	

		PERF_END(PERFORMANCE_COUNTER_0_BASE, SECTION_1);  

		/* Print report */
		perf_print_formatted_report
		(PERFORMANCE_COUNTER_0_BASE,            
		ALT_CPU_FREQ,        // defined in "system.h"
		1,                   // How many sections to print
		"task 3"        // Display-name of section(s).
		);  

		printf("Task3 Complete\n");
	}
}


void StartTask(void* pdata)
{
  INT8U err;
  void* context;

  static alt_alarm alarm;     /* Is needed for timer ISR function */
  
  /* Base resolution for SW timer : HW_TIMER_PERIOD ms */
  delay = alt_ticks_per_second() * HW_TIMER_PERIOD / 1000; 
  printf("delay in ticks %d\n", delay);

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

   //Create Task1 Timer
   Task1Tmr = OSTmrCreate(0, //delay
                            TASK1_PERIOD/HW_TIMER_PERIOD, //period
                            OS_TMR_OPT_PERIODIC,
                            Task1TmrCallback, //OS_TMR_CALLBACK
                            (void *)0,
                            "Task1Tmr",
                            &err);
                            
   if (DEBUG) {
    if (err == OS_ERR_NONE) { //if creation successful
      printf("Task1Tmr created\n");
    }
   }
   
	//Create Message Queues
	Comm12Q = OSQCreate(&Comm12Msg[0], 1);
	Comm23Q = OSQCreate(&Comm23Msg[0], 1);

	OSQFlush(Comm12Q);
	OSQFlush(Comm23Q);	

	printf("Message queues created\n");

   /*
    * Start timers
    */
   
   //start Task1 Timer
   OSTmrStart(Task1Tmr, &err);
   
   if (DEBUG) {
    if (err == OS_ERR_NONE) { //if start successful
      printf("Task1Tmr started\n");
    }
   }


   /*
   * Creation of Kernel Objects
   */

  Task1TmrSem = OSSemCreate(0);   

  /*
   * Create statistics task
   */

  OSStatInit();

  /* 
   * Creating Tasks in the system 
   */

  err=OSTaskCreateExt(task1,
                  NULL,
                  (void *)&task1_stk[TASK_STACKSIZE-1],
                  TASK1_PRIORITY,
                  TASK1_PRIORITY,
                  task1_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);

  if (DEBUG) {
     if (err == OS_ERR_NONE) { //if start successful
      printf("Task1 created\n");
    }
   }  

	//Task 2
	OSTaskCreateExt(
	 task2_graySDF, // Pointer to task code
         NULL,      // Pointer to argument that is
                    // passed to task
         (void *)&task2_stk[TASK_STACKSIZE-1], // Pointer to top
						     // of task stack 
         TASK2_PRIORITY,
         TASK2_PRIORITY,
         task2_stk,
         TASK_STACKSIZE,
         NULL,
		 0);

	//Task3
	OSTaskCreateExt(
	 task3_asciiSDF, // Pointer to task code
         NULL,      // Pointer to argument that is
                    // passed to task
         (void *)&task3_stk[TASK_STACKSIZE-1], // Pointer to top
						     // of task stack 
        TASK3_PRIORITY,
         TASK3_PRIORITY,
         task3_stk,
        TASK_STACKSIZE,
         NULL,
		 0);

  printf("All Tasks and Kernel Objects generated!\n");

  /* Task deletes itself */

  OSTaskDel(OS_PRIO_SELF);
}


int main(void) {

  printf("MicroC/OS-II-Vesion: %1.2f\n", (double) OSVersion()/100.0);
     
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



