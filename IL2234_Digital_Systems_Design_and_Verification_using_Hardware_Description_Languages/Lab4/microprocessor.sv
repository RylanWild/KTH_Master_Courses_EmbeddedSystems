`timescale 1ns / 1ps

module microprocessor #(
  parameter N = 8, // size of register data
  parameter ROM_addressBits = 6,
  parameter RF_addressBits  = 3 )(
  /* --------------------------------- Inputs --------------------------------- */
  input  logic                           clk             ,
  input  logic                           rst_n           ,
  input  logic [ 4+2*RF_addressBits-1:0] ROM_data        ,
  input  logic [                  N-1:0] SRAM_data       ,
  /* --------------------------------- Outputs -------------------------------- */
  output logic                           overflowPC      ,
  //Memory
  output logic                           ROM_readEnable  ,
  output logic                           SRAM_readEnable ,
  output logic                           SRAM_writeEnable,
  output logic [ROM_addressBits-1:0]     ROM_address     ,
  output logic [(2**ROM_addressBits)-1:0] SRAM_address    ,
  output logic [                  N-1:0] SRAM_data_in
);

  logic [  1:0] select_source;//00 01 10
  logic [RF_addressBits-1:0] write_address;//4bit RF[0:15]
  logic write_en_RF;//0 1
  logic read_en;
  logic [RF_addressBits-1:0] read_address_A;
  logic [RF_addressBits-1:0] read_address_B;
  logic select_destination_A;
  logic select_destination_B;//0 1
  logic [N-1:0] immediate_value;//4bit
  logic en_read_instr;//0 1
  logic [2:0] OP;//000,001,010,
  logic       s_rst;
  logic enable;
  logic [2:0] ONZ;
  logic [4+2*RF_addressBits-1:0] instruction_in;//
  logic en_read_addr_A;
  logic [ROM_addressBits-1:0] read_add_instr;
  //logic readorwrite; 
  logic [ROM_addressBits-1:0] read_address_instr;//6??   64  ??  
  logic ov;
  logic ov_warning;

  logic readorwrite_RF;//from FSM    
  logic [N-1:0] source_A; //from ALU
  logic [N-1:0] source_B; //from SRAM
  logic [N-1:0] source_C; //from FSM
  logic [N-1:0] destination1A;
  logic [N-1:0] destination2A;
  logic [N-1:0] destination1B;
  logic [N-1:0] destination2B;

  logic signed [N-1:0] A; //from RF
  logic signed [N-1:0] B; //from RF 
  logic signed [N-1:0] Y;//to RF

FSM #(RF_addressBits,N,ROM_addressBits) FSM (
  .clk,
  .rst_n,
  .ov,
  .ov_warning,
  .ONZ,
  .instruction_in,
  
  .s_rst,
  .enable,
  .en_read_addr_A,
  .read_add_instr,
  .SRAM_readEnable,
  .SRAM_writeEnable,
  .immediate_value,
  .write_en_RF,
  .en_read_instr,
  .select_source,
  .write_address,
  .read_address_A,
  .read_address_B,
  .select_destination_A,
  .select_destination_B,  
  .OP
);

ALU #(N) ALU(
  .clk,
  .rst_n,
  .s_rst,
  .enable,
  .A,//
  .B,  
  .OP, 
  .ONZ,
  .Y
);
RF #(N,RF_addressBits) RF(
  .clk,
  .rst_n,
  .source_A,
  .source_B, 
  .source_C, 
  .write_en_RF,
  .select_source,
  .write_address,
  .read_address_A,
  .read_address_B,
  .select_destination_A,
  .select_destination_B,

  .destination1A,
  .destination2A,
  .destination1B,
  .destination2B
);

always_comb
begin
    instruction_in=ROM_data;
    //ROM_readEnable=en_read_addr_A;
    ROM_readEnable=en_read_instr;
    ROM_address=read_add_instr;
    /*if(readorwrite==1) //read
    begin
        SRAM_readEnable=1;
        SRAM_writeEnable=0;
    end
        else //write
    begin
        SRAM_readEnable=0;
        SRAM_writeEnable=1;
    end    */
    source_C=immediate_value;
    readorwrite_RF=en_read_instr;
    overflowPC=ov_warning;
    
    source_A=Y;
    source_B=SRAM_data;
    A=destination1A;
    SRAM_address=destination2A;
    B=destination1B;
    SRAM_data_in=destination2B;  
end

endmodule
