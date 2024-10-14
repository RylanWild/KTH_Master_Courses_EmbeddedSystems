`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/07 22:38:34
// Design Name: 
// Module Name: RF_TB
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


module RF_tb #(parameter N = 8, parameter addressBits = 2)
( );
    logic clk;
    logic rst_n;
    logic selectDestinationA;
    logic selectDestinationB;
    
    logic [1:0] selectSource;
    logic [addressBits-1:0] writeAddress;
    logic write_en;
    logic [addressBits-1:0] readAddressA;
    logic [addressBits-1:0] readAddressB;

    logic [N-1:0] A;
    logic [N-1:0] B;
    logic [N-1:0] C;
    /* --------------------------------- Outputs -------------------------------- */
    logic [N-1:0] destination1A;
    logic [N-1:0] destination2A;
    logic [N-1:0] destination1B;
    logic [N-1:0] destination2B;
    
    logic [N-1:0] Q [(2<<addressBits-1)-1:0];
    logic [(2<<addressBits-1)-1:0] en;
    logic [N-1:0] data;
    logic [N-1:0] outA;
    logic [N-1:0] outB;
    //////////////////////////////
    logic [31:0] QReset [(2<<addressBits-1)-1:0];//how many times Q[i] has been reset
    logic [31:0] QWrite [(2<<addressBits-1)-1:0];//how many times Q[i] has been writen into
    logic [31:0] QReadA [(2<<addressBits-1)-1:0];//how many times Q[i] has been read by A
    logic [31:0] QReadB [(2<<addressBits-1)-1:0];//how many times Q[i] has been read by B
    logic [31:0] QRead [(2<<addressBits-1)-1:0];//how many times Q[i] has been read totally
    
    scoreboard SCB(
    clk,
    rst_n,
    
    selectSource,
    writeAddress,
    write_en,
    readAddressA,
    readAddressB,

    /* --------------------------------- Outputs -------------------------------- */
    QReset,//how many times Q[i] has been reset
    QWrite,//how many times Q[i] has been writen into
    QReadA,//how many times Q[i] has been read by A
    QReadB,//how many times Q[i] has been read by B
    QRead//how many times Q[i] has been read totally
    );
    
    RF DUT(
    clk,
    rst_n,
    selectDestinationA,
    selectDestinationB,
    
    selectSource,
    writeAddress,
    write_en,
    readAddressA,
    readAddressB,

    A, 
    B, 
    C, 
    /* --------------------------------- Outputs -------------------------------- */
    destination1A,
    destination2A,
    destination1B,
    destination2B,
    Q
    );
    
    
    
    
    initial 
    begin
        clk=1'b0;
        rst_n=1'b0;
    end
    
     always #5 clk=~clk;  //period=10
    
    initial
    begin
        selectDestinationA=1'b0;
        selectDestinationB=1'b0;
        selectSource=2'b00;
        write_en=1'b0;
      #10;
      
        selectDestinationA=1'b0;
        selectDestinationB=1'b1;
        selectSource=2'b00;
        write_en=1'b1;
        rst_n=1'b1;
     #50;
     
        selectDestinationA=1'b1;
        selectDestinationB=1'b0;
        selectSource=2'b01;
        write_en=1'b1;
      #50;
      
        selectDestinationA=1'b1;
        selectDestinationB=1'b1;
        selectSource=2'b10;
        write_en=1'b1;
     #50;
     
        selectDestinationA=1'b0;
        selectDestinationB=1'b0;
        selectSource=2'b00;
        write_en=1'b1;
      #50;
      
        selectDestinationA=1'b0;
        selectDestinationB=1'b1;
        selectSource=2'b01;
        write_en=1'b0;
     #50;
     
        selectDestinationA=1'b1;
        selectDestinationB=1'b0;
        selectSource=2'b10;
        write_en=1'b1;
     #50;
     
        selectDestinationA=1'b1;
        selectDestinationB=1'b1;
        selectSource=2'b00;
        write_en=1'b1;
        rst_n=1'b0;
     #50;     
     
        selectDestinationA=1'b1;
        selectDestinationB=1'b1;
        selectSource=2'b00;
        write_en=1'b1;
        rst_n=1'b1;
     #50;     
     $finish;
        
    end
    
    initial 
    begin
        for(int i=0;i<50;i++)
        begin
        A=$random;
        B=$random;
        C=$random;
        writeAddress=$random;
        readAddressA=$random;
        readAddressB=$random;
        #10;
        end
    end
endmodule
