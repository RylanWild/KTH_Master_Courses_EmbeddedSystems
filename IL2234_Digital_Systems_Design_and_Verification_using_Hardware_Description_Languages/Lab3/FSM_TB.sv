//-------------- Copyright (c) notice -----------------------------------------
//
// The SV code, the logic and concepts described in this file constitute
// the intellectual property of the authors listed below, who are affiliated
// to KTH (Kungliga Tekniska H?gskolan), School of EECS, Kista.
// Any unauthorised use, copy or distribution is strictly prohibited.
// Any authorised use, copy or distribution should carry this copyright notice
// unaltered.
//-----------------------------------------------------------------------------
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
//                                                                         #
//This file is part of IL1332 and IL2234 course.                           #
//                                                                         #
//    The source code is distributed freely: you can                       #
//    redistribute it and/or modify it under the terms of the GNU          #
//    General Public License as published by the Free Software Foundation, #
//    either version 3 of the License, or (at your option) any             #
//    later version.                                                       #
//                                                                         #
//    It is distributed in the hope that it will be useful,                #
//    but WITHOUT ANY WARRANTY; without even the implied warranty of       #
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
//    GNU General Public License for more details.                         #
//                                                                         #
//    See <https://www.gnu.org/licenses/>.                                 #
//                                                                         #
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
`timescale 1ns/1ps

module FSM_TB ();
  `include "instructions.sv"
  parameter M     = 4; // size of register address
  parameter N     = 4; // size of register data
  parameter P     = 6; // PC size and instruction memory address
logic clk;
logic rst_n;
logic ov_warning;
  /* ---------------------- signals to/from register file --------------------- */
logic [  1:0] select_source;//00 01 10
logic [M-1:0] write_address;//4bit RF[0:15]
logic             write_en;//0 1
logic [M-1:0] read_address_A, read_address_B;
logic select_destination_A, select_destination_B;//0 1
logic [N-1:0] immediate_value;//4bit
  /* --------------------------- signals to/from ALU -------------------------- */
logic [2:0] OP;//000,001,010,
logic       s_rst;
logic [2:0] ONZ;
logic enable;
  /* --------------------------- signals from instruction memory -------------- */
logic [4+2*M-1:0] instruction_in;//12位 4位testcode+M位ra+M位rb
logic             en_read_instr;//0 1
logic [P-1:0] read_address_instr;//6位 有64个位置
  /*---------------------------Signals to the data memory--------------*/
logic SRAM_readEnable;//0 1
logic SRAM_writeEnable;//0 1
/* ----------------------------- PROGRAM COUNTER ---------------------------- */
logic [  P-1:0] PC     ;//6位 0~63
logic [  P-1:0] PC_next;//6位 0~63
logic [2:0] ONZ_next;
logic [2:0] ONZ_reg;
logic           ov     ;
logic           ov_reg ;
logic [2*M-1:0] offset ;

/*-----------------------------------------------------------------------------*/
// Add signals and logic here
logic [4+2*M-1:0] InstructionMem [(2<<P-1)-1:0];
logic [4+2*M-1:0] PCMem [(2<<P-1)-1:0];
logic [4+2*M-1:0] Instruction_reg;
logic [4+2*M-1:0] Instruction_next;
logic [3:0]InstCode;
logic [3:0]InstregCode;
logic [M-1:0] OPA;
logic [M-1:0] OPB;
enum logic [1:0] { idle = 2'b11, fetch = 2'b00, decode = 2'b01, execute= 2'b10} state, next;

 FSM #(M,N,P) DUT (.*);
 //fsm_prog_tb #(M,N,P) TB (.*);

  logic [P-1:0] tb_PC;
  
class packet;//generate your instruction using a constraint random class
  rand bit [4+2*M-1:0] instruction_in;
  constraint datarange {instruction_in[2*M+3:2*M]<15;};
endclass

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

initial begin//generate ONZ
  ONZ=3'b000;
    forever begin
    #400;
    ONZ=ONZ+1;
    end 
end 

initial begin//generate instruction_in
    packet pkt;
    pkt = new();
    
    instruction_in = 0;
    forever begin
    #90;//30:3 period,a full cycle of FSM
      pkt.randomize() with { instruction_in[2*M-1:0]+PC< (2<<P);};
      $display("\tinstruction = %0d",pkt.instruction_in);
      instruction_in=pkt.instruction_in;
    end 
    
    forever begin
      @(en_read_instr==1);
      @(posedge clk);
      instruction_in = 0;
    end
  end

  initial begin
    forever begin
      @(DUT.ov);
      if(DUT.ov==1'b1) $finish;
    end
  end
  
//////////assertion//////////////
always @(posedge clk) begin
    assert property (((state==2'b01&&InstCode==4'b1010)||(state==2'b10&&InstCode<9))&&write_en)
    else $error("write_en wrong");
    
    assert property ((state==2'b01&&InstCode<15)&&s_rst)
    else $error("s_rst wrong");
    
    assert property ((state==2'b01&&InstCode<8)&&enable)
    else $error("enable wrong");
    
    assert property (state==2'b00&&en_read_instr)
    else $error("en_read_instr wrong");   
  
    assert property ((state==2'b01&&InstCode==8)&&SRAM_readEnable)
    else $error("SRAM_readEnable wrong");   
    
    assert property ((state==2'b01&&InstCode==9)&&SRAM_writeEnable)
    else $error("SRAM_writeEnable wrong");      
end


endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
