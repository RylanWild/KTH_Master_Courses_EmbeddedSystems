`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/27 00:18:57
// Design Name: 
// Module Name: ReLU
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


module ReLU #(parameter M=8,parameter N=8,parameter X_INTEGER=3, parameter X_FRACTION=5,parameter y_integer=3,parameter y_fraction=5)(
      input logic[M-1:0] x,
      output logic[N-1:0] y
    );
    always_comb begin
      if(x[M-1]==1) y='b0;
      else begin
        y=x[X_FRACTION+y_integer-1:X_FRACTION-y_fraction];
      end
    end
endmodule