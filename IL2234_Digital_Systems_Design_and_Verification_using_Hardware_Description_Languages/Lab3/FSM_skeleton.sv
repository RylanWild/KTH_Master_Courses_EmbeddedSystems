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
`include "instructions.sv"

module FSM #(
  parameter M = 4, // size of register address
  parameter N = 4, // size of register data
  parameter P = 6  // PC size and instruction memory address
) (
  input  logic clk,
  input  logic rst_n,
  output logic ov_warning,
  /* ---------------------- signals to/from register file --------------------- */
  output logic [  1:0] select_source,//00 01 10
  output logic [M-1:0] write_address,//4bit RF[0:15]
  output logic             write_en,//0 1
  output logic [M-1:0] read_address_A, read_address_B,
  output logic select_destination_A, select_destination_B,//0 1
  output logic [N-1:0] immediate_value,//4bit
  /* --------------------------- signals to/from ALU -------------------------- */
  output logic [2:0] OP,//000,001,010,
  output logic       s_rst,
  input  logic [2:0] ONZ,
  output logic enable,
  /* --------------------------- signals from instruction memory -------------- */
  input  logic [4+2*M-1:0] instruction_in,//12位 4位testcode+M位ra+M位rb
  output logic             en_read_instr,//0 1
  output logic [P-1:0] read_address_instr,//6位 有64个位置
  /*---------------------------Signals to the data memory--------------*/
  output logic SRAM_readEnable,//0 1
  output logic SRAM_writeEnable//0 1
);

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


/*-----------------------------------------------------------------------------*/

enum logic [1:0] { idle = 2'b11, fetch = 2'b00, decode = 2'b01, execute= 2'b10} state, next;
//////////////////////////////////////////////////////////////////////State register/////////////////////////////////////////////////////////////////////////////
always @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    state <= idle;
  end else begin
    state <= next;
  end
end





// Registered the output of the FSM when required
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    ov_reg <= 0;
    Instruction_reg<=0;
    ONZ_reg<=0;
  end else begin
    ov_reg <= ov;
    Instruction_reg<=Instruction_next;
    ONZ_reg<= ONZ_next; 
  end
end

// PC and overflow

always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) begin
    PC     <= 0;
  end else begin
    PC     <= PC_next;
  end
end

/*-----------------------------------------------------------------------------*/
// Describe your next state and output logic here

////////////////////////////////////////////////////////////////// Next state logic///////////////////////////////////////////////////////////////////
always_comb begin
    next=idle;
    case(state)
    idle: 
    begin
    if(ov) next=idle;
    else next=fetch;
    end
    
    fetch: next=decode;
    
    decode:next=execute;
    
    execute:
    begin
    if(ov_warning) next=idle;
    else next=fetch;
    end
    
    default:next=idle;
    endcase
end

/////////////////////////////////////////////////////////// Combinational output logic//////////////////////////////////////////////////////////
always_comb begin
case(state)
    ///////////idle////////////////////////////////////////
        idle:
    begin
        //////////////////
        write_en=0;
        enable=0;
        en_read_instr=0;//0 1
        SRAM_readEnable=0;
        SRAM_writeEnable=0;
        s_rst=0;
        //////////////////
        PC_next=0;
        end
        
     ///////////fetch////////////////////////////////////////
        fetch:
    begin
        //////////////////
        write_en=0;
        enable=0;
        SRAM_readEnable=0;
        SRAM_writeEnable=0;
        s_rst=0;
        //////////////////
        en_read_instr=1;//0 1
        read_address_instr=PC;//6位 0~63
        InstructionMem[read_address_instr]=instruction_in;
        PCMem[PC]=InstructionMem[read_address_instr]; 
        //Instruction_reg=   PCMem[PC];
        
    end
    
   ///////////decode//////////////////////////////////////// 
        decode:
    begin 
        //////////////////
        en_read_instr=0;
        s_rst=0;
        ONZ_next         = ONZ;      
        Instruction_next = instruction_in; 

        //////////////////        
                       
        InstCode   =   instruction_in[3+2*M:2*M];
        OPA        =   instruction_in[2*M-1:M];
        OPB        =   instruction_in[M-1:0];
        if(InstCode<8)                                    //ALU OP
            begin
            read_address_A=OPA;
            read_address_B=OPB;
            select_destination_A= $random;
            select_destination_B=$random;
            if(InstCode==6)begin           
            OP=3'b111;end
            else begin
            OP= InstCode[2:0];//For MOV instruction:OP = 3'b111    For all else:OP = instCode[2:0] 
            end
            
            enable=1'b1;
            end
        else if(InstCode<9)                            //LD,InstCode=8
            begin
            read_address_B       = OPA;           
            SRAM_readEnable      = 1'b1;          
            select_destination_A = 1'b1;           
            select_destination_B = 1'b0;            
            end
        else if(InstCode<10)                            //Store,InstCode=9
            begin
            read_address_A       = OPB;           
            read_address_B       = OPA;          
            SRAM_writeEnable     = 1'b1;           
            select_destination_A = 1'b1;           
            select_destination_B = 1'b1;       
            end
            
        else if(InstCode==10)                           //LI,InstCode=10
            begin
            immediate_value=$signed(OPB) ;
            write_en=1;//0 1
            write_address=OPA;
            select_source   = 2;//00 01 10
            end
        else if(InstCode<15)                            //BRN
            begin
            s_rst=1;
            end
        else                                            //default,all control signals be de-asserted
        begin
        //////////////////
        write_en=0;
        enable=0;
        en_read_instr=0;
        SRAM_readEnable=0;
        SRAM_writeEnable=0;
        s_rst=0;
       //////////////////
        end

    end
        
     ///////////Execute&Update PC//////////////////////////////////////// 
        execute:
    begin
        //////////////////
        write_en=0;
        enable=0;
        en_read_instr=0;
        SRAM_readEnable=0;
        SRAM_writeEnable=0;
        s_rst=0;
        //////////////////
        offset={OPA,OPB};
        InstregCode=Instruction_reg[3+2*M:2*M];
        OPA        = Instruction_reg[2*M-1 : M];
        OPB        = Instruction_reg[M-1:0]; 

        //---------update PC-----------------//
        case(InstregCode)//based on Instruction_reg
        4'b0000:{ov,PC_next}   = PC+1;
        4'b0001:{ov,PC_next}   = PC+1;
        4'b0010:{ov,PC_next}   = PC+1;
        4'b0011:{ov,PC_next}   = PC+1;
        4'b0100:{ov,PC_next}   = PC+1;
        4'b0101:{ov,PC_next}   = PC+1;
        4'b0110:{ov,PC_next}   = PC+1;
        4'b0111:{ov,PC_next}   = PC+1;
        4'b1000:{ov,PC_next}   = PC+1;
        4'b1001:{ov,PC_next}   = PC+1;
        4'b1010:{ov,PC_next}   = PC+1;
        4'b1011://BRN_Z
        begin
           s_rst = 0;           
        if(ONZ_reg[0] == 1) offset  = {OPA, OPB}; else offset = 1;   
        if (offset[2*M-1]==1) begin         
        {ov,PC_next} = PC - offset[2*M-2:0];         
        end  
        else begin         {ov,PC_next} = PC + offset[2*M-2:0];  end       
        end
        4'b1100://BRN_N
        begin
           s_rst = 0;           
        if(ONZ_reg[1] == 1) offset  = {OPA, OPB}; else offset = 1;   
        if (offset[2*M-1]==1) begin         
        {ov,PC_next} = PC - offset[2*M-2:0];         
        end  
        else begin         {ov,PC_next} = PC + offset[2*M-2:0];  end       
        end
        4'b1101://BRN_O
        begin
            s_rst = 0;           
        if(ONZ_reg[2] == 1) offset  = {OPA, OPB}; else offset = 1;   
        if (offset[2*M-1]==1) begin         
        {ov,PC_next} = PC - offset[2*M-2:0];         
        end  
        else begin         {ov,PC_next} = PC + offset[2*M-2:0];  end       
        end
        4'b1110://BRN
        begin
        s_rst = 0;   
        offset ={OPA, OPB};      
        if(offset[2*M-1]==1)   {ov,PC_next} = PC - offset[2*M-2:0];           
        else  {ov,PC_next} = PC + offset[2*M-2:0];         
        end
        
        default:PC_next=PC+1; 
        endcase
        
        
        //---------Update overflow-----------//
        if(PC_next<((2<<(P-1))-1)) ov_warning=0;
        else ov_warning=1;
        
        if(PC<((2<<(P-1))-1)) ov=0;
        else ov=1;
        //-----send to RF--------------------//
        if(InstregCode<7)        //ALU OP
        begin
         write_address = OPA;           
         write_en      = 1;           
         select_source = 0;           
         enable        = 0;   
        //{ov,PC_next}   = PC+1;
        end
        else if(InstregCode==7)//NOP
        begin
        //{ov,PC_next}   = PC+1;
        end
        
        else if(InstregCode==8)//LOAD
        begin
        select_source = 1;           
        write_address = OPA ;          
        write_en      = 1  ; 
       //{ov,PC_next}       = PC+1;  
        end 
        
        else if(InstregCode==9)//Store
        begin
        select_source = 0;                    
        write_en      = 0 ; 
       //{ov,PC_next}       = PC+1;  
        end                
        else if(InstregCode==10)  //Load_Im
        begin 
        select_source = 0;                    
        write_en      = 0 ; 
       //{ov,PC_next}       = PC+1;  
        end
        else                    //default,all control signals be de-asserted
        begin
        //////////////////
        write_en=0;
        enable=0;
        en_read_instr=0;
        SRAM_readEnable=0;
        SRAM_writeEnable=0;
        s_rst=0;
       //////////////////
        end
    end
        
endcase

end
/*-----------------------------------------------------------------------------*/

endmodule
