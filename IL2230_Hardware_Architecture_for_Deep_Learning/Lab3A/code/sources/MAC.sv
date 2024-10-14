`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/28 22:00:55
// Design Name: 
// Module Name: MAC
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


module MAC #(parameter M=32,parameter Q=16,parameter x_integer=12,parameter x_fraction=20,
             parameter w_integer=6, parameter w_fraction=10)(
    input logic [M-1:0]x,
    input logic [Q-1:0]w,
    input logic [M-1:0] adder,
    output logic [M-1:0] result
    );

    logic [2*M-1:0]calculation_result;
    logic [M-1:0] caculation_cut;

    assign calculation_result=x*w;
    assign caculation_cut = calculation_result[w_integer+2*x_fraction-1:2*x_fraction-w_fraction];
    assign result=adder+caculation_cut;

endmodule
