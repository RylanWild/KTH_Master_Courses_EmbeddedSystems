#include "images.h"
#include <stdio.h>
#include <stdlib.h>
#include "system.h"
#include "io.h"
#include "sys/alt_stdio.h"
#include "altera_avalon_pio_regs.h"
#include "altera_avalon_performance_counter.h"

#define TRUE 1

#define SECTION_1 1

extern void delay (int millisec);

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


int main()
{
  printf("Hello from cpu_0!\n");

		int current_image=0;

		//Init shared memory
		unsigned char* shared = (unsigned char*) SHARED_ONCHIP_BASE;
		unsigned char* sem12 = shared;
		//unsigned char* sem23 = shared + 1;
		unsigned char* width = shared + 2;
		unsigned char* height = shared + 3;
		unsigned char* img = shared + 5;

		//Cpu_1 already has the first sem
		*sem12 = 0;


  while (1){

		printf("GraySDF start\n");

		PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
		PERF_START_MEASURING (PERFORMANCE_COUNTER_0_BASE);
		PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, SECTION_1);

		unsigned char* img_orig = image_sequence[current_image];

		*height = *img_orig;
		*width = *(img_orig + 1);
		unsigned char* data = (int*)(img_orig + 3);

		// Call graysdf. Save output in shared memory
		graySDF(*width, *height, data, img);

		/* Increment the image pointer */
		current_image=(current_image+1) % sequence_length;

		PERF_END(PERFORMANCE_COUNTER_0_BASE, SECTION_1);  

		/* Print report */
		perf_print_formatted_report
		(PERFORMANCE_COUNTER_0_BASE,            
		ALT_CPU_FREQ,        // defined in "system.h"
		1,                   // How many sections to print
		"GraySDF"        // Display-name of section(s).
		);  	

		printf("GraySDF complete\n");

		//Sem released, so set sem field to 1
		*sem12 = 1;

		delay(1000);
	}
  return 0;
}
