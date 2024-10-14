#include "ppm_io.h"
#include <math.h>

int main(int argc, char** argv) {
   if(argc < 3){
    //printf("Please provide the input/output file name\n");
    return 1;
  }
  ppmTy ppm = ppm_read(argv[1]);
  ppm_write(argv[2], ppm);

    // Example RGB data
    double *gray_data = (double *)malloc((ppm.w * ppm.h) * sizeof(double));
    // Allocate memory for ASCII data
    char *ascii = (char *)malloc(ppm.w * ppm.h * sizeof(char));

    // Convert RGB data to grayscale
    graysdf(ppm.w, ppm.h, ppm.data, gray_data);
   
    // Convert grayscale data to ASCII art
    asciiSDF(ppm.w, ppm.h, gray_data, ascii);
 
    // Print ASCII art
    for (int i = 0; i < ppm.w * ppm.h; ++i) {
        putchar(ascii[i]);
        if ((i + 1) % ppm.w == 0) {
            putchar('\n');  // Start a new line after each row
        }
    }

    // Free dynamically allocated memory
    free(gray_data);
    free(ascii);

    return 0;
}