-------------------------------------------------------
--! @file DW01_add.vhd
--! @brief Add unit for simulation to replace the DW component
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
-- Title      : Add unit for simulation to replace the DW component
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : DW01_add.vhd
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
--! Use numeric standard library for arithmetic operations
USE ieee.numeric_std.ALL;

--! This module is defined to replace the DW component for simulation.

--! This entity has to be compiled in the DWARE library=>
--! !!!! IMPORTANT !!!! DO NOT INCLUDE IN THE SYNTHESIS !!!!
ENTITY DW01_add IS
  GENERIC (
    width : NATURAL := 4
  );
  PORT (
    A   : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    B   : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    CI  : IN STD_LOGIC;
    SUM : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
    CO  : OUT STD_LOGIC
  );
END DW01_add;

--! @brief Simple unsigned adder for simulation
ARCHITECTURE sim OF DW01_add IS
  SIGNAL unsigned_a : unsigned(width DOWNTO 0);
  SIGNAL unsigned_b : unsigned(width DOWNTO 0);
  SIGNAL temp       : unsigned(width DOWNTO 0);
BEGIN

  unsigned_a <= resize(unsigned(A), unsigned_a'length);
  unsigned_b <= resize(unsigned(B), unsigned_b'length);
  temp       <= unsigned_a + unsigned_b + CI;
  SUM        <= STD_LOGIC_VECTOR(temp(width - 1 DOWNTO 0));
  CO         <= temp(width);

END sim;