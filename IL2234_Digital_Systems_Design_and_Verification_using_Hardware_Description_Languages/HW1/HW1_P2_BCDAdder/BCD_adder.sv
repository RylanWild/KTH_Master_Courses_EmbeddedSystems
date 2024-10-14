`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/11 10:28:36
// Design Name: 
// Module Name: BCD_adder
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


module BCD_adder(
     input logic unsigned [3:0] A,//signed
     input logic unsigned [3:0] B,//round up=1,round down=0
     //input logic unsigned [3:0] Cin,
     output logic unsigned [7:0] Cout,
     output reg [3:0] Cout_H,
     output reg [3:0] Cout_L,
     output reg flag//autocheck
    );
    
     always_comb begin
        if(A+B<10)
            Cout=A+B;
        else
            Cout=A+B+8'b0000_0110;
      
        
        //-----------autocheck----------------
        Cout_H=Cout[7:4];
        Cout_L=Cout[3:0];
        if(A+B==Cout_H*10+Cout_L)
         flag=1;
        else
         flag=0;
      
      end
endmodule
