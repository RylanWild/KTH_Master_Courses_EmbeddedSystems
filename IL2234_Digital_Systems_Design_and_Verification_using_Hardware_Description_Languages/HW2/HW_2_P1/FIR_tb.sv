`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/25 23:04:54
// Design Name: 
// Module Name: FIR_tb
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


module FIR_tb();
    logic clk, rst_n;
    logic signed [7:0] in;
    logic signed [18:0] out;
    
    FIR_filter DUT (clk,rst_n,in,out);
    
    initial begin
        clk=0;
        rst_n=0;
        
        #5;
        rst_n=1;
        
        #100;
        rst_n=0;
    end
    
    always #5 clk=~clk;
    
    initial begin
        in=8'b00000000;
        #5;
         for(int i=0;i<10;i++)
        begin
            in=$random; 
            #10;
        end
       end 
    
endmodule
