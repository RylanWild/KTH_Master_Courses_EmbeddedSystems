-------------------------------------------------------
--! @file twos_compl.vhd
--! @brief Negation using two's compliment
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2021-02-16
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
-- Title      : Negation using two's compliment
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : twos_compl.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2021-02-16
-- Last update: 2021-02-16
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2021-02-16  1.0      Dimitrios Stathis      Created
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

--! This module performs 2's complement

--! After 2's complement computation, saturation is needed because 
--! the representation interval for 2's complement signed numbers is not symmetric: 
--! the lowest number -2^(Nb-1) can be represented on 'Nb' bits, but its 2's complement
--! 2^(Nb-1) cannot. In case of -2^(Nb-1), the 2's complement is saturated to 2^(Nb-1)-1.
ENTITY twos_compl IS
  GENERIC (b_width : INTEGER := 16); --! Number of bits
  PORT (
    d_in  : IN signed(b_width - 1 DOWNTO 0); --! Input data
    d_out : OUT signed(b_width - 1 DOWNTO 0) --! Output data
  );
END ENTITY;

--! @brief Compute the 2's compliment by inverting input and adding '1'
--! @details The 2's compliment is computed using the inverted input and adding '1'.
--! If the result extend the accepted range we assign the maximum number to the output.
ARCHITECTURE bhv OF twos_compl IS

  CONSTANT max_integer : INTEGER                      := 2 ** (b_width - 1) - 1;
  CONSTANT max_num_out : signed(b_width - 1 DOWNTO 0) := to_signed(max_integer, b_width);

BEGIN

  twoscompl : PROCESS (d_in)
    VARIABLE temp     : STD_LOGIC_VECTOR(b_width DOWNTO 0);
    VARIABLE Y        : STD_LOGIC_VECTOR(b_width DOWNTO 0);
    VARIABLE overflow : STD_LOGIC;
  BEGIN

    temp(b_width - 1 DOWNTO 0) := STD_LOGIC_VECTOR(d_in);
    temp(b_width)              := d_in(b_width - 1);
    temp                       := NOT temp;
    Y                          := STD_LOGIC_VECTOR(unsigned(temp) + 1);
    overflow                   := (NOT Y(b_width)) AND Y(b_width - 1);
    IF overflow = '0' THEN
      d_out <= signed(Y(b_width - 1 DOWNTO 0));
    ELSE
      d_out <= max_num_out;
    END IF;

  END PROCESS;

END ARCHITECTURE;