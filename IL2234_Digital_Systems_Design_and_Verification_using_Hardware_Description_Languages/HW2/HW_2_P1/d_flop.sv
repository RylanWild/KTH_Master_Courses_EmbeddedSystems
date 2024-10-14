`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/26 11:27:35
// Design Name: 
// Module Name: d_flop
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


module d_flop  (
  input  logic clk, rst_n,
  input  logic [7:0] d,
  output logic [7:0] q
);

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      q <= 0;
    end else begin
      q <= d;
    end
  end
  
endmodule
