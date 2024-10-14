`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/03 16:18:58
// Design Name: 
// Module Name: top_tb
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


module top_tb #(parameter A=3, parameter B=4, parameter C=6,parameter D=2,parameter E=1,parameter ADDR_WIDTH=3)( );
    logic clk;
    logic rstn;
    logic start;
    logic idle;
    //logic [ADDR_WIDTH-1:0] address;
    logic  [31:0] address;
    logic overflow;


    top DUT (clk,rstn,start,idle,address,overflow);
    
    initial begin
        clk=1'b0;
        rstn=1'b1;
        start=1'b0;
    end
    
    always #5 clk=~clk;
    
    initial begin
        #10;
        rstn=1'b0;
        #10;
        rstn=1'b1;
        #10;
        start=1'b1;
        #10;
        start=1'b0;
    end
endmodule
