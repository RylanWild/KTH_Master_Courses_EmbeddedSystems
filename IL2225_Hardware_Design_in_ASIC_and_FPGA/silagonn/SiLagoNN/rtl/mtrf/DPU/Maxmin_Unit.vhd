-------------------------------------------------------
--! @file Maxmin_Unit.vhd
--! @brief Comparator, takes two inputs and returns a flag (greater, less, or equal) and max or min 
--! @details 
--! @author Guido Baccelli
--! @version 1.0
--! @date 2021-02-16
--! @bug NONE
--! @todo @TODO the unit does not need to do both max and min only one?
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
-- Title      : Comparator, takes two inputs and returns a flag (greater, less, or equal) and max or min 
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : Maxmin_Unit.vhd
-- Author     : Guido Baccelli
-- Company    : KTH
-- Created    : 10/01/2019
-- Last update: 2021-02-16
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2019
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 10/01/2019  1.0      Guido Baccelli          Created
-- 2021-02-16  1.1      Dimitrios Stathis       Updated and optimized
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

--! Standard ieee library
LIBRARY ieee;
--! Default working library
LIBRARY work;
--! Standard logic package
USE ieee.std_logic_1164.ALL;
--! Standard numeric package for signed and unsigned
USE ieee.numeric_std.ALL;
--! Package for CGRA Types and Constants
USE work.DPU_pkg.ALL;
--! Package for misc functions
USE work.util_package.ALL;

--! This module takes two inputs and computes the maximum or minimum between them

--! This module is used to compute max/min DPU operations and to check status conditions given by Sequencer
ENTITY Maxmin_Unit IS
  GENERIC (Nb : INTEGER); --! Number of bits
  PORT (
    in_l            : IN signed(Nb - 1 DOWNTO 0); --! Left-hand side operand
    in_r            : IN signed(Nb - 1 DOWNTO 0); --! Right-hand side operand
    sel_max_min_n   : IN STD_LOGIC;               --! Selection bit: 1 for MAX, 0 for MIN
    seq_cond_status : OUT STD_LOGIC_VECTOR(SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0);
    d_out           : OUT signed(Nb - 1 DOWNTO 0) --! Output of comparison
  );
END ENTITY;

--! @brief Behavioral model for Maxmin Unit
--! @details A simple combinatorial process performs input comparison and outputs the result and the status bits.
ARCHITECTURE bhv OF Maxmin_Unit IS
BEGIN

  --! Process to calculate 
  maxmin_proc : PROCESS (in_l, in_r, sel_max_min_n)
  BEGIN
    --! Default status
    seq_cond_status <= STD_LOGIC_VECTOR(to_unsigned(SEQ_STATUS_LT, seq_cond_status'length));
    --! Default output
    d_out           <= in_r;

    --! Maximum computation
    IF sel_max_min_n = '1' THEN
      --! Maximum operations checks if left operand is greater than right
      IF in_l > in_r THEN
        d_out           <= in_l;
        seq_cond_status <= STD_LOGIC_VECTOR(to_unsigned(SEQ_STATUS_GT, seq_cond_status'length));
      ELSIF in_l = in_r THEN
        seq_cond_status <= STD_LOGIC_VECTOR(to_unsigned(SEQ_STATUS_EQ, seq_cond_status'length));
      ELSE
        seq_cond_status <= STD_LOGIC_VECTOR(to_unsigned(SEQ_STATUS_LT, seq_cond_status'length));
      END IF;
    ELSE
      IF in_l < in_r THEN
        d_out           <= in_l;
        seq_cond_status <= STD_LOGIC_VECTOR(to_unsigned(SEQ_STATUS_LT, seq_cond_status'length));
      ELSIF in_l = in_r THEN
        seq_cond_status <= STD_LOGIC_VECTOR(to_unsigned(SEQ_STATUS_EQ, seq_cond_status'length));
      ELSE
        seq_cond_status <= STD_LOGIC_VECTOR(to_unsigned(SEQ_STATUS_GT, seq_cond_status'length));
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;