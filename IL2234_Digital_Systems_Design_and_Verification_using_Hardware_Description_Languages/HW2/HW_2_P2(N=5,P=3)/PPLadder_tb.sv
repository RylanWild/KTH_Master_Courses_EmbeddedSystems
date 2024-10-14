`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/27 00:55:09
// Design Name: 
// Module Name: PPLadder_tb
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


module PPLadder_tb();
    logic clk;
    logic rstn;
    logic [4:0]a;
    logic [4:0]b;
    logic [4:0]sum;
    logic cout;
    
    PPL_adder DUT (clk,rstn,a,b,sum,cout);
    
    initial begin
        rstn=0;
        clk=0;
        #5;
        for(int i=0;i<1;i++)
        begin
        rstn=1;
        #15;
        rstn=0;
        #5;
        end
        
    end
    
   
    always #5 clk=~clk;
    
    initial begin
        a=5'b00000;
        b=5'b00000;  
        #5;
        //test one set each time
                a=5'b01101;
                b=5'b10001;
                #20;
    end
    
endmodule
