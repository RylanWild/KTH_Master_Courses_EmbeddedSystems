`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/27 00:48:14
// Design Name: 
// Module Name: full_adder
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


module full_adder (
  input  a, b, c_in,
  output c_out, s
);
  logic s1,c1,c2;

  half_adder ha1 (a,b,c1,s1);
  half_adder ha2 (s1,c_in,c2,s);

  assign c_out = c1|c2;
endmodule
