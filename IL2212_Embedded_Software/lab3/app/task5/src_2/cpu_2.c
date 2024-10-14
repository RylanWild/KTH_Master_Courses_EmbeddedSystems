#include "../src_0/ascii_gray.h"
#include <stdio.h>
//#include <stdlib.h>
#include "system.h"
#include "io.h"
#include "sys/alt_stdio.h"

#define TRUE 1

#define SECTION_1 1

extern void delay (int millisec);

void asciiSDF(int x, int y, unsigned char* pix){
	//Copy code from lab2
	//number of ascii values
	int nlevels = sizeof(asciiChars) / sizeof(char);

	//assign grayscale values to ascii
	int n = 0;	
	for(n = 0; n < x*y; n++){
		int leveln = pix[n] / nlevels;
		//ascii[n] = asciiChars[leveln];		    
        putchar(asciiChars[leveln]);
        if ((n + 1) % x == 0) {
            putchar('\n');  // Start a new line after each row
          }
	}
} 

int main()
{
  printf("Hello from cpu_2!\n");

		unsigned char* shared = (unsigned char*) SHARED_ONCHIP_BASE;
		//unsigned char* sem12 = shared;
		unsigned char* sem23 = shared + 1;
		unsigned char* width = shared + 2;
		unsigned char* height = shared + 3;
		unsigned char* img = shared + 5;

while (1) {
		
		while(*sem23 == 0);
	
		//Sem acquired, so set sem field to 0
		*sem23 = 0;	

		printf("asciiSDF start\n");

		//PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
		//PERF_START_MEASURING (PERFORMANCE_COUNTER_0_BASE);
		//PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, SECTION_1);

		//convert gray scale to ascii
		asciiSDF(*height, *width , img);

		//PERF_END(PERFORMANCE_COUNTER_0_BASE, SECTION_1);  

		/* Print report */
		//perf_print_formatted_report
		//(PERFORMANCE_COUNTER_0_BASE,            
		//ALT_CPU_FREQ,        // defined in "system.h"
		//1,                   // How many sections to print
		//"task 3"        // Display-name of section(s).
		//);  

		printf("asciiSDF Complete\n");

	
	}
  return 0;
}
