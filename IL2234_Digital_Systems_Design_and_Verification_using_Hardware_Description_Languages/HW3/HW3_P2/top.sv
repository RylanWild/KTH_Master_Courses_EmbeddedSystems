`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/03 13:33:57
// Design Name: 
// Module Name: top
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


module top  #(parameter A=3, parameter B=4, parameter C=6,parameter D=2,parameter E=1,parameter ADDR_WIDTH=3)
(
     input logic clk,
     input logic rstn,
     input logic start,
     output logic idle,
     //output logic [ADDR_WIDTH-1:0] address,
     output logic [31:0] address,
     output logic overflow
 );
    
     logic I;//i<C I=1
     logic J;//j<B, J=1
     logic iplus;//i=i+1
     logic jplus;//j=j+1
     logic ireset;//i=0
     logic jreset;//j=0
    
    address_fsm DUT1(clk,rstn,start,I,J,idle,iplus,jplus,ireset,jreset);
    address_dp DUT2(clk,rstn,start,idle,iplus,jplus,ireset,jreset,address,overflow,I,J);


endmodule