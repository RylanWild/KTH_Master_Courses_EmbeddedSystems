`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/28 21:11:21
// Design Name: 
// Module Name: parallel_fully
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


module parallel_fully #(parameter M=32,parameter Q=16,parameter integer_input=12,parameter fraction_input=20,
                        parameter W_integer=6,parameter W_fraction=10,parameter N=10)(
    input logic [Q-1:0] W[N-1:0],
    input logic [M-1:0] X [N-1:0],
    input logic rst_n,
    input clk,
    input logic [M-1:0] b,
    output logic [M-1:0]out_real
    //output logic [7:0] cut_out
    );//M:bits for X,  Q:bits for W,  N: number of mac
    logic [M-1:0] W_register[N-1:0];
    logic [M-1:0] X_register[N-1:0];
    logic [M-1:0] W_ext;
    logic [M-1:0] result_register[N:0];//the last one is for the output_real
    logic [M-1:0] M_bit1;
    assign M_bit1={{(integer_input-1){1'b0}},{1{1'b0}},{(fraction_input){1'b0}}};
    //always_ff @(posedge clk, negedge rst_n)begin
    always_comb begin
      if(!rst_n)begin
        for(int i=0;i<=(N-1);i++)begin
          W_register[i]<='b0;
          X_register[i]<='b0;
          W_ext<='b0;
        end
      end
      else begin
        for(int i=0;i<=(N-1);i++)begin
          W_ext={{(integer_input-W_integer){W[i][Q-1]}},W[i],{(fraction_input-W_fraction){1'b0}}};
          W_register[i]<=W_ext;
          X_register[i]<=X[i];
        end
      end
    end
    
    generate
      genvar j;
      for(j=0;j<=N;j++)begin
        if(j==0) MAC #(
          .M         (M),
          .Q         (Q),
          .x_integer (integer_input),
          .x_fraction(fraction_input),
          .w_integer (W_integer), 
          .w_fraction(W_fraction)
        )parallel_1 (M_bit1,b,0,result_register[j]);
        else MAC #(
          .M         (M),
          .Q         (Q),
          .x_integer (integer_input),
          .x_fraction(fraction_input),
          .w_integer (W_integer), 
          .w_fraction(W_fraction)
        )parallel_N(X_register[j-1],W_register[j-1],result_register[j-1],result_register[j]);
      end
    endgenerate

always @(posedge clk)    
    out_real <= result_register[N];
    //sigmoid cut (result_register[N],cut_out);
    
endmodule