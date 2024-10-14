#include "ppm_io.h"

int main(int argc, char** argv){
  if(argc < 3){
    printf("Please provide the input/output file name\n");
    return 1;
  }
  ppmTy ppm = ppm_read(argv[1]);
  ppm_write(argv[2], ppm);
  return 0;
}
