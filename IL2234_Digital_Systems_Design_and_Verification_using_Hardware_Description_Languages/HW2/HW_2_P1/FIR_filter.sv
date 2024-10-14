`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/25 21:42:17
// Design Name: 
// Module Name: FIR_filter
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

`include "weight.sv"

module FIR_filter(
    input logic clk, rst_n,
    input logic signed [7:0] in,
    output logic signed [18:0] out
    );
    logic signed [7:0] S [0:5];
    logic signed [15:0] next_1[0:5];
    logic signed [15:0] stage_1[0:5];
    
    logic signed [16:0] next_2[0:2];
    logic signed [16:0] stage_2[0:2];
    
    logic signed [17:0] next_3[0:1];
    logic signed [17:0] stage_3[0:1];
    
    logic signed [18:0] next_4;
    logic signed [18:0] stage_4;
    
    //layer 1
    d_flop flop1 (clk,rst_n,in,S[0]);
    d_flop flop2 (clk,rst_n,S[0],S[1]);
    d_flop flop3 (clk,rst_n,S[1],S[2]);
    d_flop flop4 (clk,rst_n,S[2],S[3]);
    d_flop flop5 (clk,rst_n,S[3],S[4]);
    d_flop flop6 (clk,rst_n,S[4],S[5]);
    
    always_ff @(posedge clk) begin
      stage_1 [0:5] <= next_1 [0:5];
      stage_2 [0:2] <= next_2 [0:2];
      stage_3 [0:1]<= next_3 [0:1];
      stage_4 <= next_4;
  end
    
    assign next_1[0] = weight::weight_0*S[0];
    assign next_1[1] = weight::weight_1*S[1];
    assign next_1[2] = weight::weight_2*S[2];
    assign next_1[3] = weight::weight_3*S[3];
    assign next_1[4] = weight::weight_4*S[4];
    assign next_1[5] = weight::weight_5*S[5];
    
    //layer2
    assign next_2[0]=stage_1[0]+stage_1[1];
    assign next_2[1]=stage_1[2]+stage_1[3];
    assign next_2[2]=stage_1[4]+stage_1[5];
    
    //layer3
    assign next_3[0]=stage_2[0]+stage_2[1];
    assign next_3[1]=stage_2[2];
    
    //layer4
    assign next_4=stage_3[0]+stage_3[1];
    assign out=stage_4;    

        
    
    endmodule
