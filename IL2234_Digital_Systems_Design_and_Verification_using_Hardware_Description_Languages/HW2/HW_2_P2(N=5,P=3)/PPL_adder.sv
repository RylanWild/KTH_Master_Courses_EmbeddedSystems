`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/27 00:45:39
// Design Name: 
// Module Name: PPL_adder
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


module PPL_adder(
    input logic clk,
    input logic rstn,
    input logic [4:0]a,
    input logic [4:0]b,
    output logic [4:0]sum,
    output logic cout
    );
    logic [7:0]next;
    logic [7:0]stage;
    logic [4:0]c;
    logic [4:0]s;
    
    
    always_ff @(posedge clk,negedge rstn) 
    begin
        if(!rstn)
            begin
            for(int i=0;i<8;i++)
                begin
                    stage[i]<=1'b0;
                    //next[i]<=1'b0;
                end
                
            end
        else
            begin
            for(int i=0;i<8;i++)
                begin
                    stage[i]<=next[i];                
                end
            end
    end
       
       
        //layer 1
        full_adder FA1(a[0],b[0],1'b0,c[0],s[0]);
        full_adder FA2(a[1],b[1],c[0],c[1],s[1]);
        full_adder FA3(a[2],b[2],c[1],c[2],s[2]);
        
        assign next[0]=s[0];
        assign next[1]=s[1];
        assign next[2]=s[2];
        assign next[3]=c[2];
        assign next[4]=b[3];
        assign next[5]=a[3];
        assign next[6]=b[4];
        assign next[7]=a[4];
        
        //layer2
        full_adder FA4(stage[5],stage[4],stage[3],c[3],s[3]);
        full_adder FA5(stage[7],stage[6],c[3],c[4],s[4]);
        assign cout=c[4];
        assign sum={s[4],s[3],stage[2],stage[1],stage[0]};

endmodule

