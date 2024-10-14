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
module micpro_tb  #(
parameter RF_addressBits = 3, // size of register address
parameter N = 8, // size of register data
parameter ROM_addressBits = 6, // PC size and instruction memory address
parameter ADD     = 4'b0000,
parameter SUB     = 4'b0001,
parameter AND     = 4'b0010,
parameter OR      = 4'b0011,
parameter XOR     = 4'b0100,
parameter NOT     = 4'b0101,
parameter MOV     = 4'b0110,
parameter NOP     = 4'b0111,
parameter LOAD    = 4'b1000,
parameter STORE   = 4'b1001,
parameter LOAD_IM = 4'b1010,
parameter BRN_Z   = 4'b1011,
parameter BRN_N   = 4'b1100,
parameter BRN_O   = 4'b1101,
parameter BRN     = 4'b1110

) 
();
  logic clk        = 0;
  logic rst_n      = 0;
  logic overflowPC    ;

  microprocessor_n_memory #(N,ROM_addressBits,RF_addressBits) DUT (clk,rst_n,overflowPC);
  //DUT ports
  logic s_rst;
  assign s_rst=DUT.microprocessor.s_rst;
  logic [N-1:0] Q [(2<<RF_addressBits-1)-1:0];
  assign Q=DUT.microprocessor.RF.Q;
  logic ROM_readEnable;
  assign ROM_readEnable=DUT.ROM.ROM_readEnable;
  logic [3:0]InstCode;
  assign InstCode=DUT.microprocessor.FSM.InstCode;
  logic enable;
  assign enable=DUT.microprocessor.ALU.enable;
  logic write_en_RF;
  assign write_en_RF=DUT.microprocessor.write_en_RF;
  always #5ns clk = ~clk;
  logic select_destination_A;
  assign select_destination_A=DUT.microprocessor.FSM.select_destination_A;
  logic select_destination_B;
  assign select_destination_B=DUT.microprocessor.FSM.select_destination_B; 
  logic [1:0] select_source;
  assign select_source=DUT.microprocessor.FSM.select_source;
  logic SRAM_writeEnable;
  assign SRAM_writeEnable=DUT.SRAM.SRAM_writeEnable; 
  logic SRAM_readEnable;
  assign SRAM_readEnable=DUT.SRAM.SRAM_readEnable;
  logic read_address_A;
  assign read_address_A=DUT.microprocessor.FSM.read_address_A;
  logic read_address_B;
  assign read_address_B=DUT.microprocessor.FSM.read_address_B;
  logic [2:0] ONZ;
  assign ONZ=DUT.microprocessor.ONZ;
  logic [1:0] state;
  assign state=DUT.microprocessor.FSM.state;
  logic signed [N-1:0] Y;
  assign Y=DUT.microprocessor.ALU.Y;
  logic source_A;
  assign source_A=DUT.microprocessor.RF.source_A;
  logic source_B;
  assign source_B=DUT.microprocessor.RF.source_B;
  logic source_C;
  assign source_C=DUT.microprocessor.RF.source_C;
  logic source_A_reg;
  logic source_B_reg;
  logic source_C_reg;
  logic [N-1:0] destination1A;
  assign destination1A=DUT.microprocessor.RF.destination1A;
  logic [N-1:0] destination2A;
  assign destination2A=DUT.microprocessor.RF.destination2A;
  logic [N-1:0] destination1B;
  assign destination1B=DUT.microprocessor.RF.destination1B;
  logic [N-1:0] destination2B;
  assign destination2B=DUT.microprocessor.RF.destination2B;
  
  
   property test_alu;
    @(posedge clk)
    $fell(ROM_readEnable)&&(InstCode <= 4'b0110 && InstCode >= 4'b0000)&&rst_n |-> enable ##1 write_en_RF;
  endproperty

  property test_store;
    @(posedge clk)  
    $fell(ROM_readEnable)&&(InstCode==4'b1001)|-> select_destination_A&&select_destination_B&&SRAM_writeEnable;
  endproperty

  property test_load;
    @(posedge clk)  
    $fell(ROM_readEnable)&&(InstCode==4'b1000)|-> select_destination_A&&SRAM_readEnable ##1 write_en_RF&&(select_source==2'b01); 
  endproperty

  property test_imm;
    @(posedge clk)  
    $fell(ROM_readEnable)&&(InstCode==4'b1010)|-> write_en_RF&&(select_source==2'b10); 
  endproperty

  property test_BNZ;
    @(posedge clk)  
    $fell(ROM_readEnable)&&(InstCode<=4'b1110&&InstCode>=4'b1011)|-> s_rst; 
  endproperty

  assert property(test_alu) $display("alu set pass");
  else $display("alu set fail");

  assert property(test_store) $display("store set pass");
  else $display("store set fail");

  assert property(test_load) $display("load set pass");
  else $display("load set fail");

  assert property(test_imm) $display("immediate write set pass");
  else $display("immediate write set fail");

  assert property(test_BNZ) $display("test_BNZ set pass");
  else $display("test_BNZ set fail");
  
  covergroup instruction_type_cg @(posedge clk);
    option.per_instance = 1;
    coverpoint InstCode {
      bins inst = {ADD, SUB, AND, OR, XOR, NOT, MOV, NOP, LOAD, STORE,LOAD_IM,BRN_Z, BRN_N, BRN_O, BRN};
    }
  endgroup
  
  covergroup instruction_alu_cg @(posedge clk);
    option.per_instance = 1;
    coverpoint InstCode {
      bins inst = {ADD, SUB, AND, OR, XOR, NOT, MOV};
    }
  endgroup
  
  covergroup instruction_bnz_cg @(posedge clk);
    //option.per_instance = 1;
    cp_op:coverpoint {BRN_Z, BRN_N, BRN_O, BRN};
    cp_offset:coverpoint {read_address_A,read_address_B};
    xcp_src_op : cross cp_op, cp_offset;
  endgroup
  
  instruction_type_cg instruction_type_inst = new();
  instruction_alu_cg instruction_alu_inst = new();
  instruction_bnz_cg instruction_bnz_inst = new();
  
  initial begin  
    //reset to zero RF etc
    rst_n = 0;
    #10ns;
    rst_n = 1;
  end
  
  initial begin
    clk = 0;
    rst_n = 0;
    #5;
    assert (ONZ==3'b000) $display("reset test ONZ pass");
    else   $error("reset test ONZ fail");
    assert (state==2'b11) $display("reset test state pass");
    else   $error("reset test state fail");
    assert (Y==N'(0)) $display("reset test ALU_out pass");
    else   $error("reset test ALU_out fail");
    for(int i=0;i<2**RF_addressBits;i++) begin
        if(i==1) begin
            assert(Q[i]==8'b11111111) $display("reset test RF_memory[%d] pass",i);
            else $display("reset test RF_memory[%d] fail",i);
        end else begin
            assert(Q[i]==8'b00000000) $display("reset test RF_memory[%d] pass",i);
            else $display("reset test RF_memory[%d] fail",i);
        end
    end
    clk= 1'b1;
    #5;
    rst_n = 1;
    forever begin
      clk = ~clk;
      #5;
    end
  end

  initial begin
    forever begin
      @(overflowPC);
      if(overflowPC==1'b1) begin
        $display("test RF memory for %d times, success %d times,fail %d time", scoreboard_rf_state_hit+scoreboard_rf_state_miss,scoreboard_rf_state_hit,scoreboard_rf_state_miss);
        $display("test RF out for %d times, success %d times,fail %d time", scoreboard_rf_out_hit+scoreboard_rf_out_miss,scoreboard_rf_out_hit,scoreboard_rf_out_miss);
        $display("Coverage instruction= %0.2f %%", instruction_type_inst.get_inst_coverage());
        $display("Coverage instruction alu= %0.2f %%", instruction_alu_inst.get_inst_coverage());
        $display("Coverage instruction bnz= %0.2f %%", instruction_bnz_inst.get_inst_coverage());
        $display("Coverage instruction bnz code= %0.2f %%", instruction_bnz_inst.cp_op.get_inst_coverage());
        $display("Coverage instruction bnz offset= %0.2f %%", instruction_bnz_inst.cp_offset.get_inst_coverage());
        $display("Coverage instruction bnz cross= %0.2f %%", instruction_bnz_inst.xcp_src_op.get_inst_coverage());
        $finish;
      end
    end
  end

  int scoreboard_rf_state_hit = 0;
  int scoreboard_rf_state_miss = 0;
  int scoreboard_rf_out_hit = 0;
  int scoreboard_rf_out_miss = 0;

  logic signed [N-1:0] ra_tmp, rb_tmp;
  logic signed [N:0] result_tmp;

always @(posedge clk) begin
    source_A_reg<=source_A;
    source_B_reg<=source_B;
    source_C_reg<=source_C;
    if(state == 2'b01)begin //decode
      if(InstCode == 4'b1001)begin //Store
        if(destination2A == Q[read_address_B] && destination2B == Q[read_address_A])
          scoreboard_rf_out_hit++;
        else 
          scoreboard_rf_out_miss++;
      end
      else if(InstCode == 4'b1010) begin//Load_Imed
        @(posedge clk);
        if(Q[read_address_A] == source_C_reg)
          scoreboard_rf_state_hit++;
        else
          scoreboard_rf_state_miss++;
      end
    end

    if(state == 2'b10) begin    //execute
      if(InstCode== 4'b1000)begin //load
        @(posedge clk);
        if(Q[read_address_A] == source_B_reg)
          scoreboard_rf_state_hit++;
        else
          scoreboard_rf_state_miss++;
      end  
      else if(InstCode >= 4'b0000 && InstCode <= 4'b0110) begin
        ra_tmp = Q[read_address_A];
        rb_tmp = Q[read_address_B];
        @(posedge clk);
        case(InstCode) 
          4'b0000: begin  // add
            result_tmp = ra_tmp + rb_tmp;
            if(Q[read_address_A] == result_tmp[N-1:0])
              scoreboard_rf_state_hit++;
            else  
              scoreboard_rf_state_miss++;
          end
          4'b0001: begin  //sub
            result_tmp = ra_tmp - rb_tmp;
            if(Q[read_address_A] == result_tmp[N-1:0])
              scoreboard_rf_state_hit++;
            else
              scoreboard_rf_state_miss++;
          end
          4'b0010: begin  //and
            result_tmp = ra_tmp & rb_tmp;
            if(Q[read_address_A] == result_tmp[N-1:0])
              scoreboard_rf_state_hit++;
            else
              scoreboard_rf_state_miss++;
          end
          4'b0011: begin  //or
            if(Q[read_address_A] == ra_tmp | rb_tmp)
              scoreboard_rf_state_hit++;
            else
              scoreboard_rf_state_miss++; 
          end
          4'b0100: begin  //xor
            result_tmp = ra_tmp ^ rb_tmp;
            if(Q[read_address_A] == result_tmp[N-1:0])
              scoreboard_rf_state_hit++;
            else
              scoreboard_rf_state_miss++; 
          end
          4'b0101: begin  //inc
            result_tmp = ra_tmp + 1;
            if(Q[read_address_A] == result_tmp[N-1:0])
              scoreboard_rf_state_hit++;
            else
              scoreboard_rf_state_miss++; 
          end
          4'b0110: begin  //mov
            if(Q[read_address_A] == rb_tmp)
              scoreboard_rf_state_hit++;
            else
              scoreboard_rf_state_miss++; 
          end
        endcase
      end
    end
  end
  
  always @(posedge clk) begin
    if (overflowPC) begin
      assert (DUT.SRAM.SRAM_memory[0]==2) $display("Data in SRAM 0 location are correct");
      else   $error("Data in the SRAM 0 location are wrong");
      assert (DUT.SRAM.SRAM_memory[1]==3) $display("Data in SRAM 1 location are correct");
      else   $error("Data in the SRAM 1 location are wrong");
      assert (DUT.SRAM.SRAM_memory[2]==4) $display("Data in SRAM 2 location are correct");
      else   $error("Data in the SRAM 2 location are wrong");
      assert (DUT.SRAM.SRAM_memory[3]==5) $display("Data in SRAM 3 location are correct");
      else   $error("Data in the SRAM 3 location are wrong");
      assert (DUT.SRAM.SRAM_memory[4]==6) $display("Data in SRAM 4 location are correct");
      else   $error("Data in the SRAM 4 location are wrong");
      assert (DUT.SRAM.SRAM_memory[5]==7) $display("Data in SRAM 5 location are correct");
      else   $error("Data in the SRAM 5 location are wrong");
      $finish;
    end
  end
endmodule