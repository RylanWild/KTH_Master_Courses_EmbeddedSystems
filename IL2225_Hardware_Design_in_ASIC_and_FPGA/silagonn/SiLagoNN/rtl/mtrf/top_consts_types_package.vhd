-------------------------------------------------------
--! @file
--! @brief Top Constant Package for the DRRA fabric.
--! @details
--! @author Sadiq Hemani , Hojat Khoshrowjerdi, Jingying Dong, Nasim Farahini, Hassan Sohofi, Dimitrios Stathis
--! @version 5.1
--! @date 2019-17-10
--! @bug NONE
--! @todo Fix the REFI instructions, clean un-needed fields, remove the instruction code for REFI2 and REFI3.
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
-- Title      : top_consts_types_package
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : top_consts_types_package.vhd
-- Author     : Sadiq Hemani <sadiq@kth.se>, Hojat Khoshrowjerdi <hojatk@kth.se>, Jingying Dong <jdon@kth.se>
-- Company    : KTH
-- Created    : 2013-09-05
-- Last update: 2021-09-06
-- Platform   : SiLago
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: To be included in all MTRF components and the top module. Includes
-- all the required constants and type declarations for the Sequencer, DPU and
-- Register file (with AGUs). The sequencer constants
-- have been declared in a parametric style to facilitate any future instruction
-- format changes.
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author               Description
-- 2013-09-05  1.0      sadiq                Created
-- 2014-02-25  2.0      Nasim Farahini       Modified
-- 2014-05-10  3.0      Nasim Farahini       Raccu and loop instructions are added
-- 2015-02-22  4.0      Hassan Sohofi        Updating branch and jump instructions
-- 2019-03-10  4.1      Dimitrios Stathis    Included the new misc package.
-- 2020-02-18  5.0      Dimitrios stathis    Change from loop-head/loop-tail
--                                           instructions to the new instructions
--                                           for use with the new auto-loop unit.
--                                           SRAM instructions combined to one. 
-- 2020-02-21  5.1      Dimitrios Stathis    Remove REFI 2 and REFI 3 from the instruction list
--                                           They are now treated as extensions of REFI 1
-- 2020-05-05  5.2      Dimitrios Stathis    Added new RACCU modes to align with loop accelerator
-- 2021-08-18  6.0      Dimitrios Stathis    New reconfiguration for the word
--                                           bitwidth (16-8-4)
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
-------------------------------------------------------------------------------

--! IEEE standard library.
LIBRARY ieee;
--! Use standard library.
USE ieee.std_logic_1164.ALL;
--! Use numeric library.
USE ieee.numeric_std.ALL;
--! Import and use the new miscellaneous package.
USE work.misc.ALL;
--! Import and use the hw setting package.
USE work.hw_setting.ALL;

--! \page Top_consts_types_package_page Top package for constants and types for the DRRA fabric
--! \tableofcontents
--! This page contains the detail description for the top_consts_types_package. The package
--! contains a number of constants, types and records that are used in the DRRA fabric. We 
--! split and group the details of the package according to where they are used.
--! \section top_seq Sequencer
--! In this section we detail and link the constants and types that are used in the
--! sequencer, auto-loop and RACCU. 
--! \subsection top_seq_instr Instructions
--! The instructions that are supported by the sequencer are presented in table \ref instruction_tbl [Instruction list].
--! Definitions for the instruction constants and types, along with more details about the individual instructions, can be find in \ref Instructions.
--! <table>
--! <caption id="instruction_tbl">Instruction list</caption>
--! <tr><th>Instruction       <th>Instruction Code   <th> Details (see)              <th> Decoding Functions
--! <tr><td>   HALT           <td> "0000"            <td> \subpage HALTInstruction   <td> NONE
--! <tr><td>   REFI1          <td> "0001"            <td> \ref REFI                  <td> \ref REFI_Functions
--! <tr><td>   REFI2          <td> "0010"            <td> \ref REFI                  <td> \ref REFI_Functions
--! <tr><td>   REFI3          <td> "0011"            <td> \ref REFI                  <td> \ref REFI_Functions
--! <tr><td>   DPU            <td> "0100"            <td> \ref DPU_instruction       <td> \ref DPU_Functions
--! <tr><td>   SWB            <td> "0101"            <td> \ref SWB_instruction       <td> \ref None
--! <tr><td>   JUMP           <td> "0110"            <td> \ref JUMP_instruction      <td> \ref JUMP_Functions
--! <tr><td>   DELAY          <td> "0111"            <td> \ref DLY_instruction       <td> \ref DLY_Functions
--! <tr><td>   FOR_HEADER     <td> "1000"            <td> \ref FOR_instruction       <td> \ref FOR_Functions
--! <tr><td>   UNUSED_9       <td> "1001"            <td> Unused instruction code    <td> NA
--! <tr><td>   RACCU          <td> "1010"            <td> \ref RACCU_instruction     <td> \ref RACCU_Functions
--! <tr><td>   BRANCH         <td> "1011"            <td> \ref BR_instruction        <td> \ref BR_Functions
--! <tr><td>   ROUTE          <td> "1100"            <td> TODO                       <td> \ref ROUTE_Functions
--! <tr><td>   SRAM           <td> "1101"            <td> \ref SRAM_instruction      <td> \ref SRAM_Functions
--! <tr><td>   UNUSED_14      <td> "1110"            <td> Unused instruction code    <td> NA
--! <tr><td>   UNUSED_15      <td> "1111"            <td> Unused instruction code    <td> NA
--! </table>
--! 

--! \page HALTInstruction Halt Instruction
--! This page describes the Halt Instruction.
--! \section Con_n_Types Constants and Types
--! The Halt Instruction does not require any special types or constants.
--! \section Functionality
--! When the sequencer encounters the Halt instruction code "0000", it stops the
--! increment of the PC. The Halt Instruction is always an immediate instruction.

--! @brief Top Constant Package for the DRRA fabric.
--! @details This package contain the basic constants
--! and type definitions for the DRRA fabric.
PACKAGE top_consts_types_package IS

  --<GLOBAL CONSTANTS BEGIN>--
  CONSTANT BITWIDTH                              : NATURAL                                          := HW_BITWIDTH;       --! h_bus bitwidth

  --! \addtogroup Instructions
  --! @{
  CONSTANT INSTR_WIDTH                           : NATURAL                                          := HW_INSTR_WIDTH;    --! Instruction bitwidth
  CONSTANT INSTR_DEPTH                           : NATURAL                                          := HW_INSTR_DEPTH;    --! Instruction memory depth (number of instruction words)
  --! @}
  --<GLOBAL CONSTANTS END>--

  --<GLOBAL CONSTANTS END>--

  --<GLOBAL TYPES BEGIN>--
  --<GLOBAL TYPES END>--

  --<SEQUENCER CONSTANTS BEGIN>--

  CONSTANT SEQ_ADDRS_WIDTH                       : NATURAL                                          := log2(INSTR_DEPTH); --! Bits used to address the sequencer memory
  CONSTANT SEQ_ADDRS                             : STD_LOGIC_VECTOR(SEQ_ADDRS_WIDTH - 1 DOWNTO 0)   := (OTHERS => '0');   --! 1st address of the sequencer
  -- for testing purposes
  CONSTANT PC_SIZE                               : NATURAL                                          := log2(INSTR_DEPTH);
  CONSTANT INSTR_REG_DEPTH                       : NATURAL                                          := log2(INSTR_DEPTH);
  CONSTANT PC_BASE_PROG                          : NATURAL                                          := 0;               -- base pc value, where PC is "pc <= PC + 1" Set to pc as default in the sequencer
  CONSTANT PC_INCREM_WIDTH                       : NATURAL                                          := 2;               --
  --width of the PC_INCREM signal

  CONSTANT INCREMENT_OPTS                        : NATURAL                                          := 1;               -- Should be ceil2(log2(nr_of_increment_options)). In this case we have 2 options
  CONSTANT NR_OF_OUTPORTS                        : NATURAL                                          := 1;               -- should be ceil2(log2(nr_of_outports)). In this case we have 2 outports

  --<SEQUENCER SAMPLE INSTRUCTION TYPE CONSTANTS>--
  CONSTANT INCREMENT_RANGE_BASE                  : NATURAL                                          := INSTR_WIDTH - 1; -- start of range declaration for the increment portion of the instruction
  CONSTANT INCREMENT_RANGE_END                   : NATURAL                                          := INCREMENT_RANGE_BASE - (INCREMENT_OPTS - 1);
  CONSTANT INCREMENT_VECTOR_SIZE                 : NATURAL                                          := INCREMENT_RANGE_BASE - INCREMENT_RANGE_END;
  CONSTANT OUTPORT_RANGE_BASE                    : NATURAL                                          := INCREMENT_RANGE_END - 1;
  CONSTANT OUTPORT_RANGE_END                     : NATURAL                                          := OUTPORT_RANGE_BASE - (NR_OF_OUTPORTS - 1);
  CONSTANT OUTPORT_VECTOR_SIZE                   : NATURAL                                          := OUTPORT_RANGE_BASE - OUTPORT_RANGE_END;
  CONSTANT JUMP_INSTR_ADDRESS_BASE               : NATURAL                                          := OUTPORT_RANGE_END - 1;
  CONSTANT JUMP_INSTR_ADDRESS_END                : NATURAL                                          := JUMP_INSTR_ADDRESS_BASE - (PC_SIZE - 1); -- changed PC_SIZE - 1 ==> PC_SIZE
  CONSTANT JUMP_INSTR_ADDRESS_VECTOR_SIZE        : NATURAL                                          := JUMP_INSTR_ADDRESS_BASE - JUMP_INSTR_ADDRESS_END;
  CONSTANT VACANT_BITS_BASE                      : NATURAL                                          := JUMP_INSTR_ADDRESS_END - 1;
  CONSTANT VACANT_BITS_END                       : NATURAL                                          := 0;
  CONSTANT VACANT_BITS_VECTOR_SIZE               : NATURAL                                          := VACANT_BITS_BASE - VACANT_BITS_END;
  CONSTANT VACANT_BITS_REMAIN                    : NATURAL                                          := INSTR_WIDTH - ((INCREMENT_VECTOR_SIZE + 1) + (OUTPORT_VECTOR_SIZE + 1) + (JUMP_INSTR_ADDRESS_VECTOR_SIZE + 1));

  --<RACCU and Loop management CONSTANTS BEGIN>
  --! \defgroup RACCU
  --! @{
  --! \brief
  --! \details
  --! \defgroup Constants
  --! \brief
  --! \details
  --! @{
  --RACCU modes functions
  CONSTANT RAC_MODE_IDLE                         : INTEGER                                          := 0;                         --! Idle RACCU
  ----------------------------------------------------
  -- REV 5.2 2020-05-05 ------------------------------
  ----------------------------------------------------
  -- CONSTANT RAC_MODE_ADD_WITH_LOOP_INDEX          : INTEGER                                          := 7;
  -- CONSTANT RAC_MODE_LOOP_HEADER                  : INTEGER                                          := 1;
  -- CONSTANT RAC_MODE_LOOP_TAIL                    : INTEGER                                          := 2;
  ----------------------------------------------------
  -- End of modification REV 5.2 ---------------------
  ----------------------------------------------------
  CONSTANT RAC_MODE_ADD                          : INTEGER                                          := 1;                         --! Add of two signed values 
  CONSTANT RAC_MODE_SUB                          : INTEGER                                          := 2;                         --! Sub of two signed values
  CONSTANT RAC_MODE_SHFT_R                       : INTEGER                                          := 3;                         --! Left shift 
  CONSTANT RAC_MODE_SHFT_L                       : INTEGER                                          := 4;                         --! Right shift
  CONSTANT RAC_MODE_ADD_SH_L                     : INTEGER                                          := 5;                         --! Shift left and add with the value of the output register (a = b << c + a)
  CONSTANT RAC_MODE_SUB_SH_L                     : INTEGER                                          := 6;                         --! Shift left and subtract with the value of the output register (a = b << c - a)

  CONSTANT RACCU_REG_BITWIDTH                    : NATURAL                                          := HW_RACCU_REG_BITWIDTH;     --! RACCU register bitwidth - To be able to access memory addresses 7

  CONSTANT MAX_NO_OF_LOOPS                       : NATURAL                                          := HW_MAX_NO_OF_RACCU_LOOPS;  --! Number of Loops that can be supported
  CONSTANT RACCU_REGFILE_DEPTH                   : NATURAL                                          := HW_RACCU_REGFILE_DEPTH;    --! Number of RACCU Registers, includes the Registers used for the Loop iterators
  CONSTANT RACCU_REG_ADDRS_WIDTH                 : NATURAL                                          := log2(RACCU_REGFILE_DEPTH); --! Address width for the RACCU register file
  --! @}
  --! @}
  --<RACCU CONSTANTS END>--

  --<GENERAL INSTRUCTION TYPE CONSTANTS>--
  --! \defgroup Instructions
  --! @{
  --! \brief Constants definitions for the instruction codes.
  --! \details For further info see \ref top_seq_instr.
  CONSTANT NR_OF_INSTR_TYPES                     : NATURAL                                          := 4;

  CONSTANT HALT                                  : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "0000";                                                               --! Halt instruction, used 0.
  CONSTANT REFI                                  : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "0001";                                                               --! Instruction code REFI1, used 1.
  ----------------------------------------------------
  -- REV 5.1 2020-02-21 ------------------------------
  ----------------------------------------------------
  CONSTANT UNUSED_2                              : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "0010";                                                               --! Instruction code REFI2, used 2.
  CONSTANT UNUSED_3                              : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "0011";                                                               --! Instruction code REFI3, used 3.
  ----------------------------------------------------
  -- End of modification REV 5.1 ---------------------
  ----------------------------------------------------
  CONSTANT DPU                                   : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "0100";                                                               --! Instruction code DPU, used 4.
  CONSTANT SWB                                   : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "0101";                                                               --! Instruction code SWB, used 5.
  CONSTANT JUMP                                  : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "0110";                                                               --! Instruction code JUMP, used 6.
  CONSTANT DELAY                                 : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "0111";                                                               --! Instruction code DELAY, used 7.
  CONSTANT FOR_LOOP                              : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "1000";                                                               --! Instruction code used for the new FOR-BASIC instruction [previously FOR_HEADER], used 8.
  CONSTANT BW_CONFIG                             : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "1001";                                                               --! Configuration of the arithmetic operation BW
  CONSTANT RACCU                                 : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "1010";                                                               --! Instruction code RACCU, used 10.
  CONSTANT BRANCH                                : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "1011";                                                               --! Instruction code BRANCH, used 11.
  CONSTANT ROUTE                                 : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "1100";                                                               --! Instruction code ROUTE, used 12.
  -----------------------------------------------------------------------------------
  -- MODIFICATION:                                             [2019-10-18]        --
  -- Begin : Combine the SRAM instructions to one to release an instruction code   --
  -- the SRAM instructions in the sequencer were already treated as the same.      --
  -----------------------------------------------------------------------------------
  -- ORIGINAL CODE :
  CONSTANT READ_SRAM                             : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "1101";                                                               --! Instruction code READ_SRAM, used 13
  CONSTANT WRITE_SRAM                            : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "1110";                                                               --! Instruction code WRITE_SRAM,    used 14
  -----------------------------------------------------------------------------------
  -- MODIFIED CODE: 
  -------------------
  --CONSTANT SRAM                                  : std_logic_vector(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "1101";                                                               --! Instruction code SRAM, used 13.
  --CONSTANT UNUSED_14                             : std_logic_vector(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "1110";                                                               --! Unused instruction code, unused 14.
  -----------------------------------------------------------------------------------
  CONSTANT UNUSED_15                             : STD_LOGIC_VECTOR(NR_OF_INSTR_TYPES - 1 DOWNTO 0) := "1111";                                                               --! Unused instruction code, unused 15.
  -----------------------------------------------------------------------------------
  CONSTANT INSTR_CODE_RANGE_BASE                 : NATURAL                                          := INSTR_WIDTH - 1;                                                      --! All instructions start with the instruction code.
  CONSTANT INSTR_CODE_RANGE_END                  : NATURAL                                          := INSTR_CODE_RANGE_BASE - (NR_OF_INSTR_TYPES - 1);                      --! Bit number, where the instruction code bit ends.
  CONSTANT INSTR_CODE_RANGE_VECTOR_SIZE          : NATURAL                                          := INSTR_CODE_RANGE_BASE - INSTR_CODE_RANGE_END + 1;                     --! Size of the instruction code.
  --! @}

  --<REFI1 INSTRUCTION TYPE CONSTANTS>--
  --<REFI1 INSTRUCTION TYPE CONSTANTS>--
  --! \addtogroup Instructions
  --! @{
  --! \defgroup REFI
  --! \brief Register file instruction [REFI].
  --! \details This instruction is used to configure the address generation units (AGUs) that are linked with the read
  --! and write ports of the register file (RF). Due to the amount of information needed to configure the AGUs, the 
  --! REFI instruction is sliced to three sub-instructions, aka REFI1, REFI2 \& REFI3.
  --! @{
  --! \defgroup REFI1
  --! @{
  --! \brief Definitions and declarations of types and constants for the REFI1 instruction.
  --! \details REFI1 is the basic configuration instruction for the register file (RF) address
  --! generation units (AGU). It specifies the starting address of the pattern, the number of address
  --! to be generated and the initial delay -clock cycles that the AGU will remain idle before it
  --! start generating the stream of addresses. 
  CONSTANT NR_OF_REG_FILE_PORTS                  : NATURAL                                          := 2;                                                                    --! # of bits used to specify the  register port to be configured.
  CONSTANT NR_OF_INSTRS                          : NATURAL                                          := 2;                                                                    --! # of bits used to specify the number of REFI instructions following this one, to extend it .
  CONSTANT STARTING_ADDRS                        : NATURAL                                          := 6;                                                                    --! # of bits used to specify the starting address of the pattern.
  CONSTANT NR_OF_ADDRS                           : NATURAL                                          := 6;                                                                    --! # of bits used to specify the number of addresses. 
  ---------------------------------------------------
  -- REV 10 2022-03-04 ------------------------------
  ---------------------------------------------------
  CONSTANT INIT_DELAY                            : NATURAL                                          := 6;                                                                    --! # of bits used to specify the initial delay.

  CONSTANT NR_OF_REG_FILE_PORTS_RANGE_BASE       : NATURAL                                          := INSTR_CODE_RANGE_END - 1;                                             --! Starting bit of the \em NR_OF_REG_FILE_PORTS field.
  CONSTANT NR_OF_REG_FILE_PORTS_RANGE_END        : NATURAL                                          := NR_OF_REG_FILE_PORTS_RANGE_BASE - (NR_OF_REG_FILE_PORTS - 1);         --! Ending bit of the \em NR_OF_REG_FILE_PORTS field.
  CONSTANT NR_OF_REG_FILE_PORTS_VECTOR_SIZE      : NATURAL                                          := NR_OF_REG_FILE_PORTS_RANGE_BASE - NR_OF_REG_FILE_PORTS_RANGE_END + 1; --! # of bits in the \em NR_OF_REG_FILE_PORTS field.
  CONSTANT NR_OF_INSTRS_RANGE_BASE               : NATURAL                                          := NR_OF_REG_FILE_PORTS_RANGE_END - 1;                                   --! Starting bit of the \em NR_OF_INSTRS field.
  CONSTANT NR_OF_INSTRS_RANGE_END                : NATURAL                                          := NR_OF_INSTRS_RANGE_BASE - (NR_OF_INSTRS - 1);                         --! Ending bit of the \em NR_OF_INSTRS field.
  CONSTANT NR_OF_INSTRS_VECTOR_SIZE              : NATURAL                                          := NR_OF_INSTRS_RANGE_BASE - NR_OF_INSTRS_RANGE_END + 1;                 --! # of bits in the \em NR_OF_INSTRS field.
  CONSTANT STARTING_ADDRS_RANGE_BASE             : NATURAL                                          := NR_OF_INSTRS_RANGE_END - 2;                                           --! Starting bit of the \em STARTING_ADDRS field. (note: 1 bit right before this field is used to define if the starting address is static or dynamic)
  CONSTANT STARTING_ADDRS_RANGE_END              : NATURAL                                          := STARTING_ADDRS_RANGE_BASE - (STARTING_ADDRS - 1);                     --! Ending bit of the \em STARTING_ADDRS field.
  CONSTANT STARTING_ADDRS_VECTOR_SIZE            : NATURAL                                          := STARTING_ADDRS_RANGE_BASE - STARTING_ADDRS_RANGE_END + 1;             --! # of bits in the \em STARTING_ADDRS field.
  CONSTANT NR_OF_ADDRS_RANGE_BASE                : NATURAL                                          := STARTING_ADDRS_RANGE_END - 1;                                         --! Starting bit of the \em NR_OF_ADDRS field.
  CONSTANT NR_OF_ADDRS_RANGE_END                 : NATURAL                                          := NR_OF_ADDRS_RANGE_BASE - (NR_OF_ADDRS - 1);                           --! Ending bit of the \em NR_OF_ADDRS field.
  CONSTANT NR_OF_ADDRS_VECTOR_SIZE               : NATURAL                                          := NR_OF_ADDRS_RANGE_BASE - NR_OF_ADDRS_RANGE_END + 1;                   --! # of bits in the \em NR_OF_ADDRS field.
  CONSTANT INIT_DELAY_RANGE_BASE                 : NATURAL                                          := NR_OF_ADDRS_RANGE_END - 1;                                            --! Starting bit of the \em INIT_DELAY field.
  CONSTANT INIT_DELAY_RANGE_END                  : NATURAL                                          := INIT_DELAY_RANGE_BASE - (INIT_DELAY - 1);                             --! Ending bit of the \em INIT_DELAY field.
  CONSTANT INIT_DELAY_VECTOR_SIZE                : NATURAL                                          := INIT_DELAY_RANGE_BASE - INIT_DELAY_RANGE_END + 1;                     --! # of bits in the \em INIT_DELAY field.

  --! @}
  --! @}
  --! @}
  ----------------------------------------------------
  -- End of modification REV 10 ----------------------
  ----------------------------------------------------

  --<REFI2 INSTRUCTION TYPE CONSTANTS>--
  --! \addtogroup Instructions
  --! @{
  --! \addtogroup REFI
  --! @{
  --! \defgroup REFI2
  --! @{
  --! \brief Definitions and declarations of types and constants for the REFI2 instruction.
  --! \details REFI2 is used to extent the basic configuration instruction (REFI1 \ref REFI1) for the register file (RF) address
  --! generation units (AGU). It specifies the step value of the pattern and its sign, the delay between the generated addresses,
  --! the number of repetitions -i.e. how many times this pattern should be generated and the step value between repetitions
  --! -i.e. the offset of the starting address.
  CONSTANT STEP_VALUE                            : NATURAL                                          := 6;
  CONSTANT STEP_VALUE_SIGN                       : NATURAL                                          := 1;
  CONSTANT REG_FILE_MIDDLE_DELAY                 : NATURAL                                          := 4;
  CONSTANT NUM_OF_REPT                           : NATURAL                                          := 5;
  CONSTANT REP_STEP_VALUE                        : NATURAL                                          := 4;
  CONSTANT STEP_VALUE_RANGE_BASE                 : NATURAL                                          := INSTR_CODE_RANGE_END - 2;
  CONSTANT STEP_VALUE_RANGE_END                  : NATURAL                                          := STEP_VALUE_RANGE_BASE - (STEP_VALUE - 1);
  CONSTANT STEP_VALUE_VECTOR_SIZE                : NATURAL                                          := STEP_VALUE_RANGE_BASE - STEP_VALUE_RANGE_END + 1;
  CONSTANT STEP_VALUE_SIGN_RANGE_BASE            : NATURAL                                          := STEP_VALUE_RANGE_END - 1;
  CONSTANT STEP_VALUE_SIGN_RANGE_END             : NATURAL                                          := STEP_VALUE_SIGN_RANGE_BASE - (STEP_VALUE_SIGN - 1);
  CONSTANT STEP_VALUE_SIGN_VECTOR_SIZE           : NATURAL                                          := STEP_VALUE_SIGN_RANGE_BASE - STEP_VALUE_SIGN_RANGE_END + 1;
  CONSTANT REG_FILE_MIDDLE_DELAY_RANGE_BASE      : NATURAL                                          := STEP_VALUE_SIGN_RANGE_END - 2;
  CONSTANT REG_FILE_MIDDLE_DELAY_RANGE_END       : NATURAL                                          := REG_FILE_MIDDLE_DELAY_RANGE_BASE - (REG_FILE_MIDDLE_DELAY - 1);
  CONSTANT REG_FILE_MIDDLE_DELAY_VECTOR_SIZE     : NATURAL                                          := REG_FILE_MIDDLE_DELAY_RANGE_BASE - REG_FILE_MIDDLE_DELAY_RANGE_END + 1;
  CONSTANT NUM_OF_REPT_RANGE_BASE                : NATURAL                                          := REG_FILE_MIDDLE_DELAY_RANGE_END - 2;
  CONSTANT NUM_OF_REPT_RANGE_END                 : NATURAL                                          := NUM_OF_REPT_RANGE_BASE - (NUM_OF_REPT - 1);
  CONSTANT NUM_OF_REPT_VECTOR_SIZE               : NATURAL                                          := NUM_OF_REPT_RANGE_BASE - NUM_OF_REPT_RANGE_END + 1;
  CONSTANT REP_STEP_VALUE_RANGE_BASE             : NATURAL                                          := NUM_OF_REPT_RANGE_END - 1;
  CONSTANT REP_STEP_VALUE_RANGE_END              : NATURAL                                          := REP_STEP_VALUE_RANGE_BASE - (REP_STEP_VALUE - 1);
  CONSTANT REP_STEP_VALUE_VECTOR_SIZE            : NATURAL                                          := REP_STEP_VALUE_RANGE_BASE - REP_STEP_VALUE_RANGE_END + 1;
  --! @}
  --! @}
  --! @}

  --<REFI3 INSTRUCTION TYPE CONSTANTS>--
  --! \addtogroup Instructions
  --! @{
  --! \addtogroup REFI
  --! @{
  --! \defgroup REFI3
  --! @{
  --! \brief Definitions and declarations of types and constants for the REFI3 instruction.
  --! \details REFI3 is used to extent the basic configuration instruction (REFI1 \ref REFI1) for the register file (RF) address
  --! generation units (AGU). It specifies the delay between the iterations of the outer loop, extends the delay specified by by REFI2,
  --! extends the number of repetitions specified by REFI2, extends the step value specified by REFI2. It can also be used to specify the 
  --! use of compression or special patters like FFT's bit-reverse. 
  CONSTANT REPT_DELAY                            : NATURAL                                          := 6;
  CONSTANT MODE_SEL                              : NATURAL                                          := 1;
  CONSTANT OUTPUT_CONTROL                        : NATURAL                                          := 2;
  CONSTANT FFT_STAGE_SEL                         : NATURAL                                          := 3;
  CONSTANT REG_FILE_MIDDLE_DELAY_EXT             : NATURAL                                          := 2;
  CONSTANT NUM_OF_REPT_EXT                       : NATURAL                                          := 1;
  CONSTANT REP_STEP_VALUE_EXT                    : NATURAL                                          := 2;
  CONSTANT FFT_END_STAGE                         : NATURAL                                          := 3;
  CONSTANT USE_COMPR                             : NATURAL                                          := 1; -- changed from 2 to 1 for sram_interface
  CONSTANT REPT_DELAY_RANGE_BASE                 : NATURAL                                          := INSTR_CODE_RANGE_END - 2;
  CONSTANT REPT_DELAY_RANGE_END                  : NATURAL                                          := REPT_DELAY_RANGE_BASE - (REPT_DELAY - 1);
  CONSTANT REPT_DELAY_VECTOR_SIZE                : NATURAL                                          := REPT_DELAY_RANGE_BASE - REPT_DELAY_RANGE_END + 1;
  CONSTANT MODE_SEL_RANGE_BASE                   : NATURAL                                          := REPT_DELAY_RANGE_END - 1;
  CONSTANT MODE_SEL_RANGE_END                    : NATURAL                                          := MODE_SEL_RANGE_BASE - (MODE_SEL - 1);
  CONSTANT MODE_SEL_VECTOR_SIZE                  : NATURAL                                          := MODE_SEL_RANGE_BASE - MODE_SEL_RANGE_END + 1;
  CONSTANT OUTPUT_CONTROL_RANGE_BASE             : NATURAL                                          := MODE_SEL_RANGE_END - 1;
  CONSTANT OUTPUT_CONTROL_RANGE_END              : NATURAL                                          := OUTPUT_CONTROL_RANGE_BASE - (OUTPUT_CONTROL - 1);
  CONSTANT OUTPUT_CONTROL_VECTOR_SIZE            : NATURAL                                          := OUTPUT_CONTROL_RANGE_BASE - OUTPUT_CONTROL_RANGE_END + 1;
  CONSTANT FFT_STAGE_SEL_RANGE_BASE              : NATURAL                                          := OUTPUT_CONTROL_RANGE_END - 1;
  CONSTANT FFT_STAGE_SEL_RANGE_END               : NATURAL                                          := FFT_STAGE_SEL_RANGE_BASE - (FFT_STAGE_SEL - 1);
  CONSTANT FFT_STAGE_SEL_VECTOR_SIZE             : NATURAL                                          := FFT_STAGE_SEL_RANGE_BASE - FFT_STAGE_SEL_RANGE_END + 1;
  CONSTANT REG_FILE_MIDDLE_DELAY_EXT_RANGE_BASE  : NATURAL                                          := FFT_STAGE_SEL_RANGE_END - 1;
  CONSTANT REG_FILE_MIDDLE_DELAY_EXT_RANGE_END   : NATURAL                                          := REG_FILE_MIDDLE_DELAY_EXT_RANGE_BASE - (REG_FILE_MIDDLE_DELAY_EXT - 1);
  CONSTANT REG_FILE_MIDDLE_DELAY_EXT_VECTOR_SIZE : NATURAL                                          := REG_FILE_MIDDLE_DELAY_EXT_RANGE_BASE - REG_FILE_MIDDLE_DELAY_EXT_RANGE_END + 1;
  CONSTANT REG_FILE_MIDDLE_DELAY_PORT_SIZE       : NATURAL                                          := REG_FILE_MIDDLE_DELAY_VECTOR_SIZE + REG_FILE_MIDDLE_DELAY_EXT_VECTOR_SIZE;
  CONSTANT NUM_OF_REPT_EXT_RANGE_BASE            : NATURAL                                          := REG_FILE_MIDDLE_DELAY_EXT_RANGE_END - 1;
  CONSTANT NUM_OF_REPT_EXT_RANGE_END             : NATURAL                                          := NUM_OF_REPT_EXT_RANGE_BASE - (NUM_OF_REPT_EXT - 1);
  CONSTANT NUM_OF_REPT_EXT_VECTOR_SIZE           : NATURAL                                          := NUM_OF_REPT_EXT_RANGE_BASE - NUM_OF_REPT_EXT_RANGE_END + 1;
  CONSTANT NUM_OF_REPT_PORT_SIZE                 : NATURAL                                          := NUM_OF_REPT_VECTOR_SIZE + NUM_OF_REPT_EXT_VECTOR_SIZE;
  CONSTANT REP_STEP_VALUE_EXT_RANGE_BASE         : NATURAL                                          := NUM_OF_REPT_EXT_RANGE_END - 1;
  CONSTANT REP_STEP_VALUE_EXT_RANGE_END          : NATURAL                                          := REP_STEP_VALUE_EXT_RANGE_BASE - (REP_STEP_VALUE_EXT - 1);
  CONSTANT REP_STEP_VALUE_EXT_VECTOR_SIZE        : NATURAL                                          := REP_STEP_VALUE_EXT_RANGE_BASE - REP_STEP_VALUE_EXT_RANGE_END + 1;
  CONSTANT REP_STEP_VALUE_PORT_SIZE              : NATURAL                                          := REP_STEP_VALUE_VECTOR_SIZE + REP_STEP_VALUE_EXT_VECTOR_SIZE;
  CONSTANT FFT_END_STAGE_RANGE_BASE              : NATURAL                                          := REP_STEP_VALUE_EXT_RANGE_END - 1;
  CONSTANT FFT_END_STAGE_RANGE_END               : NATURAL                                          := FFT_END_STAGE_RANGE_BASE - (FFT_END_STAGE - 1);
  CONSTANT FFT_END_STAGE_VECTOR_SIZE             : NATURAL                                          := FFT_END_STAGE_RANGE_BASE - FFT_END_STAGE_RANGE_END + 1;
  CONSTANT DIMARCH_MODE_BIT                      : NATURAL                                          := FFT_END_STAGE_RANGE_END - 1;
  CONSTANT USE_COMPR_RANGE_BASE                  : NATURAL                                          := DIMARCH_MODE_BIT - 1;
  CONSTANT USE_COMPR_RANGE_END                   : NATURAL                                          := USE_COMPR_RANGE_BASE - (USE_COMPR - 1);
  CONSTANT USE_COMPR_VECTOR_SIZE                 : NATURAL                                          := USE_COMPR_RANGE_BASE - USE_COMPR_RANGE_END + 1;
  --! @}
  --! @}
  --! @}
  --<DPU INSTRUCTION TYPE CONSTANTS>--
  --! \addtogroup Instructions
  --! @{
  --! \defgroup DPU_instruction
  --! @{
  --! \brief Definitions and declarations of types and constants for the DPU instruction.
  --! \details 
  CONSTANT DPU_MODE_SEL                          : NATURAL                                          := 5;
  CONSTANT DPU_SATURAT                           : NATURAL                                          := 2;
  CONSTANT DPU_OUTP_A                            : NATURAL                                          := 2;
  CONSTANT DPU_OUTP_B                            : NATURAL                                          := 2;
  CONSTANT DPU_ACC_CLEAR_BIT                     : NATURAL                                          := HW_DPU_CONSTANT_WIDTH;
  CONSTANT DPU_PROCESS_INOUT                     : NATURAL                                          := 2;
  CONSTANT DPU_MODE_SEL_RANGE_BASE               : NATURAL                                          := INSTR_CODE_RANGE_END - 1;
  CONSTANT DPU_MODE_SEL_RANGE_END                : NATURAL                                          := DPU_MODE_SEL_RANGE_BASE - (DPU_MODE_SEL - 1);
  CONSTANT DPU_MODE_SEL_VECTOR_SIZE              : NATURAL                                          := DPU_MODE_SEL_RANGE_BASE - DPU_MODE_SEL_RANGE_END + 1;
  CONSTANT DPU_SATURAT_RANGE_BASE                : NATURAL                                          := DPU_MODE_SEL_RANGE_END - 1;
  CONSTANT DPU_SATURAT_RANGE_END                 : NATURAL                                          := DPU_SATURAT_RANGE_BASE - (DPU_SATURAT - 1);
  CONSTANT DPU_SATURAT_VECTOR_SIZE               : NATURAL                                          := DPU_SATURAT_RANGE_BASE - DPU_SATURAT_RANGE_END + 1;
  CONSTANT DPU_OUTP_A_RANGE_BASE                 : NATURAL                                          := DPU_SATURAT_RANGE_END - 1;
  CONSTANT DPU_OUTP_A_RANGE_END                  : NATURAL                                          := DPU_OUTP_A_RANGE_BASE - (DPU_OUTP_A - 1);
  CONSTANT DPU_OUTP_A_VECTOR_SIZE                : NATURAL                                          := DPU_OUTP_A_RANGE_BASE - DPU_OUTP_A_RANGE_END + 1;
  CONSTANT DPU_OUTP_B_RANGE_BASE                 : NATURAL                                          := DPU_OUTP_A_RANGE_END - 1;
  CONSTANT DPU_OUTP_B_RANGE_END                  : NATURAL                                          := DPU_OUTP_B_RANGE_BASE - (DPU_OUTP_B - 1);
  CONSTANT DPU_OUTP_B_VECTOR_SIZE                : NATURAL                                          := DPU_OUTP_B_RANGE_BASE - DPU_OUTP_B_RANGE_END + 1;
  CONSTANT DPU_ACC_CLEAR_RANGE_BASE              : NATURAL                                          := DPU_OUTP_B_RANGE_END - 3; --one is for acc_clear_sd; one bit for acc_clear_rst
  CONSTANT DPU_ACC_CLEAR_RANGE_END               : NATURAL                                          := DPU_ACC_CLEAR_RANGE_BASE - (DPU_ACC_CLEAR_BIT - 1);
  CONSTANT DPU_ACC_CLEAR_VECTOR_SIZE             : NATURAL                                          := DPU_ACC_CLEAR_RANGE_BASE - DPU_ACC_CLEAR_RANGE_END + 1;
  CONSTANT DPU_PROCESS_INOUT_RANGE_BASE          : NATURAL                                          := DPU_ACC_CLEAR_RANGE_END - 1;
  CONSTANT DPU_PROCESS_INOUT_RANGE_END           : NATURAL                                          := DPU_PROCESS_INOUT_RANGE_BASE - (DPU_PROCESS_INOUT - 1);
  CONSTANT DPU_PROCESS_INOUT_VECTOR_SIZE         : NATURAL                                          := DPU_PROCESS_INOUT_RANGE_BASE - DPU_PROCESS_INOUT_RANGE_END + 1;
  --! @}
  --! @}

  --<SWITCHBOX INSTRUCTION TYPE CONSTANTS>--
  --<--! \addtogroup Instructions
  --! @{
  --! \defgroup SWB_instruction
  --! @{
  --! \brief Definitions and declarations of types and constants for the switchbox instruction.
  --! \details 
  CONSTANT SWB_DAV                               : NATURAL                                          := 1;
  CONSTANT SWB_SRC_ADDR_ROW                      : NATURAL                                          := 1;
  CONSTANT SWB_SRC_DPU_REFI                      : NATURAL                                          := 1;
  CONSTANT SWB_SRC_OUTPUT_NR                     : NATURAL                                          := 1;
  CONSTANT SWB_HB_INDEX                          : NATURAL                                          := 3;
  CONSTANT SWB_SEND_TO_OTHER_ROW                 : NATURAL                                          := 1;
  CONSTANT SWB_V_INDEX                           : NATURAL                                          := 3;
  CONSTANT SWB_INSTR_WIDTH                       : NATURAL                                          := SWB_DAV + SWB_SRC_ADDR_ROW + SWB_SRC_DPU_REFI + SWB_SRC_OUTPUT_NR + SWB_HB_INDEX + SWB_SEND_TO_OTHER_ROW + SWB_V_INDEX;
  --CONSTANT SWB_TO_PORT   : natural := 2;
  CONSTANT SWB_UNUSED                            : NATURAL                                          := 3;

  CONSTANT SWB_DAV_RANGE_BASE                    : NATURAL                                          := INSTR_CODE_RANGE_END - 1;
  CONSTANT SWB_DAV_RANGE_END                     : NATURAL                                          := SWB_DAV_RANGE_BASE - (SWB_DAV - 1);
  CONSTANT SWB_DAV_VECTOR_SIZE                   : NATURAL                                          := SWB_DAV_RANGE_BASE - SWB_DAV_RANGE_END + 1;

  CONSTANT SWB_SRC_ADDR_ROW_BASE                 : NATURAL                                          := SWB_DAV_RANGE_END - 1;
  CONSTANT SWB_SRC_ADDR_ROW_END                  : NATURAL                                          := SWB_SRC_ADDR_ROW_BASE - (SWB_SRC_ADDR_ROW - 1);
  CONSTANT SWB_SRC_ADDR_ROW_VECTOR_SIZE          : NATURAL                                          := SWB_SRC_ADDR_ROW_BASE - SWB_SRC_ADDR_ROW_END + 1;

  CONSTANT SWB_SRC_DPU_REFI_BASE                 : NATURAL                                          := SWB_SRC_ADDR_ROW_END - 1;
  CONSTANT SWB_SRC_DPU_REFI_END                  : NATURAL                                          := SWB_SRC_DPU_REFI_BASE - (SWB_SRC_DPU_REFI - 1);
  CONSTANT SWB_SRC_DPU_REFI_VECTOR_SIZE          : NATURAL                                          := SWB_SRC_DPU_REFI_BASE - SWB_SRC_DPU_REFI_END + 1;

  CONSTANT SWB_SRC_OUTPUT_NR_BASE                : NATURAL                                          := SWB_SRC_DPU_REFI_END - 1;
  CONSTANT SWB_SRC_OUTPUT_NR_END                 : NATURAL                                          := SWB_SRC_OUTPUT_NR_BASE - (SWB_SRC_OUTPUT_NR - 1);
  CONSTANT SWB_SRC_OUTPUT_NR_VECTOR_SIZE         : NATURAL                                          := SWB_SRC_OUTPUT_NR_BASE - SWB_SRC_OUTPUT_NR_END + 1;

  CONSTANT SWB_HB_INDEX_BASE                     : NATURAL                                          := SWB_SRC_OUTPUT_NR_END - 1;
  CONSTANT SWB_HB_INDEX_END                      : NATURAL                                          := SWB_HB_INDEX_BASE - (SWB_HB_INDEX - 1);
  CONSTANT SWB_HB_INDEX_VECTOR_SIZE              : NATURAL                                          := SWB_HB_INDEX_BASE - SWB_HB_INDEX_END + 1;

  CONSTANT SWB_SEND_TO_OTHER_ROW_BASE            : NATURAL                                          := SWB_HB_INDEX_END - 1;
  CONSTANT SWB_SEND_TO_OTHER_ROW_END             : NATURAL                                          := SWB_SEND_TO_OTHER_ROW_BASE - (SWB_SEND_TO_OTHER_ROW - 1);
  CONSTANT SWB_SEND_TO_OTHER_ROW_VECTOR_SIZE     : NATURAL                                          := SWB_SEND_TO_OTHER_ROW_BASE - SWB_SEND_TO_OTHER_ROW_END + 1;

  CONSTANT SWB_V_INDEX_BASE                      : NATURAL                                          := SWB_SEND_TO_OTHER_ROW_END - 1;
  CONSTANT SWB_V_INDEX_END                       : NATURAL                                          := SWB_V_INDEX_BASE - (SWB_V_INDEX - 1);
  CONSTANT SWB_V_INDEX_VECTOR_SIZE               : NATURAL                                          := SWB_V_INDEX_BASE - SWB_V_INDEX_END + 1;

  CONSTANT SWB_UNUSED_RANGE_BASE                 : NATURAL                                          := SWB_V_INDEX_END - 1;
  CONSTANT SWB_UNUSED_RANGE_END                  : NATURAL                                          := SWB_UNUSED_RANGE_BASE - (SWB_UNUSED - 1);
  CONSTANT SWB_UNUSED_VECTOR_SIZE                : NATURAL                                          := SWB_UNUSED_RANGE_BASE - SWB_UNUSED_RANGE_END + 1;

  CONSTANT SWB_INSTR_PORT_SIZE                   : NATURAL                                          := SWB_DAV + SWB_SRC_ADDR_ROW + SWB_SRC_DPU_REFI + SWB_SRC_OUTPUT_NR + SWB_HB_INDEX + SWB_SEND_TO_OTHER_ROW + SWB_V_INDEX;
  --! @}
  --! @}
  --<BRANCH INSTRUCTION TYPE CONSTANTS>--
  --! \addtogroup Instructions
  --! @{
  --! \defgroup BR_instruction
  --! @{
  --! \brief Definitions and declarations of types and constants for the branch instruction.
  --! \details 
  CONSTANT BR_MODE                               : NATURAL                                          := 2;
  CONSTANT BR_FALSE_ADDRS_SIZE                   : NATURAL                                          := PC_SIZE;
  CONSTANT BR_UNUSED                             : NATURAL                                          := INSTR_WIDTH - BR_MODE - BR_FALSE_ADDRS_SIZE - INSTR_CODE_RANGE_VECTOR_SIZE;

  CONSTANT BR_MODE_RANGE_BASE                    : NATURAL                                          := INSTR_CODE_RANGE_END - 1;
  CONSTANT BR_MODE_RANGE_END                     : NATURAL                                          := BR_MODE_RANGE_BASE - (BR_MODE - 1);
  CONSTANT BR_MODE_VECTOR_SIZE                   : NATURAL                                          := BR_MODE_RANGE_BASE - BR_MODE_RANGE_END + 1;

  CONSTANT BR_FALSE_ADDRS_RANGE_BASE             : NATURAL                                          := BR_MODE_RANGE_END - 1;
  CONSTANT BR_FALSE_ADDRS_RANGE_END              : NATURAL                                          := BR_FALSE_ADDRS_RANGE_BASE - (BR_FALSE_ADDRS_SIZE - 1);
  CONSTANT BR_FALSE_ADDRS_VECTOR_SIZE            : NATURAL                                          := BR_FALSE_ADDRS_RANGE_BASE - BR_FALSE_ADDRS_RANGE_END + 1;

  CONSTANT BR_UNUSED_RANGE_BASE                  : NATURAL                                          := BR_FALSE_ADDRS_RANGE_END - 1;
  CONSTANT BR_UNUSED_RANGE_END                   : NATURAL                                          := BR_UNUSED_RANGE_BASE - (BR_UNUSED - 1);
  CONSTANT BR_UNUSED_VECTOR_SIZE                 : NATURAL                                          := BR_UNUSED_RANGE_BASE - BR_UNUSED_RANGE_END + 1;
  --! @}
  --! @}
  --<JUMP INSTRUCTION TYPE CONSTANTS>--
  --! \addtogroup Instructions
  --! @{
  --! \defgroup JUMP_instruction
  --! @{
  --! \brief Definitions and declarations of types and constants for the jump instruction.
  --! \details 
  CONSTANT TRUE_ADDRS_SIZE                       : NATURAL                                          := PC_SIZE;                                                      --log2(INSTR_DEPTH);
  CONSTANT JUMP_UNUSED_BITS                      : NATURAL                                          := INSTR_WIDTH - TRUE_ADDRS_SIZE - INSTR_CODE_RANGE_VECTOR_SIZE; -- 23-PC_SIZE;  -- instr_code:4 || true_addrs:6

  CONSTANT TRUE_ADDRS_RANGE_BASE                 : NATURAL                                          := INSTR_CODE_RANGE_END - 1;
  CONSTANT TRUE_ADDRS_RANGE_END                  : NATURAL                                          := TRUE_ADDRS_RANGE_BASE - (TRUE_ADDRS_SIZE - 1);
  CONSTANT TRUE_ADDRS_VECTOR_SIZE                : NATURAL                                          := TRUE_ADDRS_RANGE_BASE - TRUE_ADDRS_RANGE_END + 1;

  CONSTANT JUMP_UNUSED_RANGE_BASE                : NATURAL                                          := TRUE_ADDRS_RANGE_END - 1;
  CONSTANT JUMP_UNUSED_RANGE_END                 : NATURAL                                          := JUMP_UNUSED_RANGE_BASE - (JUMP_UNUSED_BITS - 1);
  CONSTANT JUMP_UNUSED_BITS_VECTOR_SIZE          : NATURAL                                          := JUMP_UNUSED_RANGE_BASE - JUMP_UNUSED_RANGE_END + 1;
  --! @}
  --! @}
  --<DELAY INSTRUCTION TYPE CONSTANTS>--
  --! \addtogroup Instructions
  --! @{
  --! \defgroup DLY_instruction
  --! @{
  --! \brief Definitions and declarations of types and constants for the delay instruction.
  --! \details 
  CONSTANT DLY_CYCLES                            : NATURAL                                          := 15;
  CONSTANT DLY_UNUSED_BITS                       : NATURAL                                          := 7;

  CONSTANT DLY_CYCLES_RANGE_BASE                 : NATURAL                                          := INSTR_CODE_RANGE_END - 2; -- one bit for static or dynamic selection
  CONSTANT DLY_CYCLES_RANGE_END                  : NATURAL                                          := DLY_CYCLES_RANGE_BASE - (DLY_CYCLES - 1);
  CONSTANT DLY_CYCLES_VECTOR_SIZE                : NATURAL                                          := DLY_CYCLES_RANGE_BASE - DLY_CYCLES_RANGE_END;

  CONSTANT DLY_UNUSED_BITS_RANGE_BASE            : NATURAL                                          := DLY_CYCLES_RANGE_END - 1;
  CONSTANT DLY_UNUSED_BITS_RANGE_END             : NATURAL                                          := DLY_UNUSED_BITS_RANGE_BASE - (DLY_UNUSED_BITS - 1);
  CONSTANT DLY_UNUSED_BITS_VECTOR_SIZE           : NATURAL                                          := DLY_UNUSED_BITS_RANGE_BASE - DLY_UNUSED_BITS_RANGE_END;
  --! @}
  --! @}
  --<RACCU INSTRUCTION TYPE CONSTANTS>--
  --! \addtogroup Instructions
  --! @{
  --! \defgroup RACCU_instruction
  --! @{
  --! \brief Definitions and declarations of types and constants for the delay instruction.
  --! \details 
  CONSTANT RACCU_MODE_SEL                        : NATURAL                                          := 3;
  CONSTANT RACCU_OPERAND                         : NATURAL                                          := 7;
  CONSTANT RACCU_RESULT_ADDR                     : NATURAL                                          := 4;

  CONSTANT RACCU_MODE_SEL_RANGE_BASE             : NATURAL                                          := INSTR_CODE_RANGE_END - 1;
  CONSTANT RACCU_MODE_SEL_RANGE_END              : NATURAL                                          := RACCU_MODE_SEL_RANGE_BASE - (RACCU_MODE_SEL - 1);
  CONSTANT RACCU_MODE_SEL_VECTOR_SIZE            : NATURAL                                          := RACCU_MODE_SEL_RANGE_BASE - RACCU_MODE_SEL_RANGE_END + 1;

  CONSTANT RACCU_OPERAND1_RANGE_BASE             : NATURAL                                          := RACCU_MODE_SEL_RANGE_END - 2; --one to determine if it is constant or indirect address
  CONSTANT RACCU_OPERAND1_RANGE_END              : NATURAL                                          := RACCU_OPERAND1_RANGE_BASE - (RACCU_OPERAND - 1);
  CONSTANT RACCU_OPERAND1_VECTOR_SIZE            : NATURAL                                          := RACCU_OPERAND1_RANGE_BASE - RACCU_OPERAND1_RANGE_END + 1;

  CONSTANT RACCU_OPERAND2_RANGE_BASE             : NATURAL                                          := RACCU_OPERAND1_RANGE_END - 2;
  CONSTANT RACCU_OPERAND2_RANGE_END              : NATURAL                                          := RACCU_OPERAND2_RANGE_BASE - (RACCU_OPERAND - 1);
  CONSTANT RACCU_OPERAND2_VECTOR_SIZE            : NATURAL                                          := RACCU_OPERAND2_RANGE_BASE - RACCU_OPERAND2_RANGE_END + 1;

  CONSTANT RACCU_RESULT_ADDR_RANGE_BASE          : NATURAL                                          := RACCU_OPERAND2_RANGE_END - 1;
  CONSTANT RACCU_RESULT_ADDR_RANGE_END           : NATURAL                                          := RACCU_RESULT_ADDR_RANGE_BASE - (RACCU_RESULT_ADDR - 1);
  CONSTANT RACCU_RESULT_ADDR_VECTOR_SIZE         : NATURAL                                          := RACCU_RESULT_ADDR_RANGE_BASE - RACCU_RESULT_ADDR_RANGE_END + 1;
  --! @}
  --! @}
  ----------------------------------------------------
  -- REV 5 2020-02-20 --------------------------------
  ----------------------------------------------------
  --<FOR HEADER INSTRUCTION TYPE CONSTANTS>--
  --CONSTANT FOR_INDEX_ADDR    : NATURAL := 4; -- up to 16 loops
  --CONSTANT FOR_INDEX_START   : NATURAL := 6;
  --CONSTANT FOR_ITER_NO       : NATURAL := 6; -- up to 64 iterations
  --CONSTANT FOR_HEADER_UNUSED : NATURAL := 6;
  --
  --CONSTANT FOR_INDEX_ADDR_RANGE_BASE  : NATURAL := INSTR_CODE_RANGE_END - --1;                         --22
  --CONSTANT FOR_INDEX_ADDR_RANGE_END   : NATURAL := FOR_INDEX_ADDR_RANGE_BASE - --(FOR_INDEX_ADDR - 1); --22-3+1= 20
  --CONSTANT FOR_INDEX_ADDR_VECTOR_SIZE : NATURAL := FOR_INDEX_ADDR_RANGE_BASE - --FOR_INDEX_ADDR_RANGE_END + 1;
  --
  --CONSTANT FOR_INDEX_START_RANGE_BASE  : NATURAL := FOR_INDEX_ADDR_RANGE_END - 1;
  --CONSTANT FOR_INDEX_START_RANGE_END   : NATURAL := FOR_INDEX_START_RANGE_BASE - --(FOR_INDEX_START - 1);
  --CONSTANT FOR_INDEX_START_VECTOR_SIZE : NATURAL := FOR_INDEX_START_RANGE_BASE - --FOR_INDEX_START_RANGE_END + 1;
  --
  --CONSTANT FOR_ITER_NO_RANGE_BASE  : NATURAL := FOR_INDEX_START_RANGE_END - 2; -- one bit for --dynamic or static
  --CONSTANT FOR_ITER_NO_RANGE_END   : NATURAL := FOR_ITER_NO_RANGE_BASE - (FOR_ITER_NO - 1);
  --CONSTANT FOR_ITER_NO_VECTOR_SIZE : NATURAL := FOR_ITER_NO_RANGE_BASE - --FOR_ITER_NO_RANGE_END + 1;
  --
  --CONSTANT FOR_HEADER_UNUSED_RANGE_BASE  : NATURAL := FOR_ITER_NO_RANGE_END - 1;
  --CONSTANT FOR_HEADER_UNUSED_RANGE_END   : NATURAL := FOR_HEADER_UNUSED_RANGE_BASE - --(FOR_HEADER_UNUSED - 1);
  --CONSTANT FOR_HEADER_UNUSED_VECTOR_SIZE : NATURAL := FOR_HEADER_UNUSED_RANGE_BASE - --FOR_HEADER_UNUSED_RANGE_END + 1;
  --
  ----<FOR TAIL INSTRUCTION TYPE CONSTANTS>--
  --CONSTANT FOR_TAIL_INDEX_ADDR : NATURAL := 4;
  --CONSTANT FOR_INDEX_STEP      : NATURAL := 6;
  --CONSTANT FOR_PC_TOGO         : NATURAL := PC_SIZE;
  --CONSTANT FOR_TAIL_UNUSED     : NATURAL := 13 - PC_SIZE;
  --
  --CONSTANT FOR_INDEX_STEP_RANGE_BASE  : NATURAL := INSTR_CODE_RANGE_END - 1;
  --CONSTANT FOR_INDEX_STEP_RANGE_END   : NATURAL := FOR_INDEX_STEP_RANGE_BASE - --(FOR_INDEX_STEP - 1);
  --CONSTANT FOR_INDEX_STEP_VECTOR_SIZE : NATURAL := FOR_INDEX_STEP_RANGE_BASE - --FOR_INDEX_STEP_RANGE_END + 1;
  --
  --CONSTANT FOR_PC_TOGO_RANGE_BASE  : NATURAL := FOR_INDEX_STEP_RANGE_END - 1;
  --CONSTANT FOR_PC_TOGO_RANGE_END   : NATURAL := FOR_PC_TOGO_RANGE_BASE - (FOR_PC_TOGO - 1);
  --CONSTANT FOR_PC_TOGO_VECTOR_SIZE : NATURAL := FOR_PC_TOGO_RANGE_BASE - --FOR_PC_TOGO_RANGE_END + 1;
  --
  --CONSTANT FOR_TAIL_INDEX_ADDR_RANGE_BASE  : NATURAL := FOR_PC_TOGO_RANGE_END - 1;
  --CONSTANT FOR_TAIL_INDEX_ADDR_RANGE_END   : NATURAL := FOR_TAIL_INDEX_ADDR_RANGE_BASE - --(FOR_TAIL_INDEX_ADDR - 1);
  --CONSTANT FOR_TAIL_INDEX_ADDR_VECTOR_SIZE : NATURAL := FOR_TAIL_INDEX_ADDR_RANGE_BASE - --FOR_TAIL_INDEX_ADDR_RANGE_END + 1;
  --
  --CONSTANT FOR_TAIL_UNUSED_RANGE_BASE  : NATURAL := FOR_TAIL_INDEX_ADDR_RANGE_END - 1;
  --CONSTANT FOR_TAIL_UNUSED_RANGE_END   : NATURAL := FOR_TAIL_UNUSED_RANGE_BASE - --(FOR_TAIL_UNUSED - 1);
  --CONSTANT FOR_TAIL_UNUSED_VECTOR_SIZE : NATURAL := FOR_TAIL_UNUSED_RANGE_BASE - --FOR_TAIL_UNUSED_RANGE_END + 1;

  --! \defgroup FOR_instruction
  --! @{
  --! \brief For-loop instruction.
  --! \details Instruction that configures the auto-loop module. Due to the amount of information needed
  --! to configure the auto-loop, the instruction is split into two instructions \ref For_basic [FOR_BASIC] and \ref For_exp [FOR_EXPANDED].
  --! The basic instruction configures the end pc, number of iterations and start of the iterator of a specific loop (specified by the loop ID).
  --! If only the basic instruction is used the step of the iterator is considered to be 1. 
  --! The expanded instruction can be used to define a different value for the iterator.
  --! \defgroup For_basic
  --! @{
  --! \brief Basic loop configuration instruction constatnts.
  --! \details The basic loop instruction defines the loop id, the end pc, number of iterations and start of the iterator 

  --<FOR BASIC INSTRUCTION TYPE CONSTANTS>--
  -- 4 bits for instruction code
  CONSTANT FOR_EXTENDED                          : NATURAL                                          := 1;                                                      --! Bit signify if the instruction is an extended instruction. If it is, then the following instruction in the sequencer should be treaded as an extension of this.
  CONSTANT FOR_LOOP_ID                           : NATURAL                                          := 2;                                                      --! # of bits. Can handle up to 4 iterations (can be increased depending on the remaining unused bits). 
  CONSTANT FOR_END_PC                            : NATURAL                                          := PC_SIZE;                                                --! # of bits. Label pointing to the PC of the loop. When the sequencer PC reaches this value, the auto-loop will increase the incrementor and check the end of loop, and modify the PC accordingly.
  CONSTANT FOR_START_SD                          : NATURAL                                          := 1;                                                      --! Bit signify if the start is static or dynamic. 
  CONSTANT FOR_START                             : NATURAL                                          := 6;                                                      --! Bit signify if the start or the RACCU register if dynamic. 
  CONSTANT FOR_ITER_SD                           : NATURAL                                          := 1;                                                      --!  Bit signify if the num of iterations is static or dynamic.
  CONSTANT FOR_ITER                              : NATURAL                                          := 6;                                                      --!  Bit signify if the num of iterations is static or dynamic.
  CONSTANT FOR_UNUSED                            : NATURAL                                          := 0;                                                      --! Unused bits for the basic for-loop instruction.
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  -- Instruction bit range definition: --------------------------------------------------------------------------------------------------------------------------------------
  -- Each of the following constants define the index bit where the specific filed of the instruction starts and ends. ------------------------------------------------------
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  CONSTANT FOR_LOOP_EXTENDED_BIT                 : NATURAL                                          := INSTR_CODE_RANGE_END - FOR_EXTENDED;                    --! Bit 22, extended or not instruction.
  CONSTANT FOR_LOOP_ID_BASE                      : NATURAL                                          := FOR_LOOP_EXTENDED_BIT - 1;                              --! Bit 21, start of the loop ID.
  CONSTANT FOR_LOOP_ID_END                       : NATURAL                                          := FOR_LOOP_ID_BASE - FOR_LOOP_ID + 1;                     --! Bit 20, end of the loop ID.
  CONSTANT FOR_LOOP_END_PC_BASE                  : NATURAL                                          := FOR_LOOP_ID_END - 1;                                    --! Bit 19, start of the end PC.
  CONSTANT FOR_LOOP_END_PC_END                   : NATURAL                                          := FOR_LOOP_END_PC_BASE - FOR_END_PC + 1;                  --! Bit 14, end of the end PC.
  CONSTANT FOR_LOOP_START_SD_BIT                 : NATURAL                                          := FOR_LOOP_END_PC_END - FOR_START_SD;                     --! Bit 13, static or dynamic START.
  CONSTANT FOR_LOOP_START_BASE                   : NATURAL                                          := FOR_LOOP_START_SD_BIT - 1;                              --! Bit 12, start of the START field.
  CONSTANT FOR_LOOP_START_END                    : NATURAL                                          := FOR_LOOP_START_BASE - FOR_START + 1;                    --! Bit 7, end of the START field.
  CONSTANT FOR_LOOP_ITER_SD_BIT                  : NATURAL                                          := FOR_LOOP_START_END - FOR_ITER_SD;                       --! Bit 6, static or dynamic number of iterations.
  CONSTANT FOR_LOOP_ITER_BASE                    : NATURAL                                          := FOR_LOOP_ITER_SD_BIT - 1;                               --! Bit 5, start of the number of iterations field.
  CONSTANT FOR_LOOP_ITER_END                     : NATURAL                                          := FOR_LOOP_ITER_BASE - FOR_ITER + 1;                      --! Bit 0, end of the number of iterations field.
  CONSTANT FOR_LOOP_UNUSED_BASE                  : NATURAL                                          := 0;                                                      --! No unused bits in this instruction
  CONSTANT FOR_LOOP_UNUSED_END                   : NATURAL                                          := 0;                                                      --! No Unused bits in this instruction
  --! @}
  --! @}

  --! \defgroup FOR_instruction
  --! @{
  --! \brief For-loop instruction.
  --! \details Instruction that configures the auto-loop module. Due to the amount of information needed
  --! to configure the auto-loop, the instruction is split into two instructions \ref For_basic [FOR_BASIC] and \ref For_exp [FOR_EXPANDED]
  --! \defgroup For_exp
  --! @{
  --! \brief Expanded loop instruction
  --! \details Expands the configuration of the for loop, with step value.

  --<FOR EXTENDED INSTRUCTION TYPE CONSTANTS>--
  CONSTANT FOR_EX_STEP_SD                        : NATURAL                                          := 1;                                                      --! Bit signify if the STEP is static or dynamic. 
  CONSTANT FOR_EX_STEP                           : NATURAL                                          := 6;                                                      --! Bits signify if the STEP or the RACCU register if dynamic. 
  CONSTANT FOR_EX_RELATED_LOOPS                  : NATURAL                                          := 4;                                                      --! Bits signifying if the loop has the same end-PC with other loops, and more specifically which loops share the same end-PC
  CONSTANT FOR_EX_UNUSED                         : NATURAL                                          := 16;                                                     --! Unused bits for the basic for-loop instruction.
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  -- Instruction bit range definition: --------------------------------------------------------------------------------------------------------------------------------------
  -- Each of the following constants define the index bit where the specific filed of the instruction starts and ends. ------------------------------------------------------
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  CONSTANT FOR_LOOP_STEP_SD_BIT                  : NATURAL                                          := INSTR_WIDTH - FOR_EX_STEP_SD;                           --! Bit 26, extended or not instruction.
  CONSTANT FOR_LOOP_STEP_BASE                    : NATURAL                                          := FOR_LOOP_STEP_SD_BIT - 1;                               --! Bit 25, start of the loop ID.
  CONSTANT FOR_LOOP_STEP_END                     : NATURAL                                          := FOR_LOOP_STEP_BASE - FOR_EX_STEP + 1;                   --! Bit 20, end of the loop ID.
  CONSTANT FOR_LOOP_RELATED_LOOPS_BASE           : NATURAL                                          := FOR_LOOP_STEP_END - 1;                                  --! Bit 19, start of the related loops field 
  CONSTANT FOR_LOOP_RELATED_LOOPS_END            : NATURAL                                          := FOR_LOOP_RELATED_LOOPS_BASE - FOR_EX_RELATED_LOOPS + 1; --! Bit 16, end of the related loops field.
  CONSTANT FOR_LOOP_EX_UNUSED_BASE               : NATURAL                                          := FOR_LOOP_RELATED_LOOPS_END - 1;                         --! Bit 15, start of unused bits.
  CONSTANT FOR_LOOP_EX_UNUSED_END                : NATURAL                                          := FOR_LOOP_EX_UNUSED_BASE - FOR_EX_UNUSED + 1;            --! Bit 0, end of the unused bits field.
  --! @}
  --! @}
  ----------------------------------------------------
  -- End of modification REV 5 -----------------------
  ----------------------------------------------------

  --<New SRAM AGU instructions>--
  --! \addtogroup Instructions
  --! @{
  --! \defgroup SRAM_instruction
  --! @{
  --! \brief Definitions and declarations of types and constants for the delay instruction.
  --! \details 
  CONSTANT RAM_DEPTH                             : INTEGER                                          := HW_RAM_DEPTH;
  CONSTANT RAM_ADDRESS_WIDTH                     : INTEGER                                          := LOG2(RAM_DEPTH);
  CONSTANT sr_delays                             : INTEGER                                          := 6;
  --------------------------------------------------------------------
  CONSTANT COLUMNS                               : NATURAL                                          := HW_COLUMNS; -- 
  CONSTANT ROWS                                  : NATURAL                                          := HW_ROWS;
  CONSTANT DiMArch_Rows                          : NATURAL                                          := HW_DIMARCH_ROWS;
  CONSTANT DiMArch_Row_Width                     : NATURAL                                          := log2(DiMArch_Rows + 1); -- Removed +1 outside log2 - Guido Baccelli 21/03/2019
  CONSTANT MAX_HOPS                              : INTEGER                                          := COLUMNS + DiMArch_Rows;
  ----------------- new sram agu instruction widths-------------------
  CONSTANT sr_en_width                           : INTEGER                                          := 1; -- this is send from the tile itself
  CONSTANT sr_mode_width                         : INTEGER                                          := 1;
  -- hops
  CONSTANT sr_hops_width                         : INTEGER                                          := log2_ceil(15);
  -- initials
  CONSTANT sr_initial_address_width              : INTEGER                                          := RAM_ADDRESS_WIDTH;
  CONSTANT sr_initial_delay_width                : INTEGER                                          := 4;
  -- loop1
  CONSTANT sr_loop1_iteration_width              : INTEGER                                          := RAM_ADDRESS_WIDTH;
  CONSTANT sr_loop1_increment_width              : INTEGER                                          := RAM_ADDRESS_WIDTH + 1;
  CONSTANT sr_loop1_delay_width                  : INTEGER                                          := sr_delays;
  -- loop2
  CONSTANT sr_loop2_iteration_width              : INTEGER                                          := RAM_ADDRESS_WIDTH;
  CONSTANT sr_loop2_increment_width              : INTEGER                                          := RAM_ADDRESS_WIDTH + 1;
  CONSTANT sr_loop2_delay_width                  : INTEGER                                          := sr_delays;

  ---------------------Start index
  CONSTANT sr_en_s                               : INTEGER                                          := 1;
  CONSTANT sr_en_e                               : INTEGER                                          := sr_en_width + sr_en_s - 1;
  CONSTANT sr_mode_s                             : INTEGER                                          := sr_en_e + 1;
  CONSTANT sr_mode_e                             : INTEGER                                          := sr_mode_width + sr_mode_s - 1;

  -------------------------------------------------------------------added hops constants---------------------------------
  CONSTANT sr_hops_s                             : INTEGER                                          := sr_mode_e + 1;
  CONSTANT sr_hops_e                             : INTEGER                                          := sr_hops_width + sr_hops_s - 1;
  -----------------------------------------------------------------------------------------------------------------------  
  CONSTANT sr_initial_address_s                  : INTEGER                                          := sr_hops_e + 1; -- changed to sr_hops_e

  CONSTANT sr_initial_address_e                  : INTEGER                                          := sr_initial_address_width + sr_initial_address_s - 1;
  CONSTANT sr_initial_delay_s                    : INTEGER                                          := sr_initial_address_e + 1;
  CONSTANT sr_initial_delay_e                    : INTEGER                                          := sr_initial_delay_width + sr_initial_delay_s - 1;
  CONSTANT sr_loop1_iteration_s                  : INTEGER                                          := sr_initial_delay_e + 1;
  CONSTANT sr_loop1_iteration_e                  : INTEGER                                          := sr_loop1_iteration_width + sr_loop1_iteration_s - 1;
  CONSTANT sr_loop1_increment_s                  : INTEGER                                          := sr_loop1_iteration_e + 1;
  CONSTANT sr_loop1_increment_e                  : INTEGER                                          := sr_loop1_increment_width + sr_loop1_increment_s - 1;
  CONSTANT sr_loop1_delay_s                      : INTEGER                                          := sr_loop1_increment_e + 1;
  CONSTANT sr_loop1_delay_e                      : INTEGER                                          := sr_loop1_delay_width + sr_loop1_delay_s - 1;
  CONSTANT sr_loop2_iteration_s                  : INTEGER                                          := sr_loop1_delay_e + 1;
  CONSTANT sr_loop2_iteration_e                  : INTEGER                                          := sr_loop2_iteration_width + sr_loop2_iteration_s - 1;
  CONSTANT sr_loop2_increment_s                  : INTEGER                                          := sr_loop2_iteration_e + 1;
  CONSTANT sr_loop2_increment_e                  : INTEGER                                          := sr_loop2_increment_width + sr_loop2_increment_s - 1;
  CONSTANT sr_loop2_delay_s                      : INTEGER                                          := sr_loop2_increment_e + 1;
  CONSTANT sr_loop2_delay_e                      : INTEGER                                          := sr_loop2_delay_width + sr_loop2_delay_s - 1;

  CONSTANT sr_Initial_address_sd                 : INTEGER                                          := sr_loop2_delay_e + 1;
  CONSTANT sr_Loop1_iteration_sd                 : INTEGER                                          := sr_Initial_address_sd + 1;
  CONSTANT sr_Loop2_iteration_sd                 : INTEGER                                          := sr_Loop1_iteration_sd + 1;
  CONSTANT sr_initial_delay_sd                   : INTEGER                                          := sr_Loop2_iteration_sd + 1;
  CONSTANT sr_Loop1_delay_sd                     : INTEGER                                          := sr_initial_delay_sd + 1;
  CONSTANT sr_Loop2_delay_sd                     : INTEGER                                          := sr_Loop1_delay_sd + 1;
  CONSTANT sr_Loop1_increment_sd                 : INTEGER                                          := sr_Loop2_delay_sd + 1;
  CONSTANT sr_Loop2_increment_sd                 : INTEGER                                          := sr_Loop1_increment_sd + 1;

  CONSTANT sr_rw                                 : INTEGER                                          := sr_loop2_delay_e + 1; -- static and dynamic bits are  used by sequencer and read write information is appended at the end. 

  CONSTANT sram_agu_width                        : INTEGER                                          := sr_rw;
  CONSTANT sram_tb_instr_width                   : INTEGER                                          := sr_Loop2_increment_sd - sr_en_width;
  CONSTANT sram_raccu_flags                      : INTEGER                                          := sr_Loop2_increment_sd - sr_loop2_delay_e;

  CONSTANT NoC_Bus_instr_width                   : INTEGER                                          := sram_agu_width;
  --! @}
  --! @}
  --<SEQUENCER TYPES BEGIN>--

  TYPE State_ty IS (IDLE_ST, SEQ_LOADING_ST, INSTR_DECODE_ST);
  TYPE Tb_State_ty IS (TB_IDLE_ST, TB_INIT_ST, TB_LOAD_ST);
  --! \addtogroup Instructions
  --! @{
  --! \addtogroup REFI
  --! @{
  --! \addtogroup REFI1
  --! @{
  TYPE Refi1_instr_ty IS RECORD
    instr_code       : STD_LOGIC_VECTOR(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0);
    reg_file_port    : STD_LOGIC_VECTOR(NR_OF_REG_FILE_PORTS_VECTOR_SIZE - 1 DOWNTO 0);
    subseq_instrs    : STD_LOGIC_VECTOR(NR_OF_INSTRS_VECTOR_SIZE - 1 DOWNTO 0);
    start_addrs_sd   : STD_LOGIC;
    start_addrs      : STD_LOGIC_VECTOR(STARTING_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
    no_of_addrs_sd   : STD_LOGIC;
    no_of_addrs      : STD_LOGIC_VECTOR(NR_OF_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
    initial_delay_sd : STD_LOGIC;
    initial_delay    : STD_LOGIC_VECTOR(INIT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
  END RECORD;
  --! @}
  --! \addtogroup REFI2
  --! @{
  TYPE Refi2_instr_ty IS RECORD
    instr_code           : STD_LOGIC_VECTOR(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0);
    step_val_sd          : STD_LOGIC;
    step_val             : STD_LOGIC_VECTOR(STEP_VALUE_VECTOR_SIZE - 1 DOWNTO 0);
    step_val_sign        : STD_LOGIC_VECTOR(STEP_VALUE_SIGN_VECTOR_SIZE - 1 DOWNTO 0);
    refi_middle_delay_sd : STD_LOGIC;
    refi_middle_delay    : STD_LOGIC_VECTOR(REG_FILE_MIDDLE_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
    no_of_reps_sd        : STD_LOGIC;
    no_of_reps           : STD_LOGIC_VECTOR(NUM_OF_REPT_VECTOR_SIZE - 1 DOWNTO 0);
    rpt_step_value       : STD_LOGIC_VECTOR(REP_STEP_VALUE_VECTOR_SIZE - 1 DOWNTO 0);
  END RECORD;
  --! @}
  --! \addtogroup REFI3
  --! @{
  TYPE Refi3_instr_ty IS RECORD
    instr_code            : STD_LOGIC_VECTOR(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0);
    rpt_delay_sd          : STD_LOGIC;
    rpt_delay             : STD_LOGIC_VECTOR(REPT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
    mode                  : STD_LOGIC_VECTOR(MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
    outp_cntrl            : STD_LOGIC_VECTOR(OUTPUT_CONTROL_VECTOR_SIZE - 1 DOWNTO 0);
    fft_stage             : STD_LOGIC_VECTOR(FFT_STAGE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
    refi_middle_delay_ext : STD_LOGIC_VECTOR(REG_FILE_MIDDLE_DELAY_EXT_VECTOR_SIZE - 1 DOWNTO 0);
    no_of_rpt_ext         : STD_LOGIC_VECTOR(NUM_OF_REPT_EXT_VECTOR_SIZE - 1 DOWNTO 0);
    rpt_step_value_ext    : STD_LOGIC_VECTOR(REP_STEP_VALUE_EXT_VECTOR_SIZE - 1 DOWNTO 0);
    end_fft_stage         : STD_LOGIC_VECTOR(FFT_END_STAGE_VECTOR_SIZE - 1 DOWNTO 0);
    dimarch_mode          : STD_LOGIC;
    --refi3_unused        : std_logic_vector(REFI3_UNUSED_VECTOR_SIZE - 1 DOWNTO 0);
    use_compr             : STD_LOGIC; --std_logic_vector(USE_COMPR_VECTOR_SIZE - 1 downto 0);
  END RECORD;
  --! @}
  --! @}
  --! \addtogroup DPU_Instruction
  --! @{
  TYPE Dpu_instr_ty IS RECORD
    instr_code        : STD_LOGIC_VECTOR(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0);
    dpu_mode          : STD_LOGIC_VECTOR(DPU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
    dpu_saturation    : STD_LOGIC_VECTOR(DPU_SATURAT_VECTOR_SIZE - 1 DOWNTO 0);
    dpu_out_a         : STD_LOGIC_VECTOR(DPU_OUTP_A_VECTOR_SIZE - 1 DOWNTO 0);
    dpu_out_b         : STD_LOGIC_VECTOR(DPU_OUTP_B_VECTOR_SIZE - 1 DOWNTO 0);
    dpu_acc_clear_rst : STD_LOGIC;
    dpu_acc_clear_sd  : STD_LOGIC;
    dpu_acc_clear     : STD_LOGIC_VECTOR(DPU_ACC_CLEAR_VECTOR_SIZE - 1 DOWNTO 0);
    dpu_process_inout : STD_LOGIC_VECTOR(DPU_PROCESS_INOUT_VECTOR_SIZE - 1 DOWNTO 0);
  END RECORD;
  --! @}
  --! \addtogroup SWB_instruction
  --! @{
  TYPE Swb_instr_ty IS RECORD
    instr_code        : STD_LOGIC_VECTOR(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0);
    swb_dav           : STD_LOGIC_VECTOR(SWB_DAV_VECTOR_SIZE - 1 DOWNTO 0);
    src_addr_row      : STD_LOGIC_VECTOR(SWB_SRC_ADDR_ROW_VECTOR_SIZE - 1 DOWNTO 0);
    from_block        : STD_LOGIC_VECTOR(SWB_SRC_DPU_REFI_VECTOR_SIZE - 1 DOWNTO 0);
    from_port         : STD_LOGIC_VECTOR(SWB_SRC_OUTPUT_NR_VECTOR_SIZE - 1 DOWNTO 0);
    hb_index          : STD_LOGIC_VECTOR(SWB_HB_INDEX_VECTOR_SIZE - 1 DOWNTO 0);
    send_to_other_row : STD_LOGIC_VECTOR(SWB_SEND_TO_OTHER_ROW_VECTOR_SIZE - 1 DOWNTO 0);
    v_index           : STD_LOGIC_VECTOR(SWB_V_INDEX_VECTOR_SIZE - 1 DOWNTO 0);
    --to_port       : std_logic_vector(SWB_TO_PORT_VECTOR_SIZE DOWNTO 0);
    swb_unused        : STD_LOGIC_VECTOR(SWB_UNUSED_VECTOR_SIZE - 1 DOWNTO 0);
  END RECORD;
  --! @}
  --! \addtogroup BR_instruction
  --! @{
  TYPE Branch_instr_ty IS RECORD
    instr_code       : STD_LOGIC_VECTOR(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0);
    brnch_mode       : STD_LOGIC_VECTOR(BR_MODE_VECTOR_SIZE - 1 DOWNTO 0);
    brnch_false_addr : STD_LOGIC_VECTOR(BR_FALSE_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
    brnch_unused     : STD_LOGIC_VECTOR(BR_UNUSED_VECTOR_SIZE - 1 DOWNTO 0);
  END RECORD;
  --! @}
  --! \addtogroup JUMP_instruction
  --! @{
  TYPE Jump_instr_ty IS RECORD
    instr_code  : STD_LOGIC_VECTOR(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0);
    true_addrs  : STD_LOGIC_VECTOR(TRUE_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
    jump_unused : STD_LOGIC_VECTOR(JUMP_UNUSED_BITS_VECTOR_SIZE - 1 DOWNTO 0);
  END RECORD;
  --! @}
  --! \addtogroup DLY_instruction
  --! @{
  TYPE Delay_instr_ty IS RECORD
    instr_code    : STD_LOGIC_VECTOR(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0);
    del_cycles_sd : STD_LOGIC;
    del_cycles    : STD_LOGIC_VECTOR(DLY_CYCLES_VECTOR_SIZE DOWNTO 0);
    del_unused    : STD_LOGIC_VECTOR(DLY_UNUSED_BITS_VECTOR_SIZE DOWNTO 0);
  END RECORD;
  --! @}
  --! \addtogroup RACCU_instruction
  --! @{
  -- 27 bits used, no unused bits left
  TYPE Raccu_instr_ty IS RECORD
    instr_code         : STD_LOGIC_VECTOR(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0);  --! 4 bits
    raccu_mode         : STD_LOGIC_VECTOR(RACCU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);    --! 3 bits
    raccu_op1_sd       : STD_LOGIC;                                                    --! 1 bit
    raccu_op1          : STD_LOGIC_VECTOR(RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0);    --! 7 bits
    raccu_op2_sd       : STD_LOGIC;                                                    --! 1 bit
    raccu_op2          : STD_LOGIC_VECTOR(RACCU_OPERAND2_VECTOR_SIZE - 1 DOWNTO 0);    --! 7 bits
    raccu_result_addrs : STD_LOGIC_VECTOR(RACCU_RESULT_ADDR_VECTOR_SIZE - 1 DOWNTO 0); --! 4 bits
  END RECORD;
  --! @}
  --! \addtogroup FOR_instruction
  --! @{
  --! \addtogroup For_basic
  --! @{
  ----------------------------------------------------
  -- REV 5 2020-02-24 --------------------------------
  ----------------------------------------------------
  --TYPE For_header_instr_ty IS RECORD
  --    instr_code       : std_logic_vector(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0);
  --    index_raccu_addr : std_logic_vector(FOR_INDEX_ADDR_VECTOR_SIZE - 1 DOWNTO 0);
  --    index_start      : std_logic_vector(FOR_INDEX_START_VECTOR_SIZE - 1 DOWNTO 0);
  --    iter_no_sd       : std_logic;
  --    iter_no          : std_logic_vector(FOR_ITER_NO_VECTOR_SIZE - 1 DOWNTO 0);
  --    header_unused    : std_logic_vector(FOR_HEADER_UNUSED_VECTOR_SIZE - 1 DOWNTO 0);
  --END RECORD;
  TYPE For_basic_instr_ty IS RECORD
    instr_code : STD_LOGIC_VECTOR(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0); -- 4
    loop_id    : unsigned(FOR_LOOP_ID - 1 DOWNTO 0);                          -- 2
    end_pc     : unsigned(FOR_END_PC - 1 DOWNTO 0);                           -- 6
    start_sd   : STD_LOGIC;                                                   -- 1
    start      : signed(FOR_START - 1 DOWNTO 0);                              -- 6
    iter_sd    : STD_LOGIC;                                                   -- 1
    iter       : unsigned(FOR_ITER - 1 DOWNTO 0);                             -- 6
    extend     : STD_LOGIC;                                                   -- 1
    --    unused     : std_logic_vector(FOR_UNUSED - 1 DOWNTO 0);
  END RECORD;
  --! @}
  --! \addtogroup For_exp
  --! @{
  --TYPE For_tail_instr_ty IS RECORD
  --    instr_code       : std_logic_vector(INSTR_CODE_RANGE_VECTOR_SIZE - 1 DOWNTO 0);
  --    index_step       : std_logic_vector(FOR_INDEX_STEP_VECTOR_SIZE - 1 DOWNTO 0);
  --    pc_togo          : std_logic_vector(FOR_PC_TOGO_VECTOR_SIZE - 1 DOWNTO 0);
  --    index_raccu_addr : std_logic_vector(FOR_INDEX_ADDR_VECTOR_SIZE - 1 DOWNTO 0);
  --    tail_unused      : std_logic_vector(FOR_TAIL_UNUSED_VECTOR_SIZE - 1 DOWNTO 0);
  --END RECORD;
  TYPE For_exp_instr_ty IS RECORD
    step_sd       : STD_LOGIC;
    step          : signed(FOR_EX_STEP - 1 DOWNTO 0);
    related_loops : STD_LOGIC_VECTOR(FOR_EX_RELATED_LOOPS - 1 DOWNTO 0);
    unused        : STD_LOGIC_VECTOR(FOR_EX_UNUSED - 1 DOWNTO 0);
  END RECORD;
  ----------------------------------------------------
  -- End of modification REV 5 -----------------------
  ----------------------------------------------------
  --! @}
  --! @}
  --! \addtogroup SRAM_instruction
  --! @{
  ---------Route and Sram Record added! --------
  TYPE Route_instr_ty IS RECORD
    instr_code      : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
    horizontal_dir  : STD_LOGIC;
    horizontal_hops : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0);
    vertical_dir    : STD_LOGIC;
    vertical_hops   : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0);
    direction       : STD_LOGIC;
    select_drra_row : STD_LOGIC;
  END RECORD;

  TYPE Sram_instr_ty IS RECORD
    instr_code    : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
    rw            : STD_LOGIC;
    init_addr     : STD_LOGIC_VECTOR(7 - 1 DOWNTO 0);
    init_delay    : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
    l1_iter       : STD_LOGIC_VECTOR(7 - 1 DOWNTO 0);
    l1_step       : STD_LOGIC_VECTOR(8 - 1 DOWNTO 0);
    l1_delay      : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
    l2_iter       : STD_LOGIC_VECTOR(7 - 1 DOWNTO 0);
    l2_step       : STD_LOGIC_VECTOR(8 - 1 DOWNTO 0);
    l2_delay      : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
    init_addr_sd  : STD_LOGIC;
    init_delay_sd : STD_LOGIC;
    l1_iter_sd    : STD_LOGIC;
    l1_step_sd    : STD_LOGIC;
    l1_delay_sd   : STD_LOGIC;
    l2_iter_sd    : STD_LOGIC;
    l2_step_sd    : STD_LOGIC;
    l2_delay_sd   : STD_LOGIC;
    hops          : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
  END RECORD;
  --! @}
  --! @}
  ----------------------------------------
  TYPE Instr_reg_ty IS ARRAY (0 TO INSTR_DEPTH - 1) OF STD_LOGIC_VECTOR(INSTR_WIDTH - 1 DOWNTO 0);

  CONSTANT REFI1_INIT              : Refi1_instr_ty                       := (instr_code => (OTHERS => '0'), reg_file_port => (OTHERS => '0'), subseq_instrs => (OTHERS => '0'), start_addrs_sd => '0', start_addrs => (OTHERS => '0'), no_of_addrs_sd => '0', no_of_addrs => (OTHERS => '0'), initial_delay_sd => '0', initial_delay => (OTHERS => '0'));

  --<SEQUENCER TYPES END>--

  --<DPU CONSTANTS BEGIN>--

  CONSTANT NR_OF_DPU_IN_PORTS      : NATURAL                              := 4;
  CONSTANT NR_OF_DPU_OUT_PORTS     : NATURAL                              := 2;
  CONSTANT DPU_CTRL_OUT_WIDTH      : INTEGER                              := 2;
  CONSTANT DPU_IN_WIDTH            : INTEGER                              := BITWIDTH;
  CONSTANT DPU_MODE_CFG_WIDTH      : INTEGER                              := DPU_MODE_SEL; --5
  CONSTANT DPU_OUT_WIDTH           : INTEGER                              := BITWIDTH;
  CONSTANT DPU_SAT_CTRL_WIDTH      : INTEGER                              := DPU_SATURAT;
  CONSTANT SEQ_COND_STATUS_WIDTH   : INTEGER                              := 2;
  CONSTANT DPU_ACC_CLEAR_WIDTH     : INTEGER                              := DPU_ACC_CLEAR_VECTOR_SIZE;
  CONSTANT DPU_PROCESS_INOUT_WIDTH : INTEGER                              := 2;
  --! All generics must be <= OUT_NUM: it doesn't make sense to get more results in parallel than the number of outputs
  CONSTANT MULT_NUM                : INTEGER                              := 2;
  CONSTANT ADD_NUM                 : INTEGER                              := 2;
  CONSTANT MAC_NUM                 : INTEGER                              := 2; --! MAC_NUM must be <= min(MULT_NUM, ADD_NUM)
  CONSTANT OUT_NUM                 : INTEGER                              := NR_OF_DPU_OUT_PORTS;
  CONSTANT SQUASH_NUM              : INTEGER                              := 2; --! SQUASH_NUM must be <= MAC_NUM
  CONSTANT MAXMIN_NUM              : INTEGER                              := 2;
  CONSTANT DIV_NUM                 : INTEGER                              := 1; --! DIV_NUM must be >= SOFTMAX_NUM, <= OUT_NUM
  CONSTANT EXP_NUM                 : INTEGER                              := 1; --! EXP_NUM must be = DIV_NUM
  CONSTANT SHIFT_NUM               : INTEGER                              := 2;
  CONSTANT ELU_NUM                 : INTEGER                              := 1;
  CONSTANT SOFTMAX_NUM             : INTEGER                              := 1;  --! Softmax = min(NR_OF_DPU_IN_PORTS/2, NR_OF_DPU_IN_PORTS/2)
  CONSTANT DPU_Q_FORMAT            : INTEGER                              := 0;  --! # of fractional bits

  CONSTANT IDLE                    : INTEGER                              := 0;  -- out0, out1 = none
  CONSTANT ADD                     : INTEGER                              := 1;  -- out0 = in0 + in1 , out1 = in2 + in3
  --CONSTANT ADD_ABS	 : integer := 2;  -- out0 = |in0 + in1| , out1 = |in2+in3|
  CONSTANT ADD_3                   : INTEGER                              := 2;  -- out0 = in0 + in1 + 1n2
  CONSTANT ADD_ACC                 : INTEGER                              := 3;  -- out0 = in0 + acc0 , out1 = in2 + acc1
  CONSTANT ADD_CONST               : INTEGER                              := 4;  -- out0 = in0 + dpureg0 , out1 = in2 + dpureg1
  CONSTANT SUBT                    : INTEGER                              := 5;  -- out0 = in1 - in0 , out1 = in3 - in2
  CONSTANT SUBT_ABS                : INTEGER                              := 6;  -- out0 = |in1 - in0| , out1 = |in3 - in2|
  CONSTANT SUBT_ACC                : INTEGER                              := 7;  -- out0 = acc0 - in0 , out1 = acc1 - in2
  CONSTANT MULT                    : INTEGER                              := 8;  -- out0 = in0 * in1 , out1 = in2 * in3
  --CONSTANT MULT_NEG	 : integer := 9;  -- out0 = -in0 * in1 , out1 = -in2 * in3
  CONSTANT MULT_ADD                : INTEGER                              := 9;  -- out0 = in0*in1+in2
  CONSTANT MULT_CONST              : INTEGER                              := 10; -- out0 = in0 * dpureg0 , out1 = in2 * dpureg1
  CONSTANT MAC                     : INTEGER                              := 11; -- out0 = (in0 * in1) + acc0  , out1 = (in2 * in3) + acc1
  --CONSTANT MAC_NEG	 : integer := 12; -- out0 = (-in0 * in1) + acc0 , out1 = (-in2 * in3) + acc1
  CONSTANT SOM_DIST                : INTEGER                              := 12; -- out0 = N/2-|in0-N/2|
  CONSTANT MAC_CONST               : INTEGER                              := 13; -- out0 = (in0 * const) + acc0 , out1 = (in2 * const) + acc1
  CONSTANT MAX_ACC                 : INTEGER                              := 14; -- out0 = max(in0, acc0) , out1 = max(in1, acc1)
  CONSTANT MAX_CONST               : INTEGER                              := 15; -- out0 = max(in0, const) , out1 = max(in1, const)
  CONSTANT MIN_ACC                 : INTEGER                              := 16; -- out0 = min(in0, acc0) , out1 = min(in1, acc1)
  --CONSTANT MIN_CONST	 : integer := 17; -- out0 = min(in0, const) , out1 = min(in1, const)
  CONSTANT MAX                     : INTEGER                              := 17; -- out0 = max(in0, in1) , out1 = max(in2, in3)
  CONSTANT SHIFT_L                 : INTEGER                              := 18; -- out0 = in0 sla in1 , out1 = in2 sla in3
  CONSTANT SHIFT_R                 : INTEGER                              := 19; -- out0 = in0 sra in1 , out1 = in2 sra in3
  CONSTANT SIGM                    : INTEGER                              := 20; -- out0 = sigmoid(in0) , out1 = sigmoid(in1)
  CONSTANT TANHYP                  : INTEGER                              := 21; -- out0 = tanh(in0) , out1 = tanh(in1)
  CONSTANT EXPON                   : INTEGER                              := 22; -- out0 = exp(in0) , out1 = exp(in1) (if DIV_NUM = 2)
  CONSTANT LK_RELU                 : INTEGER                              := 23; -- out0 = max(const * in0, in0) , out1 = max(const * in1, in1) (const < 1)
  CONSTANT ELU                     : INTEGER                              := 24; -- out0 = in0 if in0 > 0, else a*(in1-1) , out1 = in2 if in2 > 0, else a*(in3-1)
  CONSTANT DIV                     : INTEGER                              := 25; -- out0 = in0/in1 , out1 = in0 % in1
  CONSTANT ACC_SOFTMAX             : INTEGER                              := 26; -- (out0 & out1), (dpureg0 & dpureg1) = in0 + (dpureg0 & dpureg1) 
  CONSTANT DIV_SOFTMAX             : INTEGER                              := 27; -- out0 = in0/(dpureg0 & dpureg1) , out1 = none
  CONSTANT LD_REGS                 : INTEGER                              := 28; -- dpureg0 = in0 , dpureg1 = in1
  CONSTANT ST_REGS                 : INTEGER                              := 29; -- out0 = dpureg0 , out1 = dpureg1
  CONSTANT CHANGE_Q                : INTEGER                              := 30; -- q_reg = const

  -- dpu output control modes select between right and left

  CONSTANT OUT_NONE                : NATURAL                              := 0;
  CONSTANT OUT_RIGHT               : NATURAL                              := 1;
  CONSTANT OUT_LEFT                : NATURAL                              := 2;
  CONSTANT OUT_BOTH                : NATURAL                              := 3;

  CONSTANT UP_COUNT                : INTEGER RANGE 0 TO 2 ** DPU_IN_WIDTH := 7; --x"00000007";
  CONSTANT DOWN_COUNT              : INTEGER RANGE 0 TO 2 ** DPU_IN_WIDTH := 4;
  CONSTANT SET_COUNT               : INTEGER RANGE 0 TO 2 ** DPU_IN_WIDTH := 5; --x"00000005";
  CONSTANT RESET_COUNT             : INTEGER RANGE 0 TO 2 ** DPU_IN_WIDTH := 6; --x"00000006";
  CONSTANT STOP_COUNT              : INTEGER RANGE 0 TO 2 ** DPU_IN_WIDTH := 8; --x"00000008";

  --<DPU CONSTANTS END>--

  --<DPU TYPES BEGIN>--

  SUBTYPE dpu_cfg_mode_type IS STD_LOGIC_VECTOR(DPU_MODE_CFG_WIDTH - 1 DOWNTO 0);
  SUBTYPE dpu_ctrl_out_type IS STD_LOGIC_VECTOR(DPU_CTRL_OUT_WIDTH - 1 DOWNTO 0);
  SUBTYPE dpu_in_type IS signed(DPU_IN_WIDTH - 1 DOWNTO 0);

  --<DPU TYPES END>--

  --<REGISTER FILE CONSTANTS BEGIN>--

  CONSTANT REG_FILE_DEPTH              : INTEGER := HW_REG_FILE_DEPTH;
  CONSTANT MEM_BLOCK_SIZE              : INTEGER := 16;
  CONSTANT NUM_OF_REG_BLOCKS           : INTEGER := REG_FILE_DEPTH/MEM_BLOCK_SIZE;
  CONSTANT RLE_WP                      : INTEGER := 4;

  --<REGISTER FILE CONSTANTS END>--

  --<DiMArch Constants BEGIN>--
  CONSTANT SRAM_SEQUENCER_INSTRUCTIONS : INTEGER := 16;
  CONSTANT SRAM_DEPTH                  : INTEGER := HW_RAM_DEPTH;
  CONSTANT SRAM_WIDTH                  : INTEGER := MEM_BLOCK_SIZE * BITWIDTH;
  CONSTANT REG_ADDRESS_WIDTH           : INTEGER := log2(NUM_OF_REG_BLOCKS);
  CONSTANT REG_FILE_MEM_ADDR_WIDTH     : NATURAL := REG_ADDRESS_WIDTH;
  CONSTANT REG_FILE_MEM_DATA_WIDTH     : NATURAL := SRAM_WIDTH;
  CONSTANT CONFIG_WIDTH                : NATURAL := 40;
  --<DiMArch Constants END>--

  --<REFI CONSTANTS BEGIN>--

  CONSTANT NR_OF_REG_FILE_IN_PORTS     : NATURAL := 2;
  CONSTANT REG_FILE_DATA_WIDTH         : INTEGER := BITWIDTH;

  CONSTANT REG_FILE_ADDR_WIDTH         : INTEGER := 6;

  CONSTANT WORDS_PER_BLOCK             : INTEGER := MEM_BLOCK_SIZE;
  CONSTANT NR_REG_FILE_DATA_BLOCKS     : INTEGER := REG_FILE_DEPTH/WORDS_PER_BLOCK;
  CONSTANT INITIAL_DELAY_WIDTH         : INTEGER := 6;
  CONSTANT ADDR_COUNTER_WIDTH          : INTEGER := 6;
  CONSTANT START_ADDR_WIDTH            : INTEGER := 6;
  CONSTANT ADDR_OFFSET_WIDTH           : INTEGER := 6;
  CONSTANT ADDR_OFFSET_SIGN_WIDTH      : INTEGER := 1;
  CONSTANT INITIAL_DELAY_BIT           : INTEGER := 31;
  CONSTANT START_ADDR_BIT              : INTEGER := 27;
  CONSTANT ADDR_OFFSET_BIT             : INTEGER := 21;
  CONSTANT ADDR_COUNTER_BIT            : INTEGER := 16;
  CONSTANT PORT_NUMBER_WIDTH           : INTEGER := 2;

  -- NEW CONSTANTS FOR REGISTER FILE AGU_block
  CONSTANT START_ADDR_WIDTH_BLOCK      : INTEGER := REG_FILE_MEM_ADDR_WIDTH;
  CONSTANT ADDR_OFFSET_WIDTH_BLOCK     : INTEGER := REG_FILE_MEM_ADDR_WIDTH;

  --<REFI CONSTANTS END>--

  --<REFI TYPES BEGIN>--

  --<REFI TYPES END>--

  --<COMPUTATIONAL FABRIC CONSTANTS BEGIN>--
  CONSTANT NR_OF_HOPS                  : NATURAL := 2;                  --sliding window connectivity RANGE
  CONSTANT MAX_NR_OF_OUTP_N_HOPS       : INTEGER := 2 * NR_OF_HOPS + 1; -- Max # outps in NR_OF_HOPS range
  CONSTANT NR_OF_OUTP                  : NATURAL := 2;                  -- # of outp for Reg File/DPU - 2
  CONSTANT NR_OF_COL_INPS_ONE_CELL     : NATURAL := 6;
  CONSTANT NR_OF_COL_INPS              : NATURAL := 12; -- # of inps in a column,
  -- formerly known as "N" in
  -- the previous version
  CONSTANT HC_OUT_BITS                 : NATURAL := 4;
  CONSTANT OUTP0                       : NATURAL := 0;
  CONSTANT OUTP1                       : NATURAL := 1;
  CONSTANT NR_OF_VLANE_IN_PORTS        : NATURAL := NR_OF_REG_FILE_IN_PORTS + NR_OF_DPU_IN_PORTS; --
  --to determine the correct v_lane for each dpu/reg_file in port in the fabric
  CONSTANT TRISTATE_SEL                : NATURAL := 5;

  --<COMPUTATIONAL FABRIC CONSTANTS END>--

  --<COMPUTATIONAL FABRIC TYPES BEGIN>--

  --TYPE v_bus_ty_2d  IS ARRAY (natural RANGE <>) OF signed (BITWIDTH-1 DOWNTO 0);
  TYPE h_bus_seg_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF signed(BITWIDTH - 1 DOWNTO 0);
  TYPE h_bus_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF signed(BITWIDTH - 1 DOWNTO 0);
  TYPE hc_out_w_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(HC_OUT_BITS - 1 DOWNTO 0);
  TYPE hc_in_bus_ty IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(HC_OUT_BITS - 1 DOWNTO 0);
  TYPE all_hc_in_bus_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(HC_OUT_BITS - 1 DOWNTO 0);
  -- TYPE v6_bus_ty IS ARRAY (0 TO NR_OF_COL_INPS/2-1) OF signed (BITWIDTH-1 DOWNTO 0);  
  --TYPE v6_bus_ty_array IS ARRAY (natural RANGE <>) OF v6_bus_ty;
  -- TYPE v6_bus_ty_2d IS ARRAY (natural RANGE <>, NATURAL RANGE <>) OF v6_bus_ty; 

  TYPE v_bus_ty IS ARRAY (0 TO NR_OF_COL_INPS/2 - 1) OF signed(BITWIDTH - 1 DOWNTO 0);
  TYPE v_bus_ty_array IS ARRAY (NATURAL RANGE <>) OF v_bus_ty;
  TYPE v_bus_ty_2d IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF v_bus_ty;
  -- TYPE sel_swb_ty IS ARRAY (0 to NR_OF_COL_INPS-1) of unsigned (5 downto 0);
  -- Type sel_swb_ty_2d is ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) of sel_swb_ty;
  TYPE s_bus_switchbox_ty IS ARRAY (0 TO NR_OF_COL_INPS/2 - 1) OF STD_LOGIC_VECTOR(5 DOWNTO 0);   --5) OF --std_logic_vector (NR_OF_COL_INPS_ONE_CELL-1 DOWNTO 0);--NR_OF_COL_INPS-1) OF std_logic_vector (5 DOWNTO 0);  --
  TYPE s_bus_switchbox_2d_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF s_bus_switchbox_ty; --
  TYPE s_bus_switchbox_ty_array IS ARRAY (NATURAL RANGE <>) OF s_bus_switchbox_ty;

  --MAKE GENERIC
  TYPE s_bus_out_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(SWB_INSTR_PORT_SIZE - 1 DOWNTO 0); --
  --MAKE GENERIC
  TYPE v_lane_ty IS ARRAY (NATURAL RANGE <>) OF v_bus_ty;

  TYPE data_array_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF signed(BITWIDTH - 1 DOWNTO 0);
  TYPE dpu_cfg_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(DPU_MODE_SEL_VECTOR_SIZE DOWNTO 0);
  TYPE dpu_acc_clear_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(DPU_ACC_CLEAR_WIDTH DOWNTO 0);
  TYPE dpu_output_ctrl_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(DPU_CTRL_OUT_WIDTH - 1 DOWNTO 0);
  TYPE dpu_sat_ctrl_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(DPU_SAT_CTRL_WIDTH - 1 DOWNTO 0);

  TYPE reg_initial_delay_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(INIT_DELAY_VECTOR_SIZE DOWNTO 0);
  TYPE reg_instr_start_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC;
  TYPE reg_start_addrs_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(STARTING_ADDRS_VECTOR_SIZE DOWNTO 0);
  TYPE reg_step_val_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(STEP_VALUE_VECTOR_SIZE DOWNTO 0);
  TYPE reg_step_val_sign_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(STEP_VALUE_SIGN_VECTOR_SIZE DOWNTO 0);
  TYPE reg_no_of_addrs_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(NR_OF_ADDRS_VECTOR_SIZE DOWNTO 0);
  TYPE reg_port_type_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(NR_OF_REG_FILE_PORTS_VECTOR_SIZE DOWNTO 0);
  TYPE reg_outp_cntrl_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(OUTPUT_CONTROL_VECTOR_SIZE DOWNTO 0);
  TYPE reg_middle_delay_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(REG_FILE_MIDDLE_DELAY_PORT_SIZE DOWNTO 0);
  TYPE reg_no_of_rpts_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(NUM_OF_REPT_PORT_SIZE DOWNTO 0);
  TYPE reg_rpt_step_value_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(REP_STEP_VALUE_PORT_SIZE DOWNTO 0);
  TYPE reg_rpt_delay_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(REPT_DELAY_VECTOR_SIZE DOWNTO 0);
  TYPE reg_mode_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(MODE_SEL_VECTOR_SIZE DOWNTO 0);
  TYPE reg_fft_stage_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(FFT_STAGE_SEL_VECTOR_SIZE DOWNTO 0);
  TYPE seq_cond_status_ty IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC_VECTOR(SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0);

  --<COMPUTATIONAL FABRIC TYPES END>-- 

  --<MEMORY FABRIC TYPES BEGIN>--
  TYPE v_bus_signal_ty IS ARRAY (COLUMNS - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(INSTR_WIDTH + 1 DOWNTO 0);
  TYPE lcc_elements_ty IS ARRAY (COLUMNS - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(COLUMNS + ROWS + CONFIG_WIDTH DOWNTO 0);
  TYPE row_sel_ty IS ARRAY (0 TO COLUMNS) OF STD_LOGIC_VECTOR(ROWS DOWNTO 0);
  --  TYPE origin_ty   IS (FROM_SOURCE,FROM_DESTINATION);
  --<MEMORY FABRIC TYPES END>--

  --<RACCU TYPES BEGIN>--
  --! \addtogroup RACCU
  --! @{
  --! \defgroup Types
  --! \brief
  --! \details
  --! @{
  ----------------------------------------------------
  -- REV 5 2020-02-24 --------------------------------
  ----------------------------------------------------
  --TYPE raccu_loop_reg_ty IS RECORD
  --loop_index_value : std_logic_vector(RACCU_REG_BITWIDTH - 1 DOWNTO 0);
  --loop_counter     : std_logic_vector(RACCU_REG_BITWIDTH - 1 DOWNTO 0);
  --loop_end_flag    : std_logic;
  --END RECORD;

  --TYPE raccu_loop_array_ty IS ARRAY (MAX_NO_OF_RACCU_LOOPS - 1 DOWNTO 0) OF raccu_loop_reg_ty; --std_logic_vector(lOOP_REG_WIDTH-1 downto 0);
  TYPE loop_iterators_ty IS ARRAY (MAX_NO_OF_LOOPS - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(RACCU_REG_BITWIDTH - 1 DOWNTO 0);    --! Type for the registers used to store the values for the loop iterators 
  TYPE raccu_reg_out_ty IS ARRAY (RACCU_REGFILE_DEPTH - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(RACCU_REG_BITWIDTH - 1 DOWNTO 0); --! Type for the RACCU registers

  TYPE For_instr_ty IS RECORD
    loop_id       : unsigned(FOR_LOOP_ID - 1 DOWNTO 0);                  --! Loop ID
    start_pc      : unsigned(FOR_END_PC - 1 DOWNTO 0);                   --! Start PC label
    end_pc        : unsigned(FOR_END_PC - 1 DOWNTO 0);                   --! End PC label
    start_sd      : STD_LOGIC;                                           --! Dynamic or static start value
    start         : signed(FOR_START - 1 DOWNTO 0);                      --! Start value
    iter_sd       : STD_LOGIC;                                           --! Dynamic or static num. of iterations value
    iter          : unsigned(FOR_ITER - 1 DOWNTO 0);                     --! Num. of iterations value
    default_step  : STD_LOGIC;                                           --! Use of default step value (1)
    step_sd       : STD_LOGIC;                                           --! Dynamic or static step value
    step          : signed(FOR_EX_STEP - 1 DOWNTO 0);                    --! Step value
    related_loops : STD_LOGIC_VECTOR(FOR_EX_RELATED_LOOPS - 1 DOWNTO 0); --! 4 bits that when active they signify that the corresponding loop has the same end-PC
  END RECORD;

  TYPE For_conf_ty IS RECORD
    active        : STD_LOGIC;                                           --! Active loop
    start_pc      : unsigned(PC_SIZE - 1 DOWNTO 0);                      --! Start PC label
    end_pc        : unsigned(FOR_END_PC - 1 DOWNTO 0);                   --! End PC label
    start         : signed(FOR_START - 1 DOWNTO 0);                      --! Start value
    iter          : unsigned(FOR_ITER - 1 DOWNTO 0);                     --! Num. of iterations value
    step          : signed(FOR_EX_STEP - 1 DOWNTO 0);                    --! Step value
    related_loops : STD_LOGIC_VECTOR(FOR_EX_RELATED_LOOPS - 1 DOWNTO 0); --! 4 bits that when active they signify that the corresponding loop has the same end-PC
  END RECORD;

  TYPE loop_config_reg_ty IS ARRAY (MAX_NO_OF_LOOPS - 1 DOWNTO 0) OF For_conf_ty;                     --! Type definition of the loop configuration registers

  TYPE incrementor_reg_ty IS ARRAY (MAX_NO_OF_LOOPS - 1 DOWNTO 0) OF unsigned(FOR_ITER - 1 DOWNTO 0); --! Type definition of the loop iterator registers 

  CONSTANT for_instr_zero : For_instr_ty :=
  (
  (OTHERS => '0'), --loop_id
  (OTHERS => '0'), --start_pc
  (OTHERS => '0'), --end_pc
  '0',             --start_sd
  (OTHERS => '0'), --start
  '0',             --iter_sd
  (OTHERS => '0'), --iter
  '0',             --default_step
  '0',             --step_sd
  (OTHERS => '0'), --step
  (OTHERS => '0')  --related_loops
  );

  CONSTANT conf_zero : For_conf_ty :=
  (
  '0',             --active
  (OTHERS => '0'), --start pc
  (OTHERS => '0'), --end pc
  --
  (OTHERS => '0'), --start
  --
  (OTHERS => '0'), --iter
  --
  (OTHERS => '0'), --step
  --
  (OTHERS => '0')  --related_loops
  );

  TYPE priority_input_ty IS ARRAY (NATURAL RANGE <>) OF unsigned(FOR_LOOP_ID - 1 DOWNTO 0); --! Input type for the priority mux
  ----------------------------------------------------
  -- End of modification REV 5 -----------------------
  ----------------------------------------------------
  --! @}
  --! @}
  --<RACCU TYPES END>--

  --<DiMArch Constants BEGIN>--
  CONSTANT RF0                    : INTEGER   := 0;
  CONSTANT RF1                    : INTEGER   := 1;
  CONSTANT SEQ                    : INTEGER   := 2;
  CONSTANT UNSEL                  : INTEGER   := 3;

  CONSTANT FROM_SOURCE            : STD_LOGIC := '1';
  CONSTANT FROM_DESTINATION       : STD_LOGIC := '0';
  --<DiMArch Constants BEGIN>--
  CONSTANT SRAM_ADDRESS_WIDTH     : INTEGER   := log2(SRAM_DEPTH);
  CONSTANT SRAM_NumberOfInstrRegs : INTEGER   := 256;

  -----------------------------------------------------------------------------------------
  --Constants for SRAM_Sequencer
  CONSTANT MAX_DELAY              : INTEGER   := 512;
  CONSTANT MAX_INCR_DECR_VALUE    : INTEGER   := 64;
  CONSTANT MAX_REPETITION         : INTEGER   := 512;

  ---------------------------------------
  -- Types
  ---------------------------------------
  TYPE Refi_AGU_st_ty IS (IDLE_ST, COUNT_ST, RD_WR_ST, BIT_REVRS_ST, REPETITION_ST);

END top_consts_types_package;