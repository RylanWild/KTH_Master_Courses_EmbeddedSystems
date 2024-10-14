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
	int n = 0;
	for(n = 0; n < x*y; n++){
		conversion(rgb_pix + 3*n, gray_pix + n);
		//printf("%f ", gray_pix[n]);
	}
}

int main(void) {

  printf("MicroC/OS-II-Vesion: %1.2f\n", (double) OSVersion()/100.0);
	INT8U value=0;
	INT8U current_image=0;
	INT8U err;	
	unsigned char* img = (unsigned char*) SHARED_ONCHIP_BASE;
while(1){
/*
	Task1
*/
		printf("Task1 start\n");

		PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
		PERF_START_MEASURING (PERFORMANCE_COUNTER_0_BASE);
		PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, SECTION_1);

		sram2sm_p3(image_sequence[current_image]);
		unsigned char* img1 = image_sequence[current_image];

		PERF_END(PERFORMANCE_COUNTER_0_BASE, SECTION_1);   
		/* Print report */
		perf_print_formatted_report
		(PERFORMANCE_COUNTER_0_BASE,            
		ALT_CPU_FREQ,        // defined in "system.h"
		1,                   // How many sections to print
		"Section 1"        // Display-name of section(s).
		);     	
		
		printf("Task1 complete\n");
/*
	Task2
*/	

		printf("Task2 start\n");
		PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
		PERF_START_MEASURING (PERFORMANCE_COUNTER_0_BASE);
		PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, SECTION_1);
		int h = *img1;
		int w = *(img1 + 1);
		unsigned char* data = (int*)(img1 + 3);
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
		"Section 2"        // Display-name of section(s).
		); 

		printf("Task2 complete\n");
/*
	Task3
*/	
		printf("Task3 start\n");
		PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
		PERF_START_MEASURING (PERFORMANCE_COUNTER_0_BASE);
		PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, SECTION_1);
		unsigned char* img2 =gray_pix;
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
		"Section 3"        // Display-name of section(s).
		); 

		printf("Task3 Complete\n");
				/* Increment the image pointer */
		current_image=(current_image+1) % sequence_length;
}
  return 0;
}



