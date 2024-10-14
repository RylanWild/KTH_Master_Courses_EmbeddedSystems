
// File: TwoTasks.c

#include <stdio.h>
#include <stdlib.h>
#include "includes.h"
#include <string.h>
//#include<altera_avalon_performance_counter.h>

#define DEBUG 0

/* Definition of Task Stacks */
/* Stack grows from HIGH to LOW memory */
#define TASK_STACKSIZE 2048
OS_STK task1_stk[TASK_STACKSIZE];
OS_STK task2_stk[TASK_STACKSIZE];
OS_STK stat_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */
#define TASK1_PRIORITY 6 // highest priority
#define TASK2_PRIORITY 7
#define TASK_STAT_PRIORITY 12 // lowest priority


OS_EVENT *Semaphore;
OS_EVENT *SemaphoreA;
OS_EVENT *SemaphoreB;
enum TaskState
{
  STATE_0,
  STATE_1
};
enum TaskState task0_state = STATE_0;
enum TaskState task1_state = STATE_0;

INT8U err_handler;

void printStackSize(char *name, INT8U prio)
{
  INT8U err;
  OS_STK_DATA stk_data;

  err = OSTaskStkChk(prio, &stk_data);
  if (err == OS_NO_ERR)
  {
    if (DEBUG == 1)
      printf("%s (priority %d) - Used: %d; Free: %d\n",
             name, prio, stk_data.OSUsed, stk_data.OSFree);
  }
  else
  {
    if (DEBUG == 1)
      printf("Stack Check Error!\n");
  }
}

/* Prints a message and sleeps for given time interval */
void task1(void *pdata)
{
  while (1)
  {
    switch (task0_state)
    {
    case STATE_0:
      OSSemPend(Semaphore, 0, &err_handler);
      task1_state = STATE_0;
      printf("Task 0 - State 0\n");
      OSSemPost(Semaphore);
      OSSemPost(SemaphoreB);
      break;
    case STATE_1:
      OSSemPend(Semaphore, 0, &err_handler);
      task0_state = STATE_0;
      printf("Task 0 - State 1\n");
      OSSemPost(Semaphore);
      OSSemPost(SemaphoreA);
      break;
    default:
      break;
    }
    OSSemPend(SemaphoreA, 0, &err_handler);
  }
}

/* Prints a message and sleeps for given time interval */
void task2(void *pdata)
{
  while (1)
  {
    OSSemPend(SemaphoreB, 0, &err_handler);
    switch (task1_state)
    {
    case STATE_0:
      OSSemPend(Semaphore, 0, &err_handler);
      task1_state = STATE_1;
      printf("Task 1 - State 0\n");
      OSSemPost(Semaphore);
      OSSemPost(SemaphoreB);
      break;
    case STATE_1:
      OSSemPend(Semaphore, 0, &err_handler);
      task0_state = STATE_1;
      printf("Task 1 - State 1\n");
      OSSemPost(Semaphore);
      OSSemPost(SemaphoreA);
      break;
    default:
      break;
    }
  }
}

/* Printing Statistics */
void statisticTask(void *pdata)
{
  while (1)
  {
    // OSSemPend(Semaphore,0,&err_handler);
    printStackSize("Task1", TASK1_PRIORITY);
    printStackSize("Task2", TASK2_PRIORITY);
    printStackSize("StatisticTask", TASK_STAT_PRIORITY);
    // OSSemPost(Semaphore);
  }
}

/* The main function creates two task and starts multi-tasking */
int main(void)
{
  printf("Lab 3 - Two Tasks\n");

  Semaphore = OSSemCreate(1);
  SemaphoreA = OSSemCreate(0);
  SemaphoreB = OSSemCreate(0);

  OSTaskCreateExt(task1,                          // Pointer to task code
                  NULL,                           // Pointer to argument passed to task
                  &task1_stk[TASK_STACKSIZE - 1], // Pointer to top of task stack
                  TASK1_PRIORITY,                 // Desired Task priority
                  TASK1_PRIORITY,                 // Task ID
                  &task1_stk[0],                  // Pointer to bottom of task stack
                  TASK_STACKSIZE,                 // Stacksize
                  NULL,                           // Pointer to user supplied memory (not needed)
                  OS_TASK_OPT_STK_CHK |           // Stack Checking enabled
                      OS_TASK_OPT_STK_CLR         // Stack Cleared
  );

  OSTaskCreateExt(task2,                          // Pointer to task code
                  NULL,                           // Pointer to argument passed to task
                  &task2_stk[TASK_STACKSIZE - 1], // Pointer to top of task stack
                  TASK2_PRIORITY,                 // Desired Task priority
                  TASK2_PRIORITY,                 // Task ID
                  &task2_stk[0],                  // Pointer to bottom of task stack
                  TASK_STACKSIZE,                 // Stacksize
                  NULL,                           // Pointer to user supplied memory (not needed)
                  OS_TASK_OPT_STK_CHK |           // Stack Checking enabled
                      OS_TASK_OPT_STK_CLR         // Stack Cleared
  );

  if (DEBUG == 1)
  {
    OSTaskCreateExt(statisticTask,                 // Pointer to task code
                    NULL,                          // Pointer to argument passed to task
                    &stat_stk[TASK_STACKSIZE - 1], // Pointer to top of task stack
                    TASK_STAT_PRIORITY,            // Desired Task priority
                    TASK_STAT_PRIORITY,            // Task ID
                    &stat_stk[0],                  // Pointer to bottom of task stack
                    TASK_STACKSIZE,                // Stacksize
                    NULL,                          // Pointer to user supplied memory (not needed)
                    OS_TASK_OPT_STK_CHK |          // Stack Checking enabled
                        OS_TASK_OPT_STK_CLR        // Stack Cleared
    );
  }

  OSStart();
  return 0;
}
