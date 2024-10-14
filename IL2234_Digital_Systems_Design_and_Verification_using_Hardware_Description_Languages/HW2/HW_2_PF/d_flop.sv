`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/22 19:59:45
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


module d_flop(clk,rst_n,d,q);
    input logic clk;
    input logic rst_n;
    input logic d;
    output logic q;
    
    always_ff @(posedge clk) begin
        if(!rst_n) 
            begin
                q<=1'b0;
            end
        else
            begin
                q<=d;
            end 
    end
endmodule
