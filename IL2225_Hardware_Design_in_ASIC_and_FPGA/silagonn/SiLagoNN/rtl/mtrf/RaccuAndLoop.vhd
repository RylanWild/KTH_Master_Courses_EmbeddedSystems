-------------------------------------------------------
--! @file RaccuAndLoop.vhd
--! @brief Raccu and loop manager together with their register file
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2020-04-29
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
-- Title      : Raccu and loop manager together with their register file
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : RaccuAndLoop.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2020-04-29
-- Last update: 2022-02-03
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2020
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2020-04-29  1.0      Dimitrios Stathis      Created
-- 2022-03-18  1.1      Dimitrios Stathis      Change to adapt new functionality
--                                              of the autoloop rev1.2
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

--! IEEE Library
LIBRARY IEEE;
--! Use standard library
USE IEEE.std_logic_1164.ALL;
--! Use numeric standard library for arithmetic operations
USE ieee.numeric_std.ALL;
--! Top constant and type package for type definition
USE work.top_consts_types_package.ALL;

--! This is the top module for the RACCU plus the loop accelerator 

--! This entity includes three components, the RACCU, the loop accelerator, and the RACCU register
--! file that is shared between the two. It is meant to be instantiated in place of the old RACCU
--! inside the sequencer. 
ENTITY RaccuAndLoop IS
  PORT (
    rst_n             : IN STD_LOGIC;                                                     --! Reset (active-low)
    clk               : IN STD_LOGIC;                                                     --! Clock
    --------------------------------------------------------------------------------
    -- Instruction input (loop)
    --------------------------------------------------------------------------------
    instr_loop        : IN STD_LOGIC;                                                     --! Bit signaling the configuration of the autoloop unit.
    config_loop       : IN For_instr_ty;                                                  --! Configuration input of autoloop
    --------------------------------------------------------------------------------
    -- Extra inputs from the sequencer
    --------------------------------------------------------------------------------
    pc                : IN unsigned(PC_SIZE - 1 DOWNTO 0);                                --! Program counter.
    --done              : IN std_logic;                                                     --! Signal from the sequencer to show that the instruction execution has been completed.
    pc_out            : OUT unsigned(PC_SIZE - 1 DOWNTO 0);                               --! GOTO Program counter.
    jump              : OUT STD_LOGIC;                                                    --! Signal the sequencer that the goto address should be the one used to update the program counter.
    ----------------------------------------------------
    -- REV 1.1 2022-03-18 ------------------------------
    ----------------------------------------------------
    -- Adapted for the rev1.2 of the autoloop
    is_delay          : IN STD_LOGIC;                                                     --! Signal inferring that there is an active delay instruction
    ----------------------------------------------------
    -- End of modification REV 1.1 ---------------------
    ----------------------------------------------------
    --------------------------------------------------------------------------------
    -- RACCU inputs
    --------------------------------------------------------------------------------
    raccu_in1         : IN STD_LOGIC_VECTOR (RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0);    --! Value of operand 1 or address of RACCU RF when dynamic
    raccu_in2         : IN STD_LOGIC_VECTOR (RACCU_OPERAND2_VECTOR_SIZE - 1 DOWNTO 0);    --! Value of operand 2 or address of RACCU RF when dynamic
    raccu_cfg_mode    : IN STD_LOGIC_VECTOR (RACCU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);    --! RACCU mode
    raccu_res_address : IN STD_LOGIC_VECTOR (RACCU_RESULT_ADDR_VECTOR_SIZE - 1 DOWNTO 0); --! RF address where to store the result of the operation
    --------------------------------------------------------------------------------
    -- RACCU RF 
    --------------------------------------------------------------------------------
    en                : IN STD_LOGIC_VECTOR(RACCU_REGFILE_DEPTH - 1 DOWNTO 0);            --! Enable for the RACCU register file
    raccu_regout      : OUT raccu_reg_out_ty                                              --! Output values from the RACCU RF
  );
END RaccuAndLoop;

--! @brief The architecture of the top unit that includes the RACCU, loop accelerator, and 
--! RACCU RF. It includes just the instantiation and the connection between the three units.
ARCHITECTURE RTL OF RaccuAndLoop IS
  --------------------------------------------------------------------------------
  -- RACCU Registers
  --------------------------------------------------------------------------------
  SIGNAL raccu_regs  : raccu_reg_out_ty;                                              --! Contents of the RACCU registers
  --------------------------------------------------------------------------------
  -- Output from autoloop to RACCU RF
  --------------------------------------------------------------------------------
  SIGNAL iterators   : loop_iterators_ty;                                             --! Output new values for the iterator values from the autoloop
  SIGNAL active_iter : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);                --! Active bits, each bit is bound to an iterator. If '1' then the register holding the current value of the iterator will be updated with the value from the 'iterators' output (from autoloop)
  --------------------------------------------------------------------------------
  -- RACCU outputs
  --------------------------------------------------------------------------------
  SIGNAL wr_addr     : STD_LOGIC_VECTOR (RACCU_RESULT_ADDR_VECTOR_SIZE - 1 DOWNTO 0); --! RF write address from the RACCU
  SIGNAL wr_en       : STD_LOGIC;                                                     --! RF write enable from the RACCU
  SIGNAL data_to_RF  : STD_LOGIC_VECTOR(RACCU_REG_BITWIDTH - 1 DOWNTO 0);             --! Data output to the RF from the RACCU
BEGIN
  --------------------------------------------------------------------------------
  -- Instance of loop accelerator
  --------------------------------------------------------------------------------
  autoLoop_u : ENTITY work.autoloop
    PORT MAP(
      rst_n       => rst_n,
      clk         => clk,
      instr       => instr_loop,
      config      => config_loop,
      pc          => pc,
      pc_out      => pc_out,
      jump        => jump,
      raccu_regs  => raccu_regs,
      iterators   => iterators,
      is_delay    => is_delay,
      active_iter => active_iter
    );

  --------------------------------------------------------------------------------
  --  Instance of RACCU
  --------------------------------------------------------------------------------
  raccu_u : ENTITY work.RACCU
    PORT MAP(
      clk               => clk,
      rst_n             => rst_n,
      raccu_in1         => raccu_in1,
      raccu_in2         => raccu_in2,
      raccu_cfg_mode    => raccu_cfg_mode,
      raccu_res_address => raccu_res_address,
      data_RF           => raccu_regs,
      wr_addr           => wr_addr,
      wr_en             => wr_en,
      data_to_RF        => data_to_RF
    );

  --------------------------------------------------------------------------------
  -- Instance of the RACCU RF
  --------------------------------------------------------------------------------
  raccu_RF_u : ENTITY work.RaccuRF
    PORT MAP(
      rst_n       => rst_n,
      clk         => clk,
      en          => en,
      wr_addr     => wr_addr,
      wr_en       => wr_en,
      data_in     => data_to_RF,
      iterators   => iterators,
      active_iter => active_iter,
      data_out    => raccu_regs
    );

  --------------------------------------------------------------------------------
  -- RACCU RF output
  --------------------------------------------------------------------------------
  raccu_regout <= raccu_regs;
END RTL;