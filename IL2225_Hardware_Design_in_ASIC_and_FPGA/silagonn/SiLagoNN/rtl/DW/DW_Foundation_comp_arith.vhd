-------------------------------------------------------
--! @file DWARE.DW_foundation_comp_arith.vhd
--! @brief DW_package for simulation, it contains the component definitions
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2021-02-22
--! @bug NONE
--! @todo NONE
--! @copyright  GNU Public License [GPL-3.0].
-------------------------------------------------------
---------------- Copyright (c) notice -----------------------------------------
--
-- The VHDL code, the logic and concepts described in this file constitute
-- the intellectual property of the authors listed below, who are affiliated
-- to KTH(Kungliga Tekniska Högskolan), School of EECS, Kista.
-- Any unauthorised use, copy or distribution is strictly prohibited.
-- Any authorised use, copy or distribution should carry this copyright notice
-- unaltered.
-------------------------------------------------------------------------------
-- Title      : DW_package for simulation, it contains the component definitions
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : DWARE.DW_foundation_comp_arith.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2021-02-22
-- Last update: 2021-02-22
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2021-02-22  1.0      Dimitrios Stathis      Created
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

--! This package is used for simulation only
--! and it replaces the synopsys DW_Foundation_comp_arith package
PACKAGE DW_Foundation_comp_arith IS

  COMPONENT DW_div_pipe IS
    GENERIC (
      a_width     : POSITIVE := 16; -- >= 1
      b_width     : POSITIVE := 16;-- >= 1
      tc_mode     : NATURAL  := 1; -- 1 or 0 (0 -> unsigned, 1 -> signed)
      rem_mode    : NATURAL  := 1; -- 1 or 0 (0 -> remainder output is VHDL modulus, 1 -> remainder is remainder)
      num_stages  : POSITIVE := 2; -- >= 2 (default is 2 -> i.e. 1 register, so that it takes two cycles)
      stall_mode  : NATURAL  := 0; -- 1 or 0 (0 -> non-stallable, 1 stallable)
      rst_mode    : NATURAL  := 1; -- 0, 1, or 2 (0 -> no reset, 1 -> asyn, 2 -> sync)
      op_iso_mode : NATURAL  := 0  -- 0 to 4 Type of operand isolation, if stall is 0 then this parameter is ignored. 0 -> follow intend defined by the compiler options, 1 -> no isolation, 2 -> 'AND' gate isolation, 3 -> 'OR' gate isolation, 4 -> preferred style 'OR'
    );
    PORT (
      clk         : IN STD_LOGIC;
      rst_n       : IN STD_LOGIC;
      en          : IN STD_LOGIC;
      a           : IN STD_LOGIC_VECTOR(a_width - 1 DOWNTO 0);
      b           : IN STD_LOGIC_VECTOR(b_width - 1 DOWNTO 0);
      quotient    : OUT STD_LOGIC_VECTOR(a_width - 1 DOWNTO 0); -- (a/b)
      remainder   : OUT STD_LOGIC_VECTOR(b_width - 1 DOWNTO 0);
      divide_by_0 : OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT DW_div IS
    GENERIC (
      a_width  : POSITIVE := 16; -- >= 1
      b_width  : POSITIVE := 16;-- >= 1
      tc_mode  : NATURAL  := 1; -- 1 or 0 (0 -> unsigned, 1 -> signed)
      rem_mode : NATURAL  := 1  -- 1 or 0 (0 -> remainder output is VHDL modulus, 1 -> remainder is remainder)
    );
    PORT (
      a           : IN STD_LOGIC_VECTOR(a_width - 1 DOWNTO 0);
      b           : IN STD_LOGIC_VECTOR(b_width - 1 DOWNTO 0);
      quotient    : OUT STD_LOGIC_VECTOR(a_width - 1 DOWNTO 0); -- (a/b)
      remainder   : OUT STD_LOGIC_VECTOR(b_width - 1 DOWNTO 0);
      divide_by_0 : OUT STD_LOGIC
    );
  END COMPONENT;

END PACKAGE;