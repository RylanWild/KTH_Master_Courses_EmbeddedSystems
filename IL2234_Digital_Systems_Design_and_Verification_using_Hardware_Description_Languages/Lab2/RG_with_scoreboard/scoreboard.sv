`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/13 13:19:39
// Design Name: 
// Module Name: scoreboard
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


module scoreboard  #(parameter N = 8, parameter addressBits = 2)(
    input logic clk,
    input logic rst_n,
    
    input logic [1:0] selectSource,
    input logic [addressBits-1:0] writeAddress,
    input logic write_en,
    input logic [addressBits-1:0] readAddressA,
    input logic [addressBits-1:0] readAddressB,

    /* --------------------------------- Outputs -------------------------------- */
    output logic [31:0] QReset [(2<<addressBits-1)-1:0],//how many times Q[i] has been reset
    output logic [31:0] QWrite [(2<<addressBits-1)-1:0],//how many times Q[i] has been writen into
    output logic [31:0] QReadA [(2<<addressBits-1)-1:0],//how many times Q[i] has been read by A
    output logic [31:0] QReadB [(2<<addressBits-1)-1:0],//how many times Q[i] has been read by B
    output logic [31:0] QRead [(2<<addressBits-1)-1:0]//how many times Q[i] has been read totally
    );
    
    always_comb
    begin
     for (int i = 0; i<(2<<addressBits-1) ;i=i+1 ) 
        begin
            QReset [i]=0; 
            QWrite [i]=0;
            QReadA [i]=0;
            QReadB [i]=0;
            QRead  [i]=0;  
        end
    end
    
    always_ff @(posedge rst_n, negedge rst_n)
    begin
       
        if(rst_n!=0)
        begin
            for (int i = 0; i<(2<<addressBits-1) ;i=i+1 ) 
                 QReset [i]=QReset [i]+1;
        end
    end
    
always_comb
begin        
    if(write_en)
    begin
        for(int i=0;i<(2<<addressBits-1);i++)
        begin
            if(writeAddress==i)
            QWrite [i]=QWrite [i]+1;
        end
    end
    
     else
     begin
        for(int i=0;i<(2<<addressBits-1);i++)
        begin
            if(writeAddress==i)
            QWrite [i]=QWrite [i];
        end
    end
end

always_comb
begin        
        for(int i=0;i<(2<<addressBits-1);i++)
        begin
            if(readAddressA==i)
            QReadA [i]=QReadA [i]+1;
        end   
end

always_comb
begin
        for(int i=0;i<(2<<addressBits-1);i++)
        begin
            if(readAddressB==i)
            QReadB [i]=QReadB [i]+1;
        end
end 

always_comb
begin
  for(int i=0;i<(2<<addressBits-1);i++)
  QRead [i]=QReadA [i]+ QReadB [i];
end

endmodule
