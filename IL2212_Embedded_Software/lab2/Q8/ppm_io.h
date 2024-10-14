#ifndef PPM_IO_H
#define PPM_IO_H

#define BUF_LEN 32

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>
#include <string.h>

typedef struct {
  unsigned int w;
  unsigned int h;
  unsigned int max_val;
  unsigned int *data;
} ppmTy;

ppmTy ppm_read(char *file_name);
int ppm_write(char* file_name, ppmTy data);

#endif
