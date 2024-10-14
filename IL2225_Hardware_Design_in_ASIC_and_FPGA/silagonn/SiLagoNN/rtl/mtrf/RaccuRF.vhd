-------------------------------------------------------
--! @file RaccuRF.vhd
--! @brief Raccu Register File
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
-- Title      : Raccu Register File
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : RaccuRF.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2020-04-29
-- Last update: 2020-04-29
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

--! Register file shared between the RACCU and the loop manager

--! The register file has a common input & output from the RACCU and the loop accelerator.
--! It receives up to 4 values from the loop accelerator together with enable signals (since multiple of them can be active in the same time, a normal address would not work).
--! It also receives a value from the RACCU together with write address, since the RACCU only writes one value every time. 
--! The register file is shared between the RACCU and the loop accelerator, meaning that they can potentially use the same RF locations.
--! The compiler/programmer has to make sure that the are no conflicts.
--! !!!ATTENTION!!! In case of a conflict where both the loop accelerator and the RACCU write in the same location of the RF, the RACCU will overwrite the data from
--! the loop accelerator!
ENTITY RaccuRF IS
  PORT (
    rst_n       : IN STD_LOGIC;                                                     --! Reset (active-low)
    clk         : IN STD_LOGIC;                                                     --! Clock
    --------------------------------------------------------------------------------
    -- Control input 
    --------------------------------------------------------------------------------
    en          : IN STD_LOGIC_VECTOR(RACCU_REGFILE_DEPTH - 1 DOWNTO 0);            --! Generic enable signal for the registers
    --------------------------------------------------------------------------------
    -- Input from RACCU
    --------------------------------------------------------------------------------
    wr_addr     : IN STD_LOGIC_VECTOR (RACCU_RESULT_ADDR_VECTOR_SIZE - 1 DOWNTO 0); --! Register file write address from the RACCU
    wr_en       : IN STD_LOGIC;                                                     --! Write enable
    data_in     : IN STD_LOGIC_VECTOR(RACCU_REG_BITWIDTH - 1 DOWNTO 0);             --! Data input
    --------------------------------------------------------------------------------
    -- Input from autoloop
    --------------------------------------------------------------------------------
    iterators   : IN loop_iterators_ty;                                             --! Output new values for the iterator values
    active_iter : IN STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);                --! Active bits, each bit is bound to an iterator. If '1' then the register holding the current value of the iterator will be updated with the value from the 'iterators' output
    --------------------------------------------------------------------------------
    -- Common output
    --------------------------------------------------------------------------------
    data_out    : OUT raccu_reg_out_ty                                              --! Data output
  );
END RaccuRF;

--! @brief Architecture for the RACCU register file.
--! @details This is a special register file, dedicated for the RACCU & the loop accelerator
--! The register file receives data from both the RACCU and the loop accelerator. The program
--! is responsible to make sure that there is no overwrite of data. 
ARCHITECTURE RTL OF RaccuRF IS
  SIGNAL raccu_data_reg : raccu_reg_out_ty;  --! Registered values of the data
  SIGNAL inputFromLoop  : loop_iterators_ty; --! Temporary signals for the register inputs
BEGIN
  --! Main registered process for the register file
  reg_proc : PROCESS (clk, rst_n)
    VARIABLE write_addr : unsigned(RACCU_RESULT_ADDR_VECTOR_SIZE - 1 DOWNTO 0); --! Temporary variable to hold the write address
  BEGIN
    IF rst_n = '0' THEN
      raccu_data_reg <= (OTHERS => (OTHERS => '0'));
    ELSIF rising_edge(clk) THEN
      -- Send in the input from the loop in the upper half of the RF
      FOR i IN MAX_NO_OF_LOOPS - 1 DOWNTO 0 LOOP
        raccu_data_reg(RACCU_REGFILE_DEPTH - 1 - i) <= inputFromLoop(MAX_NO_OF_LOOPS - 1 - i);
      END LOOP;
      -- Writing process from the raccu 
      -- ATTENTION: It overwrites the data from the LOOP
      write_addr := unsigned(wr_addr);
      IF (wr_en = '1' AND en(to_integer(write_addr)) = '1') THEN
        raccu_data_reg(to_integer(write_addr)) <= data_in;
      END IF;
    END IF;
  END PROCESS reg_proc;

  --------------------------------------------------------------------------------
  -- Muxs controlling the inputs
  --------------------------------------------------------------------------------
  --! This process controls the input mux from the loop to the register file
  input_mux_loop : PROCESS (raccu_data_reg, iterators, active_iter)
  BEGIN
    -- Default values 
    FOR i IN MAX_NO_OF_LOOPS - 1 DOWNTO 0 LOOP
      inputFromLoop(MAX_NO_OF_LOOPS - 1 - i) <= raccu_data_reg(RACCU_REGFILE_DEPTH - 1 - i);
    END LOOP;
    -- Control inputs
    FOR i IN MAX_NO_OF_LOOPS - 1 DOWNTO 0 LOOP
      IF (active_iter(i) = '1') THEN
        inputFromLoop(MAX_NO_OF_LOOPS - 1 - i) <= iterators(i);
      END IF;
    END LOOP;
  END PROCESS input_mux_loop;

  --------------------------------------------------------------------------------
  -- Control output
  --------------------------------------------------------------------------------
  output_p : PROCESS (ALL)
  BEGIN
    FOR i IN RACCU_REGFILE_DEPTH - 1 DOWNTO 0 LOOP

      IF en(i) = '1' THEN
        data_out(i) <= raccu_data_reg(i);
      ELSE
        data_out(i) <= (OTHERS => '0');
      END IF;
    END LOOP;
  END PROCESS output_p;

END RTL;