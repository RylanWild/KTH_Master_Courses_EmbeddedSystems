---------------- Copyright (c) notice ----------------------------------------------------
--
-- The VHDL code, the logic and concepts described in this file constitute
-- the intellectual property of the authors listed below, who are affiliated
-- to KTH(Kungliga Tekniska H�gskolan), School of ICT, Kista.
-- Any unauthorised use, copy or distribution is strictly prohibited.
-- Any authorised use, copy or distribution should carry this copyright notice
-- unaltered.
--
--Author: Muhammad ali Shami
--Contact: shami@kth.se
--
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL; 
USE ieee.numeric_std.ALL;
USE work.misc.ALL;

PACKAGE SRAMTile_types_n_constants IS


-- CONSTANT SRAM_AGU_INSTR_WIDTH             : INTEGER := 104;
-- CONSTANT SRAM_INCR_DECR_VALUE              : INTEGER := 64;
-- CONSTANT SRAM_DELAY                        : INTEGER := 512;
-- CONSTANT SRAM_REPETITIONS                  : INTEGER := 512;
 
 
   
 ---------------------AGU Signals----------------------------------------------------------------
 ------------------------------------------------------------------------------------------------
--CONSTANT new_instr_s            : INTEGER :=1; CONSTANT new_instr_e             : INTEGER :=1;  CONSTANT new_instr_WIDTH            : INTEGER :=1;
--CONSTANT mode_s                 : INTEGER :=2; CONSTANT mode_e                  : INTEGER :=2;  CONSTANT mode_WIDTH                 : INTEGER :=1;
--CONSTANT start_addrs_s          : INTEGER :=3; CONSTANT start_addrs_e           : INTEGER :=11; CONSTANT start_addrs_WIDTH          : INTEGER :=7;
--CONSTANT end_addrs_s            : INTEGER :=12; CONSTANT end_addrs_e             : INTEGER :=20;CONSTANT end_addrs_WIDTH             : INTEGER :=7;
--CONSTANT incr_decr_s            : INTEGER :=21; CONSTANT incr_decr_e             : INTEGER :=21;CONSTANT incr_decr_WIDTH             : INTEGER :=1;
--CONSTANT incr_decr_value_s      : INTEGER :=22; CONSTANT incr_decr_value_e       : INTEGER :=27;CONSTANT incr_decr_value_WIDTH       : INTEGER :=6;
--CONSTANT initial_delay_s        : INTEGER :=28; CONSTANT initial_delay_e         : INTEGER :=33;CONSTANT initial_delay_WIDTH         : INTEGER :=6;
--CONSTANT outputcontrol_s        : INTEGER :=34; CONSTANT outputcontrol_e         : INTEGER :=34;CONSTANT outputcontrol_WIDTH         : INTEGER :=1;
--CONSTANT instruction_complete_s : INTEGER :=35; CONSTANT instruction_complete_e  : INTEGER :=35;CONSTANT instruction_complete_WIDTH  : INTEGER :=1;
--CONSTANT infinite_loop_s        : INTEGER :=36; CONSTANT infinite_loop_e         : INTEGER :=36;CONSTANT infinite_loop_WIDTH         : INTEGER :=1;
-- 
--CONSTANT repetition_delay_s           : INTEGER :=37; CONSTANT repetition_delay_e            : INTEGER :=45;  CONSTANT repetition_delay_WIDTH            : INTEGER :=9;  --9
--CONSTANT no_of_repetitions_s          : INTEGER :=46; CONSTANT no_of_repetitions_e           : INTEGER :=54;  CONSTANT no_of_repetitions_WIDTH           : INTEGER :=9;  
--CONSTANT repetition_incr_decr_s       : INTEGER :=55; CONSTANT repetition_incr_decr_e        : INTEGER :=55;  CONSTANT repetition_incr_decr_WIDTH        : INTEGER :=1;    --1
--CONSTANT repetition_incr_decr_value_s : INTEGER :=56; CONSTANT repetition_incr_decr_value_e  : INTEGER :=61;  CONSTANT repetition_incr_decr_value_WIDTH  : INTEGER :=6;  --6
--CONSTANT middle_delay_s               : INTEGER :=62; CONSTANT middle_delay_e                : INTEGER :=70;  CONSTANT middle_delay_WIDTH                : INTEGER :=9;
--CONSTANT range_counter_s              : INTEGER :=71; CONSTANT range_counter_e               : INTEGER :=77;  CONSTANT range_counter_WIDTH               : INTEGER :=7;
 
 
 
 END SRAMTile_types_n_constants;


