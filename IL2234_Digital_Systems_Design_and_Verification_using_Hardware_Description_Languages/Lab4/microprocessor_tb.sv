`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/18 22:50:52
// Design Name: 
// Module Name: microprocessor_tb
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


module microprocessor_tb#( parameter M = 4, // size of register address
  parameter N = 4, // size of register data
  parameter ROM_addressBits = 6,
  parameter RF_addressBits  = 3 )( );
  
logic                           clk             ;
logic                           rst_n           ;
logic [ 4+2*M-1:0]              ROM_data        ;
logic [                  N-1:0] SRAM_data       ;
  /* --------------------------------- Outputs -------------------------------- */
logic                           overflowPC      ;
logic                           ROM_readEnable  ;
logic                           SRAM_readEnable ;
logic                           SRAM_writeEnable;
logic [    ROM_addressBits-1:0] ROM_address     ;
logic [(2**ROM_addressBits)-1:0] SRAM_address   ;
logic [                  N-1:0] SRAM_data_in    ;

 //microprocessor #(M,N,ROM_addressBits,RF_addressBits) DUT (.*);
 
initial begin //generate clk rst_n
    clk = 0;
    rst_n = 0;
    #5;
    clk= 1'b1;
    #5;
    rst_n = 1;
    forever begin
      clk = ~clk;
      #5;
    end
end

initial begin
ROM_data=0;
SRAM_data=0;
forever begin
#30;
ROM_data=$random;
SRAM_data=$random;
end
end


endmodule
