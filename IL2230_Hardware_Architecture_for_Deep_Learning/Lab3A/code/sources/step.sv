`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/27 00:12:48
// Design Name: 
// Module Name: step
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

module step #(parameter M=8,parameter N=8, parameter y_integer=3,parameter y_fraction=5)(
    input logic[M-1:0] x,
    output logic[N-1:0] y
);
  always_comb begin
    if(x[M-1]==0)y={{(y_integer-1){1'b0}},1'b1,{y_fraction{1'b0}}};
    else y='b0;
  end
endmodule