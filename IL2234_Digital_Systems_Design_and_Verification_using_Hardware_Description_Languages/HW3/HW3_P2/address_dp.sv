`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/03 13:35:18
// Design Name: 
// Module Name: address_dp
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


module address_dp #(parameter A=3, parameter B=4, parameter C=6,parameter D=2,parameter E=1,parameter ADDR_WIDTH=3)
(
    input logic clk,
    input logic rstn,
    input logic start,
    input logic idle,
    input logic iplus,
    input logic jplus,
    input logic ireset,
    input logic jreset,
    
    //output logic [ADDR_WIDTH-1:0] address,
    output logic [31:0] address,
    output logic overflow,
    output logic I,
    output logic J
    );
    logic [2:0]i;
    logic [2:0]j;
    
    always_ff @(posedge clk, negedge rstn,posedge idle)
    begin  
        if(!rstn) 
        begin
            i<=3'b000;
            j<=3'b000;
            address<={ADDR_WIDTH{1'b0}};
        end
        
        else 
            begin
            if(!idle)//idle=0 compute
            address<=A+D*j+E*i;
            else 
            address<={ADDR_WIDTH{1'b0}};
            end
      end
      
     always_ff @(posedge clk, negedge rstn)
      begin
            if(iplus)  i<=i+1;
            if(jplus)  j<=j+1;
            if(ireset) i<=0;  
            if(jreset) j<=0;
             
        assign I   =(i<C);
        assign J   =(j<B-2);
     end
     
     always_comb
     begin
        if(address>{ADDR_WIDTH{1'b1}})
        overflow=1;
        else
        overflow=0;
     end
     
endmodule
