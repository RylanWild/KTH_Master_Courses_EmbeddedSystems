-------------------------------------------------------
--! @file data_crossbar.vhd
--! @brief 
--! @details 
--! @author Muhammad Adeel Tajammul
--! @version 1.0
--! @date 
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
-- Title      : UnitX
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : data_crossbar.vhd
-- Author     : Muhammad Adeel Tajammul
-- Company    : KTH
-- Created    : 
-- Last update: 
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2014
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
--             1.0      Muhammad Adeel Tajammul      Created
--             2.0      Cyril                        Modifications for path-building
--             2.1      Dimitrios Stathis            Debugging errors on crossbar data 
--                                                   propagation
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

---------------- -----------------------------------------------------------
-- This is the bi-directional version of the data crossbar 
----------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.top_consts_types_package.SRAM_WIDTH;
USE work.crossbar_types_n_constants.ALL;

ENTITY data_crossbar IS
  GENERIC (NumberofPorts : INTEGER := nr_of_crossbar_ports);
  PORT (
    rst_n          : IN STD_LOGIC;
    clk            : IN STD_LOGIC;
    DIRECTION      : IN CORSSBAR_INSTRUCTION_RECORD_TYPE;
    --		VER_SELECT : IN CORSSBAR_INSTRUCTION_RECORD_TYPE;

    DATA_MEM_IN    : IN STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
    DATA_NORTH_IN  : IN STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
    DATA_SOUTH_IN  : IN STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
    DATA_EAST_IN   : IN STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
    DATA_WEST_IN   : IN STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
    DATA_MEM_OUT   : OUT STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
    DATA_NORTH_OUT : OUT STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
    DATA_SOUTH_OUT : OUT STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
    DATA_EAST_OUT  : OUT STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
    DATA_WEST_OUT  : OUT STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0)
  );
END ENTITY data_crossbar;

ARCHITECTURE RTL OF data_crossbar IS
  TYPE data_array IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
  TYPE inps_type IS ARRAY (nr_of_crossbar_ports DOWNTO 0) OF data_array(nr_of_crossbar_ports - 1 DOWNTO 0);

  SIGNAL input              : data_array(nr_of_crossbar_ports DOWNTO 0);

  SIGNAL inps               : inps_type;
  SIGNAL selects            : CROSSBAR_select_type;

  SIGNAL DATA_MEM_IN_TMP    : STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0); -- Coming from our memory
  SIGNAL DATA_NORTH_OUT_TMP : STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
  SIGNAL DATA_SOUTH_OUT_TMP : STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
  SIGNAL DATA_EAST_OUT_TMP  : STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
  SIGNAL DATA_WEST_OUT_TMP  : STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);

BEGIN

  input(DEFAULT_INT) <= (OTHERS => '0');
  input(MEMORY_INT)  <= DATA_MEM_IN;
  input(NORTH_INT)   <= DATA_NORTH_IN;
  input(EAST_INT)    <= DATA_EAST_IN;
  input(WEST_INT)    <= DATA_WEST_IN;
  input(SOUTH_INT)   <= DATA_SOUTH_IN;

  p_OUTPUT_REG : PROCESS (rst_n, clk)
  BEGIN
    IF rst_n = '0' THEN
      DATA_MEM_OUT       <= (OTHERS => '0');
      DATA_NORTH_OUT_TMP <= (OTHERS => '0');
      DATA_EAST_OUT_TMP  <= (OTHERS => '0');
      DATA_WEST_OUT_TMP  <= (OTHERS => '0');
      DATA_SOUTH_OUT_TMP <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      DATA_MEM_OUT       <= input(TO_INTEGER(UNSIGNED(selects(MEMORY_INT))));
      DATA_NORTH_OUT_TMP <= input(TO_INTEGER(UNSIGNED(selects(NORTH_INT))));
      DATA_EAST_OUT_TMP  <= input(TO_INTEGER(UNSIGNED(selects(EAST_INT))));
      DATA_WEST_OUT_TMP  <= input(TO_INTEGER(UNSIGNED(selects(WEST_INT))));
      DATA_SOUTH_OUT_TMP <= input(TO_INTEGER(UNSIGNED(selects(SOUTH_INT))));
    END IF;

  END PROCESS p_OUTPUT_REG;
  ----------------------------------------------------
  -- REV 2.1 2022-09-13 ------------------------------
  ----------------------------------------------------
  -- Removing the OR and adding default to the select signals,
  -- so when a new configuration comes in the old one is removed
  -- OUTPUT OR
  --p_OUTPUT_OR : PROCESS (DATA_NORTH_OUT_TMP, DATA_EAST_OUT_TMP, DATA_WEST_OUT_TMP, DATA_SOUTH_OUT_TMP, DATA_MEM_IN)
  --BEGIN
  DATA_NORTH_OUT <= DATA_NORTH_OUT_TMP;
  DATA_EAST_OUT  <= DATA_EAST_OUT_TMP;
  DATA_WEST_OUT  <= DATA_WEST_OUT_TMP;
  DATA_SOUTH_OUT <= DATA_SOUTH_OUT_TMP;
  --END PROCESS p_OUTPUT_OR;

  p_select : PROCESS (clk, rst_n) IS
  BEGIN
    IF rst_n = '0' THEN
      selects <= (OTHERS => STD_LOGIC_VECTOR(TO_UNSIGNED(DEFAULT_INT, selects(0)'length)));
    ELSIF rising_edge(clk) THEN
      IF DIRECTION.ENABLE = '1' THEN
        selects                                            <= (OTHERS => STD_LOGIC_VECTOR(TO_UNSIGNED(DEFAULT_INT, selects(0)'length)));
        selects(to_integer(unsigned(DIRECTION.SELECT_TO))) <= DIRECTION.SELECT_FROM;
        selects(MEMORY_INT)                                <= DIRECTION.SELECT_FROM;
      END IF;
      --  		if VER_SELECT.ENABLE = '1' then  		  		selects(to_integer(unsigned(VER_SELECT.SELECT_TO)))<= VER_SELECT.SELECT_FROM;end if;
    END IF;
  END PROCESS p_select;

  ----------------------------------------------------
  -- End of modification REV 2.1 ---------------------
  ----------------------------------------------------

END ARCHITECTURE RTL;