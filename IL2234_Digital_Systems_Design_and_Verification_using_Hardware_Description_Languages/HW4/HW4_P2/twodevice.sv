`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/15 11:56:22
// Design Name: 
// Module Name: twodevice
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

//simulate the behaviour of master and slave 
module twodevice(
input logic clk,
//input logic send,
input logic active,
output logic ready,
output wire [2:0] data
    );
assign data=(!active||!ready)?'bz:$random;

always_ff @(posedge clk)
begin
if(active) ready=1;
else ready=0;
end


endmodule
