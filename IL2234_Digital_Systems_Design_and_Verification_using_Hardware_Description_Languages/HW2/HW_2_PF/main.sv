`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/24 21:57:26
// Design Name: 
// Module Name: main
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


module main(clk,rst_n,select,in,D,out,Q);
    input logic clk;
    input logic rst_n;
    input logic select;
    input logic in;
    output logic D;
    output logic out;
    output logic [5:0]Q;

//instantiation should be outside the always block
//I find out that no need to use the Rotator when using the mux
   // mux MUX (in,out,select,D);
   Rotator MUX (clk,rst_n,in,out,select,D);
                d_flop Q0 (clk,rst_n,D,Q[5]);//D=in,shift;D=out,rotate
                d_flop Q1 (clk,rst_n,Q[5],Q[4]);
                d_flop Q2 (clk,rst_n,Q[4],Q[3]);
                d_flop Q3 (clk,rst_n,Q[3],Q[2]);
                d_flop Q4 (clk,rst_n,Q[2],Q[1]);
                d_flop Q5 (clk,rst_n,Q[1],Q[0]);

                always_comb
                    begin
                        out=Q[0];
                    end

endmodule
