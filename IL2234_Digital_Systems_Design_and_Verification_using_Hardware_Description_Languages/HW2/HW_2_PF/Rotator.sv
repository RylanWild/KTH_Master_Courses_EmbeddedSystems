`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/22 20:03:26
// Design Name: 
// Module Name: Rotator
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


module Rotator(clk,rst_n,in,out,select,Out);
    input logic clk;
    input logic rst_n;
    input logic in;
    input logic out;
    input logic select;
    
    output logic Out;  
    
    always_comb
    begin
        case(select)
        1'b0:Out=in;      
        1'b1:Out=out;
        endcase
    end 
    
endmodule
