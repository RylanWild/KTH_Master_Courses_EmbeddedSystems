/*
module SDF_System_Model where

import ForSyDe.Shallow

graySDF :: Int -- ^ dimension X for input images
        -> Int -- ^ dimension Y for input images
        -> Signal Int -- ^ stream of pixels from the RGB image
        -> Signal Double -- ^ stream of resulting grayscale pixels
graySDF dimX dimY = actor11SDF (3 * dimX * dimY) (dimX * dimY) (wrapImageF (3 * dimX) dimY grayscale)

grayscale :: Image Int -> Image Double
grayscale = mapMatrix (convert . fromVector) . mapV (groupV 3)
  where
    convert [r,g,b] = fromIntegral r * 0.3125
                    + fromIntegral g * 0.5625
                    + fromIntegral b * 0.125
    convert _ = error "X length is not a multiple of 3"



-- | The ASCII actor, which outputs the ASCII 'art' of the image stream.
asciiSDF :: Int -- ^ dimension X for input images
         -> Int -- ^ dimension Y for input images
         -> Signal Double -- ^ stream of pixels to be printed
         -> Signal Char -- ^ stream of resulting ASCII pixels
asciiSDF dimX dimY = actor11SDF (dimX * dimY) (dimX * dimY) (wrapImageF dimX dimY toAsciiArt)

-- | Converts a 256-value grayscale image to a 16-value ASCII art
-- image.
toAsciiArt :: Image Double -> Image Char
toAsciiArt = mapMatrix num2char
  where
    num2char n = asciiLevels !! level n
    level n = truncate $ nLevels * (n / 255)
    nLevels = fromIntegral $ length asciiLevels - 1

-- | List with grayscale levels encoded as ASCII characters
asciiLevels :: [Char]
asciiLevels = [' ','.',':','-','=','+','/','t','z','U','w','*','0','#','%','@']
*/

#include <stdio.h>
#include <stdlib.h>
#include "circular_buffer.h" /* defines data type token as uint8_t */

/* Definition of the channel */
typedef cbuf_handle_t channel;

/* Definition of the functions 'readToken' and 'writeToken' */
int readToken(channel ch, token* data) {
  return circular_buf_get(ch, data);
}

void writeToken(channel ch, token data) {
  circular_buf_put(ch, data);
}

typedef struct {
    int r, g, b; // Red, Green, Blue components
} pixel;

typedef struct {
    pixel* data; // Matrix of pixels
    int dimX;    // Number of rows
    int dimY;    // Number of columns
} ImageRGB;

typedef struct {
    double* data; // Matrix of pixels
    int dimX;    // Number of rows
    int dimY;    // Number of columns
} ImageDouble;

typedef struct {
    char* data; // Matrix of pixels
    int dimX;    // Number of rows
    int dimY;    // Number of columns
} ImageChar;

/* Definition of function 'createFIFO' */
channel createFIFO(token* buffer, size_t size){
  return circular_buf_init(buffer, size);
}

/* Definition of SDF actors */

void actor11SDF(int consum, int prod,
					 channel* ch_in, channel* ch_out,
					 void (*f) (token*, token*))
{
  token input[consum], output[prod];
  int i;

  for(i = 0; i < consum; i++) {
	 readToken(*ch_in, &input[i]);
  }
  f(input, output);
  for(i = 0; i< prod; i++) {	 
	 writeToken(*ch_out, output[i]);
  }
}

void actor12SDF(int consum, int prod1, int prod2,
					 channel* ch_in, channel* ch_out1, channel* ch_out2,
					 void (*f) (token*, token*, token*))
{
  token input[consum], output1[prod1], output2[prod2];
  int i;

  for(i = 0; i < consum; i++) {
	 readToken(*ch_in, &input[i]);
  }
  f(input, output1, output2);
  for(i = 0; i< prod1; i++) {	 
	 writeToken(*ch_out1, output1[i]);
  }
  for(i = 0; i< prod2; i++) {	 
	 writeToken(*ch_out2, output2[i]);
  }
}

void actor21SDF(int consum1, int consum2, int prod,
					 channel* ch_in1, channel* ch_in2, channel* ch_out,
					 void (*f) (token*, token*, token*))
{
  token input1[consum1], input2[consum2], output[prod];
  int i;

  for(i = 0; i < consum1; i++) {
	 readToken(*ch_in1, &input1[i]);
  }
  for(i = 0; i < consum2; i++) {
	 readToken(*ch_in2, &input2[i]);
  }
  f(input1, input2, output);
  for(i = 0; i< prod; i++) {	 
	 writeToken(*ch_out, output[i]);
  }
}

/* Definition of functions within processes */

/* Function in graySDF */
// grayscale = mapMatrix (convert . fromVector) . mapV (groupV 3)
//where
//   convert [r,g,b] = fromIntegral r * 0.3125
//                    + fromIntegral g * 0.5625
//                    + fromIntegral b * 0.125
//   convert _ = error "X length is not a multiple of 3"
// Function to convert an RGB pixel to grayscale

double convert(pixel p) {
    return (double)p.r * 0.3125 + (double)p.g * 0.5625 + (double)p.b * 0.125;
}

// Function to convert an image to grayscale
void grayscale(ImageRGB* in, ImageDouble* out) {
    if (in->data == NULL || out->data == NULL) {
        printf("Error: Input or output image is NULL\n");
        return;
    }

    if (in->dimY != out->dimX || in->dimY != out->dimY) {
        printf("Error: Input and output image dimensions do not match\n");
        return;
    }

    for (int i = 0; i < in->dimX; i++) {
        for (int j = 0; j < in->dimY; j++) {
            pixel current_pixel = in->data[i * in->dimY + j]; // Accessing current pixel
            double grayscale_value = convert(current_pixel);  // Converting pixel to grayscale
            out->data[i * out->dimY + j] = grayscale_value; // Storing grayscale value in output image
        }
    }
}

/* Function in asciiSDF */
// toAsciiArt = mapMatrix num2char
// where
//    num2char n = asciiLevels !! level n
//    level n = truncate $ nLevels * (n / 255)
//    nLevels = fromIntegral $ length asciiLevels - 1
//   where f_2 [ x ] = ([ x ] ,[ x +1])
// Function to convert a double value to a character based on ASCII levels
char num2char(double n) {
    const char asciiLevels[] = {' ','.',':','-','=','+','/','t','z','U','w','*','0','#','%','@'};
    int level = (int)(n * 16 / 256); // Map the double value to the ASCII levels
    return asciiLevels[level];
}

// Function to convert a grayscale image to ASCII art
ImageChar toAsciiArt(ImageDouble* image) {
    ImageChar asciiImage;
    asciiImage.dimX = image->dimX;
    asciiImage.dimY = image->dimY;
    asciiImage.data = (char*)malloc(image->dimX * image->dimY * sizeof(char));

    for (int i = 0; i < image->dimY; i++) {
        for (int j = 0; j < image->dimX; j++) {
            double pixelValue = image->data[i * image->dimX + j];
            asciiImage.data[i * image->dimX + j] = num2char(pixelValue);
        }
    }

    return asciiImage;
}

// Function to handle the stream of pixels and convert to ASCII art
ImageChar asciiSDF(int dimX, int dimY, double* pixels, int length) {
    ImageDouble inputImage;
    inputImage.dimX = dimX;
    inputImage.dimY = dimY;
    inputImage.data = pixels;

    return toAsciiArt(&inputImage);
}

/* Main Program */

int main() {
  token input;
  token output;
  int i, j;

  /* Create FIFO-Buffers for signals */
  
  /* Buffer s_in: Size: 3*dimX*dimY */
  token* buffer_s_in  = malloc(3*dimX*dimY * sizeof(token));
  channel s_in = createFIFO(buffer_s_in, 2);
  /* Buffer s_out: Size: 3 */
  token* buffer_s_out  = malloc(3 * sizeof(token));
  channel s_out = createFIFO(buffer_s_out, 3);
  /* Buffer s_1: Size: 1 */
  token* buffer_s_1  = malloc(1 * sizeof(token));
  channel s_1 = createFIFO(buffer_s_1, 1);
  /* Buffer s_2: Size: 1 */
  token* buffer_s_2  = malloc(1 * sizeof(token));
  channel s_2 = createFIFO(buffer_s_2, 1);
  /* Buffer s_3: Size: 2 */
  token* buffer_s_3  = malloc(2 * sizeof(token));
  channel s_3 = createFIFO(buffer_s_3, 2);
  /* Buffer s_4: Size: 1 */
  token* buffer_s_4  = malloc(1 * sizeof(token));
  channel s_4 = createFIFO(buffer_s_4, 1);
  /* Buffer s_5: Size: 2 */
  token* buffer_s_5  = malloc(2 * sizeof(token));
  channel s_5 = createFIFO(buffer_s_5, 2);
  /* Buffer s_6: Size: 2 */
  token* buffer_s_6  = malloc(2 * sizeof(token));
  channel s_6 = createFIFO(buffer_s_6, 2);

  /* Put initial tokens in channel s_6 */
  writeToken(s_6, 0);
  writeToken(s_6, 0);

  /* Repeating Schedule: in->graySDF->AsciiSDF->out */
  while(1) {
	 for(i = 0; i < 2; i++) {
		/* Read input tokens */
		printf("Read two input tokens: ");
		for(j = 0; j < 2; j++) {
		  scanf("%d", &input);
		  writeToken(s_in, input);
		}
		/* P_1 */
		actor21SDF(2, 1, 1, &s_in, &s_6, &s_1, f_1);
		/* P_2 */
		actor12SDF(1, 1, 1, &s_1, &s_2, &s_3, f_2);
		/* P_4 */
		actor12SDF(1, 3, 1, &s_2, &s_out, &s_4, f_4);
		/* Write output tokens */
		printf("Output: ");
		for(j = 0; j< 3; j++) {
		  readToken(s_out, &output);
		  printf("%d ", output);
		}
		printf("\n");
		/* P_5 */
		actor11SDF(1, 1, &s_4, &s_5, f_5);
	 }
	 /* P_3 */
	 actor21SDF(2, 2, 2, &s_3, &s_5, &s_6, f_3);	
  }
  return 0;
}
