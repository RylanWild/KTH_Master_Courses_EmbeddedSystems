---------------- Copyright (c) notice ----------------------------------------------------
--
-- The VHDL code, the logic and concepts described in this file constitute
-- the intellectual property of the authors listed below, who are affiliated
-- to KTH(Kungliga Tekniska H�gskolan), School of ICT, Kista.
-- Any unauthorised use, copy or distribution is strictly prohibited.
-- Any authorised use, copy or distribution should carry this copyright notice
-- unaltered.
-- AGU Package. This package makes the AGU generic. Just change the values 
-- over here and the AGU will work according to these values. We can also define
-- the instructions operand widths in this package.
--
--- Try to use records for future versions and code reduction
--
--Author: Muhammad ali Shami
--Contact: shami@kth.se
--
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL; 
USE ieee.numeric_std.ALL;
USE work.misc.ALL;

PACKAGE SINGLEPORT_SRAM_AGU_types_n_constants IS


 --Constans for SRAM_Sequencer
CONSTANT MAX_DELAY               : INTEGER := 512;
CONSTANT MAX_INCR_DECR_VALUE     : INTEGER := 64;
CONSTANT	MAX_REPETITION   : INTEGER := 512;
CONSTANT RAM_DEPTH               : INTEGER := 128;
CONSTANT AGU_INSTR_WIDTH         : INTEGER := 91; 
 
 
 ---------------------AGU Signals----------------------------------------------------------------
 
--------First Part---------------------
--------Common Part--------------
CONSTANT new_instr_s                  : INTEGER :=1;  CONSTANT new_instr_e             : INTEGER :=1;  CONSTANT new_instr_WIDTH             : INTEGER :=1;
CONSTANT mode_s                       : INTEGER :=2;  CONSTANT mode_e                  : INTEGER :=2;  CONSTANT mode_WIDTH                  : INTEGER :=1;
CONSTANT start_addrs_s                : INTEGER :=3;  CONSTANT start_addrs_e           : INTEGER :=9;  CONSTANT start_addrs_WIDTH           : INTEGER :=7;
CONSTANT end_addrs_s                  : INTEGER :=10; CONSTANT end_addrs_e             : INTEGER :=16; CONSTANT end_addrs_WIDTH             : INTEGER :=7;
--------Vector Addressing--------
CONSTANT incr_decr_s                  : INTEGER :=17; CONSTANT incr_decr_e             : INTEGER :=17; CONSTANT incr_decr_WIDTH             : INTEGER :=1;
CONSTANT incr_decr_value_s            : INTEGER :=18; CONSTANT incr_decr_value_e       : INTEGER :=24; CONSTANT incr_decr_value_WIDTH       : INTEGER :=7;
CONSTANT initial_delay_s              : INTEGER :=25; CONSTANT initial_delay_e         : INTEGER :=30; CONSTANT initial_delay_WIDTH         : INTEGER :=6;
CONSTANT outputcontrol_s              : INTEGER :=31; CONSTANT outputcontrol_e         : INTEGER :=32; CONSTANT outputcontrol_WIDTH         : INTEGER :=2;

--------Bit Reverse Addressing---
CONSTANT start_stage_s                : INTEGER :=17; CONSTANT start_stage_e           : INTEGER :=19; CONSTANT start_stage_WIDTH           : INTEGER :=3;
CONSTANT end_stage_s                  : INTEGER :=20; CONSTANT end_stage_e             : INTEGER :=22; CONSTANT end_stage_WIDTH             : INTEGER :=3;



-------Second Part-------------------- 
CONSTANT instruction_complete_s       : INTEGER :=33; CONSTANT instruction_complete_e        : INTEGER :=33; CONSTANT instruction_complete_WIDTH         : INTEGER :=1;
CONSTANT infinite_loop_s              : INTEGER :=34; CONSTANT infinite_loop_e               : INTEGER :=34;  CONSTANT infinite_loop_WIDTH               : INTEGER :=1;
CONSTANT repetition_delay_s           : INTEGER :=35; CONSTANT repetition_delay_e            : INTEGER :=43;  CONSTANT repetition_delay_WIDTH            : INTEGER :=9;  --9
CONSTANT no_of_repetitions_s          : INTEGER :=44; CONSTANT no_of_repetitions_e           : INTEGER :=52;  CONSTANT no_of_repetitions_WIDTH           : INTEGER :=9;  
CONSTANT repetition_incr_decr_s       : INTEGER :=53; CONSTANT repetition_incr_decr_e        : INTEGER :=53;  CONSTANT repetition_incr_decr_WIDTH        : INTEGER :=1;    --1
CONSTANT repetition_incr_decr_value_s : INTEGER :=54; CONSTANT repetition_incr_decr_value_e  : INTEGER :=59;  CONSTANT repetition_incr_decr_value_WIDTH  : INTEGER :=6;  --6
CONSTANT middle_delay_s               : INTEGER :=60; CONSTANT middle_delay_e                : INTEGER :=68;  CONSTANT middle_delay_WIDTH                : INTEGER :=9;



------Third Part----------------------
CONSTANT SRAM_inout_select_s          : INTEGER :=69; CONSTANT SRAM_inout_select_e           : INTEGER :=69;  CONSTANT SRAM_inout_select_WIDTH           : INTEGER :=1;
CONSTANT range_counter_s              : INTEGER :=70; CONSTANT range_counter_e               : INTEGER :=76;  CONSTANT range_counter_WIDTH               : INTEGER :=7;
CONSTANT hault_delay_s                : INTEGER :=77; CONSTANT hault_delay_e                 : INTEGER :=85;  CONSTANT hault_delay_WIDTH                 : INTEGER :=9;
CONSTANT hault_counter_s              : INTEGER :=86; CONSTANT hault_counter_e               : INTEGER :=91;  CONSTANT hault_counter_WIDTH               : INTEGER :=6;

 
 
 ---------------------------------------
-- Types
---------------------------------------
 TYPE Refi_AGU_st_ty IS (IDLE_ST, COUNT_ST,  RD_WR_ST, BIT_REVRS_ST, REPETITION_ST);
 
 END SINGLEPORT_SRAM_AGU_types_n_constants;


