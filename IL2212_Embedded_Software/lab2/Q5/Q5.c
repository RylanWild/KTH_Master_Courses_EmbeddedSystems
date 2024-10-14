/*
Bare-metal implementation of the following orignal ForSyDe-model

module SDF_System_Model where

import ForSyDe.Shallow

-- System Netlist
system s_in = s_out where
  s_1 = p_1 s_in s_6_delayed
  (s_2, s_3) = p_2 s_1
  s_6 = p_3 s_3 s_5
  (s_out, s_4) = p_4 s_2
  s_5 = p_5 s_4
  s_6_delayed = delaySDF [0,0] s_6

-- Process Specification
p_1 = actor21SDF (2,1) 1 f_1
  where f_1 [x1,x2] [y] = [x1+x2+y]
p_2 = actor12SDF 1 (1,1) f_2
  where f_2 [x] = ([x],[x+1])
p_3 = actor21SDF (2,2) 2 f_3
  where f_3 [x1,x2] [y1,y2] = [x1+x2,y1+y2]
p_4 = actor12SDF 1 (3,1) f_4
  where f_4 [x] = ([x,x+1,x+2],[x])
p_5 = actor11SDF 1 1 f_5
  where f_5 [x] = [x+1]
*/

#include <stdio.h>
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

void actor22SDF(int consum1, int consum2, int prod1,int prod2,
                channel* ch_in1, channel* ch_in2, channel* ch_out1,channel* ch_out2,
                void (*f) (token*, token*, token*, token*))
 {
 token input1[consum1], input2[consum2], output1[prod1],output2[prod2];
 int i;

 for(i = 0; i < consum1; i++) {
 readToken(*ch_in1, &input1[i]);
    }
 for(i = 0; i < consum2; i++) {
 readToken(*ch_in2, &input2[i]);
    }
 f(input1, input2, output1,output2);
 for(i = 0; i< prod1; i++) {
 writeToken(*ch_out1, output1[i]);

    }
 for(i = 0; i< prod2; i++) {
 writeToken(*ch_out2, output2[i]);
    }
}
/* Definition of functions within processes */

/* Function in a */
// a = actor11SDF 2 1 f_1
//   where f_1 [ x ] [ y ] = [ x + y ]
void f_1(token* in, token* out) {
  out[0] = in[0] + in[1];
}

/* Function in b */
// b = actor11SDF 1 2 f_2
//   where f_2 [ x ] = [ x, x +1]
void f_2(token* in, token* out) {
  out[0] = in[0];
  out[1] = in[0] + 1;
}

/* Function in c */
// c = actor21SDF (2 ,1) 1 f_3
//   where f_3 [ x, y ] [ z ] = [ x+y+z ]
void f_3(token* in1, token* in2, token* out) {
  out[0] = in1[0] + in1[1] + in2[0];
}

/* Function in d */
// d = actor22SDF (2,1) (1,2) f_4
//   where f_4 [ x,y ][z] = ([ x+y+z] ,[ x+y,x+y+z])
void f_4(token* in1, token* in2, token* out1, token* out2) {
  out1[0] = in1[0]+in1[1]+in2[0];
  out2[0] = in1[0]+in1[1];
  out2[1] = in1[0]+in1[1]+in2[0];
}

/* Main Program */

int main() {
  token input1;
  token input2;
  token output;
  int i, j;

  /* Create FIFO-Buffers for signals */
  
  /* Buffer s_in1: Size: 2 */
  token* buffer_s_in1  = malloc(2 * sizeof(token));
  channel s_in1 = createFIFO(buffer_s_in1, 2);
  /* Buffer s_in2: Size: 1 */
  token* buffer_s_in2  = malloc(1 * sizeof(token));
  channel s_in2 = createFIFO(buffer_s_in2, 1);
  /* Buffer s_out: Size: 2 */
  token* buffer_s_out  = malloc(2 * sizeof(token));
  channel s_out = createFIFO(buffer_s_out, 2);
  /* Buffer s_1: Size: 2 */
  token* buffer_s_1  = malloc(2 * sizeof(token));
  channel s_1 = createFIFO(buffer_s_1, 1);
  /* Buffer s_2: Size: 2 */
  token* buffer_s_2  = malloc(2 * sizeof(token));
  channel s_2 = createFIFO(buffer_s_2, 2);
  /* Buffer s_3: Size: 1 */
  token* buffer_s_3  = malloc(1 * sizeof(token));
  channel s_3 = createFIFO(buffer_s_3, 1);
  /* Buffer s_4: Size: 1 */
  token* buffer_s_4  = malloc(1 * sizeof(token));
  channel s_4 = createFIFO(buffer_s_4, 1);

  /* Put initial tokens in channel s_4 */
  writeToken(s_4, 0);
  writeToken(s_4, 0);

  /* Repeating Schedule: a,a,b,c,d */
  while(1) {
	 for(i = 0; i < 2; i++) {
		/* Read input tokens */
		printf("Read two input tokens for s_in1: ");
		for(j = 0; j < 2; j++) {
		  scanf("%d", &input1);
		  writeToken(s_in1, input1);
		}
  		printf("Read one input token for s_in2: ");
		for(j = 0; j < 1; j++) {
		  scanf("%d", &input2);
		  writeToken(s_in2, input2);
		}  
		/* a */
		actor11SDF(2, 1, &s_in1, &s_1, f_1);
		/* a */
		actor11SDF(2, 1, &s_in1, &s_1, f_1);
		/* b */
		actor11SDF(1, 2, &s_in2, &s_2, f_2);
		/* c */
		actor21SDF(2, 1, 1, &s_1, &s_4, &s_3, f_3);
 		/* d */
		actor22SDF(2, 1, 1, 2, &s_2, &s_3, &s_4, &s_out, f_4);   
		/* Write output tokens */
		printf("Output: ");
		for(j = 0; j< 2; j++) {
		  readToken(s_out, &output);
		  printf("%d ", output);
      printf("\n");
		}
	 }
  }
  return 0;
}
