#include "ppm_io.h"

int write_buf(char* buffer, char c, int* buf_len, int count){
  if(count == *buf_len){
    *buf_len += BUF_LEN;
    buffer = (char*) realloc(buffer, *buf_len);
  }
  buffer[count] = c;
}

char* read_word(FILE *fp){
  enum { S1, S2, S3 } state = S1;

  int buf_len = BUF_LEN;
  int count = 0;
  char *buffer = malloc(sizeof(char) * buf_len);
  char c;
  
  while((c = fgetc(fp)) != EOF){
    switch(state){
    //init state
    case S1:
      if(isspace(c)) continue;
      else if(c != '#'){
	state = S2;
	write_buf(buffer, c, &buf_len, count);
	count += 1;
	continue;
      }
      else {state = S3; continue;}
    //read in state
    case S2:
      if(!isspace(c) && (c != '#')){
	write_buf(buffer, c, &buf_len, count);
	buffer[count] = c;
	count += 1;
	continue;
      }
      else if(c == '#') {state = S3; continue;}
      else break;
    //comment state
    case S3:
      if(c != '\n') continue;
      else break;
    }
    break;
  } 

  if(count == buf_len){
    buf_len += 1;
    buffer = (char*) realloc(buffer, buf_len);
  }
  buffer[count] = '\0';
  
  return buffer;
}

ppmTy ppm_read(char *file_name){
  FILE *ppm_file = fopen(file_name, "r");
  ppmTy ppm_data;
  char* word;
  enum { READ_HEAD, READ_WIDTH, READ_HEIGHT, READ_MAX_V, READ_PIXEL} state = READ_HEAD;
  int count = 0;
  if(ppm_file != NULL){
    do{
      word = read_word(ppm_file);
      
      switch(state){
      case READ_HEAD:
	if(strcmp(word, "P3") == 0) {state = READ_WIDTH; continue;}
	printf("The file is not a PPM file.%s \n", word);
	exit(1);
      case READ_WIDTH:
	ppm_data.w = atoi(word);
	if(ppm_data.w != 0) {state = READ_HEIGHT; continue;}
	printf("Width of the image is not valid.\n");
	exit(1);
      case READ_HEIGHT:
	ppm_data.h = atoi(word);
	if(ppm_data.h != 0) {
	  ppm_data.data = malloc(sizeof(unsigned int) * ppm_data.w * ppm_data.h * 3);
	  state = READ_MAX_V;
	  continue;}
	printf("Height of the image is not valid.\n");
	exit(1);
      case READ_MAX_V:
	ppm_data.max_val = atoi(word);
	if(ppm_data.max_val != 0) {state = READ_PIXEL; continue;}
	printf("Max value of the image is not valid.\n");
	exit(1);
      case READ_PIXEL:
	if(count < ppm_data.w * ppm_data.h * 3) {
	  ppm_data.data[count] = atoi(word);
	  if(ppm_data.data[count] > ppm_data.max_val){
	    printf("Pixel value overflow\n");
	    exit(1);}
	  count += 1;
	  continue;}
	break;
      }     
      break;
    }while(!feof(ppm_file));
    
    if(count != (ppm_data.w * ppm_data.h * 3)){
      printf("Number of pixels is not equal with the specified dimention.");
      exit(1);
    }
  }
  else{
    printf("cannot open the file: %s\n", file_name);
    exit(1);
  }
  fclose(ppm_file);
  return ppm_data;
}

int ppm_write(char* file_name, ppmTy data){
  FILE *ppm_file = fopen(file_name, "w");
  fputs("P3\n", ppm_file);
  fprintf(ppm_file, "%d %d\n", data.w, data.h);
  fprintf(ppm_file, "%d\n", data.max_val);
  fputs("# R\tG\tB\n", ppm_file);
  for(int i = 0; i < data.w * data.h * 3; i+=3){
    fprintf(ppm_file, "%d\t%d\t%d\n", data.data[i], data.data[i+1], data.data[i+2]);
  }
  fclose(ppm_file);
  return 0;
}

/*
grayscale :: Image Int -> Image Double
grayscale = mapMatrix (convert . fromVector) . mapV (groupV 3)
  where
    convert [r,g,b] = fromIntegral r * 0.3125
                    + fromIntegral g * 0.5625
                    + fromIntegral b * 0.125
    convert _ = error "X length is not a multiple of 3"

graySDF :: Int -- ^ dimension X for input images
        -> Int -- ^ dimension Y for input images
        -> Signal Int -- ^ stream of pixels from the RGB image
        -> Signal Double -- ^ stream of resulting grayscale pixels
graySDF dimX dimY = actor11SDF (3 * dimX * dimY) (dimX * dimY) (wrapImageF (3 * dimX) dimY grayscale)
*/

double rgb_to_gray(unsigned int r, unsigned int g, unsigned int b) {
    return (double)(0.3125 * r + 0.5625 * g + 0.125 * b); // Luminosity method
}

void graysdf(int dimX, int dimY, int* rgb_data, double* gray_data){

    // split into arrays of 3 [rgb]
    // apply conversion of each array
    // re-combine all arrays into single array
    // return an array of doubles

    for (int i = 0; i < dimX*dimY*3; i += 3){
       gray_data[i / 3] = rgb_to_gray(rgb_data[i], rgb_data[i + 1], rgb_data[i + 2]);
    }
}
/*
asciiLevels :: [Char]
asciiLevels = [' ','.',':','-','=','+','/','t','z','U','w','*','0','#','%','@']

toAsciiArt :: Image Double -> Image Char
toAsciiArt = mapMatrix num2char
  where
    num2char n = asciiLevels !! level n
    level n = truncate $ nLevels * (n / 255)
    nLevels = fromIntegral $ length asciiLevels - 1

asciiSDF :: Int -- ^ dimension X for input images
         -> Int -- ^ dimension Y for input images
         -> Signal Double -- ^ stream of pixels to be printed
         -> Signal Char -- ^ stream of resulting ASCII pixels
asciiSDF dimX dimY = actor11SDF (dimX * dimY) (dimX * dimY) (wrapImageF dimX dimY toAsciiArt)

*/
char asciiLevels[] = {' ', '.', ':', '-', '=', '+', '/', 't', 'z', 'U', 'w', '*', '0', '#', '%', '@'};
int nLevels = sizeof(asciiLevels) / sizeof(asciiLevels[0]) - 1;

char num2char(double n) {
    int level = (int)(nLevels * (n / 255.0));
    return asciiLevels[level];
}

void toAsciiArt(int dimX, int dimY,double *pixels, char *ascii) {
    for (int i = 0; i < dimX * dimY; ++i) {
        ascii[i] = num2char(pixels[i]);
    }
}

void asciiSDF(int dimX, int dimY, double *pix, char *ascii) {
    toAsciiArt(dimX,dimY,pix,ascii);
}

