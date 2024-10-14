`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/25 09:56:38
// Design Name: 
// Module Name: sigmoid
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sigmoid #(parameter M=32,parameter X_INT=12,parameter X_FRACTION=20)(
  input logic [M-1:0] x,
  output logic [M-1:0] y
    );
  logic [9:0]x_ext;
  logic [9:0]region1,region2,region3,region4;
  logic [M-1:0]region1_ext,region2_ext,region3_ext,region4_ext;
  logic [3:0] choose;
  logic [M-1:0] x_shift;
  logic [M-1:0] x_ext_shift;
  logic [M-1:0] y_real;
  logic [M-1:0] M_bit_fix_1;
  logic ext_0;
  assign region1=10'b11000_00000;//-8
  assign region2=10'b01000_00000;//8,
  assign region3=10'b11110_01101;//-1.6,but in fact -1.59375
  assign region4=10'b00001_10011;//1.6
  assign ext_0=1'b0;
  assign M_bit_fix_1={{(X_INT-1){ext_0}},{1{~ext_0}},{(X_FRACTION){ext_0}}};
  
  always_comb begin
    if(M<10)begin //x extension
      x_ext={{2{x[M-1]}},x};
      
      if(x[M-1]==1 && x_ext[8]==0) begin
        y=0;
        choose=0;//x<-8
      end
      else if(x[M-1]==1 && x_ext[8]==1 && x_ext[8:0]<region3[8:0])begin
        y=(region2-~(x_ext-1))>>6;
        choose=1;//x>-8,x<-1.6
      end
      else if(x[M-1]==1 || (x[M-1]==0 && x_ext[8:0]<region4[8:0]))begin
        x_shift=x>>2;
        y= x_shift+8'b000_10000;
        choose=2;//x>-1.6, x<1.6
      end
      else if(x[M-1]==0 && x_ext[8:0]<region2[8:0])begin
        x_ext_shift=(region2-x_ext)>>8;
        y=8'b001_00000-x_ext_shift[7:0];
        choose=3;//x>1.6,x<8
      end
      else begin 
        y=8'b0010_0000;
        choose=4;
      end
    end
    else begin
      region1_ext={{(X_INT-5){region1[9]}},region1,{(X_FRACTION-5){ext_0}}};
      region2_ext={{(X_INT-5){region2[9]}},region2,{(X_FRACTION-5){ext_0}}};
      region3_ext={{(X_INT-5){region3[9]}},region3,{(X_FRACTION-5){ext_0}}};
      region4_ext={{(X_INT-5){region4[9]}},region4,{(X_FRACTION-5){ext_0}}};
      
      if(x[M-1]==1 && x[M-2:X_FRACTION+3]!={(M-2-(X_FRACTION+3)+1){1'b1}}) begin
        y=0;
        choose=0;//x<-8
      end
      else if(x[M-1]==1 && x[M-1:X_FRACTION+3]=={(M-1-(X_FRACTION+3)+1){1'b1}} && x[X_FRACTION+3:X_FRACTION-5]<region3[8:0])begin
        y_real=(region2_ext-~(x-1))>>6;
        //y=y_real[X_FRACTION+2:X_FRACTION-5];
        y=y_real;
        choose=1;//x>-8,x<-1.6
      end
      else if(x[M-1]==1 || (x[M-1]==0 && x[M-1:X_FRACTION+3]=={(M-1-(X_FRACTION+3)+1){1'b0}} && x[X_FRACTION+3:X_FRACTION-5]<region4[8:0]))begin
        x_shift=x>>2;//>>>似乎并不是算数右移，仍旧补了0
        if(x[M-1]==1)x_shift[M-1:M-2]=2'b11;
        y_real= x_shift+(M_bit_fix_1>>1);//{x_shift[M-1:X_FRACTION+3],(x_shift[X_FRACTION+2:X_FRACTION-5]+8'b000_10000),x_shift[X_FRACTION-6:0]};
        //y=y_real[X_FRACTION+2:X_FRACTION-5];
        y=y_real;
        choose=2;//x>-1.6, x<1.6
      end
      else if(x[M-1]==0 && x[M-1:X_FRACTION+3]=={(M-1-(X_FRACTION+3)+1){1'b0}} && x[X_FRACTION+3:X_FRACTION-5]<region2[8:0])begin
        x_shift=(region2_ext-x)>>8;
        y_real=M_bit_fix_1-x_shift;//{x_shift[M-1:X_FRACTION+3],8'b001_00000-x_shift[X_FRACTION+2:X_FRACTION-5],x_shift[X_FRACTION-6:0]};//underflow may occur
        y=y_real[X_FRACTION+2:X_FRACTION-5];
        choose=3;//x>1.6,x<8
      end
      else begin 
        y_real[X_FRACTION+2:X_FRACTION-6]=8'b0010_0000;
        //y=y_real[X_FRACTION+2:X_FRACTION-5];
        y=y_real;
        choose=4;
      end
      
    end
    
//    if(x[M-1]==1 && x_ext[8:0]<region1[8:0]) y=0;//x<-8
//    else if(x[M-1]==1 && x_ext[8:0]>region3[8:0])y=(region2-~(x_ext-1))>>8;//x>-8,x<-1.6
//    else if(x[M-1]==1 || (x[M-1]==0 && x_ext[8:0]<region4[8:0])) y= x>>2+ 8'b0001_0000;//x>-1.6, x<1.6
//    else if(x[M-1]==0 && x_ext[8:0]<region4[8:0])y=8'b001_00000-((region2-x_ext))>>8;//x>1.6,x<8
//    else y=8'b0010_0000;
  end 
endmodule