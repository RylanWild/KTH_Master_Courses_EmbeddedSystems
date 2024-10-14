`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/08 14:22:38
// Design Name: 
// Module Name: bin2gray_tb
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
`timescale 1ns/1ns
`define half_period 5

module bin2gray_tb();
 logic [3:0] binary;
 logic [3:0] bcd;
 logic i;

bin2gray DUT(binary,bcd);

initial begin
  binary=4'b0000;
  
  for(i=0;i<15;i=i+1) begin
    #5
    binary=binary+1;
    #5;
  end
  
 end

endmodule
