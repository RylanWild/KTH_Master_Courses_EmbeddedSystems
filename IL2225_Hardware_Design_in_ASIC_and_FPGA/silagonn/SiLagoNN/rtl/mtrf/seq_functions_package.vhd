-------------------------------------------------------
--! @file seq_functions_package.vhd
--! @brief sequencer function package
--! @details 
--! @author sadiq
--! @version 1.0
--! @date 2020-05-26
--! @bug NONE
--! @todo NONE
--! @copyright  GNU Public License [GPL-3.0].
-------------------------------------------------------
---------------- Copyright (c) notice -----------------------------------------
--
-- The VHDL code, the logic and concepts described in this file constitute
-- the intellectual property of the authors listed below, who are affiliated
-- to KTH(Kungliga Tekniska Högskolan), School of ICT, Kista.
-- Any unauthorised use, copy or distribution is strictly prohibited.
-- Any authorised use, copy or distribution should carry this copyright notice
-- unaltered.
-------------------------------------------------------------------------------
-- Title      : sequencer function package
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : seq_functions_package.vhd
-- Author     : sadiq  <sadiq@kth.se>
-- Supervisor : Nasim Farahini
-- Company    : KTH
-- Created    : 2013-07-19
-- Last update: 2020-05-26
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2013
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2013-07-19  1.0      sadiq			        Created
-- 2014-02-25  2.0      Nasim Farahini          Modified
-- 2020-05-26  3.0      Dimitrios Stathis       New functions for loop
-------------------------------------------------------------------------------

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
--                                                                         #
--This file is part of SiLago.                                             #
--                                                                         #
--    SiLago platform source code is distributed freely: you can           #
--    redistribute it and/or modify it under the terms of the GNU          #
--    General Public License as published by the Free Software Foundation, #
--    either version 3 of the License, or (at your option) any             #
--    later version.                                                       #
--                                                                         #
--    SiLago is distributed in the hope that it will be useful,            #
--    but WITHOUT ANY WARRANTY; without even the implied warranty of       #
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
--    GNU General Public License for more details.                         #
--                                                                         #
--    You should have received a copy of the GNU General Public License    #
--    along with SiLago.  If not, see <https://www.gnu.org/licenses/>.     #
--                                                                         #
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
--! Standard ieee and work library
LIBRARY ieee, work;
--! Standard logic package
USE ieee.std_logic_1164.ALL;
--! Standard numeric package for signed and unsigned operations
USE ieee.numeric_std.ALL;
--! Package for the constants and types decelerations
USE work.top_consts_types_package.ALL;
--! Package specifying the testbench instruction
USE work.tb_instructions.ALL;
--! Noc package for type and constants
USE work.noc_types_n_constants.ALL;
USE work.isa_package.ALL;

PACKAGE seq_functions_package IS

----------------------------------new pack functions-----------------------------------------------------------------------------------

    FUNCTION pack_sram_noc_instruction(arg : Sram_instr_type)RETURN NOC_BUS_TYPE;
    FUNCTION pack_route_noc_instruction(arg : Route_instr_type)RETURN NOC_BUS_TYPE;
---------------------------------------------------------------------------------------------------------------------
--    FUNCTION unpack_sram_tb_instruction(arg  : std_logic_vector(size_of_sram_instruction_regs - 1 DOWNTO 0))RETURN sram_instr_type;
--    FUNCTION unpack_route_tb_instruction(arg : std_logic_vector(INSTR_WIDTH - 1 DOWNTO 0))RETURN NOC_BUS_TYPE;

 --   FUNCTION pack_sram_noc_instruction(arg   : sram_instr_type)RETURN NOC_BUS_TYPE;

    ----------------------------------------------------
    -- REV 3 2020-05-26 --------------------------------
    ----------------------------------------------------
    --FUNCTION unpack_for_header_record(arg    : std_logic_vector(INSTR_WIDTH - 1 DOWNTO 0)) RETURN For_header_instr_ty;
    --FUNCTION unpack_for_tail_record(arg      : std_logic_vector(INSTR_WIDTH - 1 DOWNTO 0)) RETURN For_tail_instr_ty;
    FUNCTION unpack_for_basic_record(arg     : std_logic_vector(INSTR_WIDTH - 1 DOWNTO 0)) RETURN For_basic_instr_ty;

    FUNCTION unpack_for_exp_record(arg       : std_logic_vector(INSTR_WIDTH - 1 DOWNTO 0)) RETURN For_exp_instr_ty;
    ----------------------------------------------------
    -- End of modification REV 3 -----------------------
    ----------------------------------------------------
END;

PACKAGE BODY seq_functions_package IS


    ----------------------------------------------------
    -- REV 3 2020-05-26 --------------------------------
    ----------------------------------------------------
    --FUNCTION unpack_for_header_record(arg : std_logic_vector(INSTR_WIDTH - 1 DOWNTO 0)) RETURN For_header_instr_ty IS
    --    VARIABLE result                       : For_header_instr_ty;
    --BEGIN
    --    result.instr_code       := arg(INSTR_CODE_RANGE_BASE DOWNTO INSTR_CODE_RANGE_END);
    --    result.index_raccu_addr := arg(FOR_INDEX_ADDR_RANGE_BASE DOWNTO FOR_INDEX_ADDR_RANGE_END);
    --    result.index_start      := arg(FOR_INDEX_START_RANGE_BASE DOWNTO FOR_INDEX_START_RANGE_END);
    --    result.iter_no_sd       := arg(FOR_INDEX_START_RANGE_END - 1);
    --    result.iter_no          := arg(FOR_ITER_NO_RANGE_BASE DOWNTO FOR_ITER_NO_RANGE_END);
    --    result.header_unused    := arg(FOR_HEADER_UNUSED_RANGE_BASE DOWNTO FOR_HEADER_UNUSED_RANGE_END);
    --    RETURN result;
    --END;
    --
    --FUNCTION unpack_for_tail_record(arg : std_logic_vector(INSTR_WIDTH - 1 DOWNTO 0)) RETURN For_tail_instr_ty IS
    --    VARIABLE result                     : For_tail_instr_ty;
    --BEGIN
    --    result.instr_code       := arg(INSTR_CODE_RANGE_BASE DOWNTO INSTR_CODE_RANGE_END);
    --    result.index_step       := arg(FOR_INDEX_STEP_RANGE_BASE DOWNTO FOR_INDEX_STEP_RANGE_END);
    --    result.pc_togo          := arg(FOR_PC_TOGO_RANGE_BASE DOWNTO FOR_PC_TOGO_RANGE_END);
    --    result.index_raccu_addr := arg(FOR_TAIL_INDEX_ADDR_RANGE_BASE DOWNTO FOR_TAIL_INDEX_ADDR_RANGE_END);
    --    result.tail_unused      := arg(FOR_TAIL_UNUSED_RANGE_BASE DOWNTO FOR_TAIL_UNUSED_RANGE_END);
    --    RETURN result;
    --END;
    FUNCTION unpack_for_basic_record(arg : std_logic_vector(INSTR_WIDTH - 1 DOWNTO 0)) RETURN For_basic_instr_ty IS
        VARIABLE result                      : For_basic_instr_ty;
    BEGIN
        result.instr_code := arg(INSTR_CODE_RANGE_BASE DOWNTO INSTR_CODE_RANGE_END);
        result.extend     := arg(FOR_LOOP_EXTENDED_BIT);
        result.loop_id    := unsigned(arg(FOR_LOOP_ID_BASE DOWNTO FOR_LOOP_ID_END));
        result.end_pc     := unsigned(arg(FOR_LOOP_END_PC_BASE DOWNTO FOR_LOOP_END_PC_END));
        result.start_sd   := arg(FOR_LOOP_START_SD_BIT);
        result.start      := signed(arg(FOR_LOOP_START_BASE DOWNTO FOR_LOOP_START_END));
        result.iter_sd    := arg(FOR_LOOP_ITER_SD_BIT);
        result.iter       := unsigned(arg(FOR_LOOP_ITER_BASE DOWNTO FOR_LOOP_ITER_END));
        RETURN result;
    END;

    FUNCTION unpack_for_exp_record(arg : std_logic_vector(INSTR_WIDTH - 1 DOWNTO 0)) RETURN For_exp_instr_ty IS
        VARIABLE result                    : For_exp_instr_ty;
    BEGIN
        result.step_sd       := arg(FOR_LOOP_STEP_SD_BIT);
        result.step          := signed(arg(FOR_LOOP_STEP_BASE DOWNTO FOR_LOOP_STEP_END));
        result.related_loops := arg(FOR_LOOP_RELATED_LOOPS_BASE DOWNTO FOR_LOOP_RELATED_LOOPS_END);
        result.unused        := arg(FOR_LOOP_EX_UNUSED_BASE DOWNTO FOR_LOOP_EX_UNUSED_END);
        RETURN result;
    END;
    ----------------------------------------------------
    -- End of modification REV 3 -----------------------
    ----------------------------------------------------
    FUNCTION pack_route_noc_instruction(arg : Route_instr_type)RETURN NOC_BUS_TYPE IS
        VARIABLE result                        : NOC_BUS_TYPE;
    BEGIN
        result.instr_code := both_instruction;
        result.bus_enable := '1';
	result.INSTRUCTION := (OTHERS => '0');
        result.INSTRUCTION(DRH_dir_l)                          := arg.vertical_dir;
        result.INSTRUCTION(DCH_dir_l)                          := arg.horizontal_dir;
        result.INSTRUCTION(SRH_e DOWNTO SRH_s)                 := STD_LOGIC_VECTOR(TO_UNSIGNED(0, SRH_e - SRH_s + 1));
        result.INSTRUCTION(SCH_e DOWNTO SCH_s)                 := STD_LOGIC_VECTOR(TO_UNSIGNED(0, SCH_e - SCH_s + 1));
        result.INSTRUCTION(DRH_e DOWNTO DRH_s)                 := arg.vertical_hops;
        result.INSTRUCTION(DCH_e DOWNTO DCH_s)                 := arg.horizontal_hops;
        result.INSTRUCTION(ON_l)                               := not (arg.direction);
        result.INSTRUCTION(RF_e)                               := '0';
        result.INSTRUCTION(RF_s)                               := arg.select_drra_row;
        result.INSTRUCTION(UNION_FLAG_l)                       := '0';
        result.INSTRUCTION(UNION_PORT_e DOWNTO UNION_PORT_s)   := STD_LOGIC_VECTOR(TO_UNSIGNED(0, UNION_PORT_e - UNION_PORT_s + 1));
        result.INSTRUCTION(READ_WRITE_l)                       := arg.direction;
        RETURN result;
    END;

    FUNCTION pack_sram_noc_instruction(arg : Sram_instr_type)RETURN NOC_BUS_TYPE IS
        VARIABLE result                        : NOC_BUS_TYPE;
    BEGIN 
        result.INSTRUCTION(NoC_Bus_instr_width - sr_en_s DOWNTO NoC_Bus_instr_width - sr_en_e)                           := "1";
        result.INSTRUCTION(NoC_Bus_instr_width - sr_mode_s DOWNTO NoC_Bus_instr_width - sr_mode_e)                       := "0";
        result.INSTRUCTION(NoC_Bus_instr_width - sr_hops_s DOWNTO NoC_Bus_instr_width - sr_hops_e)                       := arg.hops;
        result.INSTRUCTION(NoC_Bus_instr_width - sr_initial_address_s DOWNTO NoC_Bus_instr_width - sr_initial_address_e) := arg.init_addr;
        result.INSTRUCTION(NoC_Bus_instr_width - sr_initial_delay_s DOWNTO NoC_Bus_instr_width - sr_initial_delay_e)     := arg.init_delay;
        result.INSTRUCTION(NoC_Bus_instr_width - sr_loop1_iteration_s DOWNTO NoC_Bus_instr_width - sr_loop1_iteration_e) := arg.l1_iter;
        result.INSTRUCTION(NoC_Bus_instr_width - sr_loop1_increment_s DOWNTO NoC_Bus_instr_width - sr_loop1_increment_e) := arg.l1_step;
        result.INSTRUCTION(NoC_Bus_instr_width - sr_loop1_delay_s DOWNTO NoC_Bus_instr_width - sr_loop1_delay_e)         := arg.l1_delay;
        result.INSTRUCTION(NoC_Bus_instr_width - sr_loop2_iteration_s DOWNTO NoC_Bus_instr_width - sr_loop2_iteration_e) := arg.l2_iter;
        result.INSTRUCTION(NoC_Bus_instr_width - sr_loop2_increment_s DOWNTO NoC_Bus_instr_width - sr_loop2_increment_e) := arg.l2_step;
        result.INSTRUCTION(NoC_Bus_instr_width - sr_loop2_delay_s DOWNTO NoC_Bus_instr_width - sr_loop2_delay_e)         := arg.l2_delay;
        result.INSTRUCTION(NoC_Bus_instr_width - sr_rw)                                                                  := arg.rw;
        result.instr_code := AGU_instruction;
        result.bus_enable := '1';
        RETURN result;
    END;
END;
