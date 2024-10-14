`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/02 19:17:34
// Design Name: 
// Module Name: lock_tb
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


module lock_tb();
    logic clk;
    logic rstn;
    logic [3:0]key;//4'ha表示4位十六进制数字a(二进制1010)
    logic valid_key;
    logic state_out;
    
    lock DUT (clk,rstn,key,valid_key,state_out);
    
    initial 
    begin
    rstn=1'b1;
    key=4'h0;   
    clk=1'b0;
    end
    
    always #5 clk=~clk;
    
    initial
    begin
    #10;
    rstn=1'b0;
    #10;
    rstn=1'b1;
    #10;
    key=4'hB;
    #30;
    key=4'h1;
    #10;
    key=4'h2;
    #10;
    key=4'h3;
    #10;
    key=4'h4;
    #10;
    key=4'hC;
    #10;
    key=4'hA;
    #10;
    key=4'h5;
     #10;
    key=4'h6;
     #10;
    key=4'h7;
     #10;
    key=4'h8;//new password:5678
    #10;
    key=4'hB;//lock
    #30;
    key=4'h5;
    #10;
    key=4'h6;
    #10;
    key=4'h7;
    #10;
    key=4'h8;
    #10;
    key=4'hC;//unlock
    
    
    //rstn=1'b0;
    end
endmodule
