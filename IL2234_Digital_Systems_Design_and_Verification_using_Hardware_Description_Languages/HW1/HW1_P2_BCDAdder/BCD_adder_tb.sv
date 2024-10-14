`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/11 10:53:13
// Design Name: 
// Module Name: BCD_adder_tb
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


module BCD_adder_tb( );
    logic unsigned [3:0] A;
    logic unsigned [3:0] B;
    logic unsigned [7:0] Cout;
    reg [3:0] Cout_H;
    reg [3:0] Cout_L;
    reg flag;
    
    BCD_adder DUT(A,B,Cout,Cout_H,Cout_L,flag);
    initial begin
    A=4'b0000;
    B=4'b0000;
    for(int i=0;i<20;i++)
        begin
            A={$random}%10;
            B={$random}%10;
            #5;
        end
    end
endmodule
