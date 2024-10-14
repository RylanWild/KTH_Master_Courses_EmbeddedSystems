#include <stdio.h>
#include "system.h"
#include "io.h"

#define TRUE 1

#define SECTION_1 1

//RESIZE SDF
void resizeSDF(int width,int height, unsigned char* gray_pix, unsigned char* resized_pix){
	int y;
	int x;
	for (y = 0; y < height; y=y+2) {
        for (x = 0; x < width; x=x+2) {  
			resized_pix[16*y+x/2]=(gray_pix[64*y+x]+gray_pix[64*y+x+1]+gray_pix[64*y+x+64]+gray_pix[64*y+x+65])/4.0; 
		}
    }
}

extern void delay (int millisec);

int main()
{
  printf("Hello from cpu_1!\n");

		unsigned char* shared = (unsigned char*) SHARED_ONCHIP_BASE;
		unsigned char* sem12 = shared;
		unsigned char* sem23 = shared + 1;
		unsigned char* width = shared + 2;
		unsigned char* height = shared + 3;
		unsigned char* img = shared + 5;

		//Cpu_1 already has the first sem
		*sem23 = 0;

  while (1) {
	
	//Read sem12. hold if clear
	while(*sem12 == 0);

	printf("ResizeSDF start\n");

	//Sem acquired, so set sem field to 0
	*sem12 = 0;

	//Resize SDF
	resizeSDF(*width, *height, img, img);
	*height = *height/2;
	*width = *width/2;

	//Sem released, so set sem field to 1
	*sem23 = 1;

	printf("ResizeSDF complete\n");

  }
  return 0;
}
