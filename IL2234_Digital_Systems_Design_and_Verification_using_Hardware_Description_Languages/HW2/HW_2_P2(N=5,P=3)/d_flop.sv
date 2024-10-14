`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/27 00:50:20
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
  input  logic clk, rstn,
  input  logic  d,
  output logic  q
);

  always_ff @(posedge clk, negedge rstn) begin
    if (!rstn) begin
      q <= 0;
    end else begin
      q <= d;
    end
  end
  
endmodule
