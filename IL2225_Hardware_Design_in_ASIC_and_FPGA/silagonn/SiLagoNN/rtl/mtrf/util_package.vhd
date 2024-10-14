-------------------------------------------------------
--! @file util_package.vhd
--! @brief Utility package
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2021-05-26
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
-- Title      : Utility package
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : util_package.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2021-05-26
-- Last update: 2021-05-26
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2021-05-26  1.0      Dimitrios Stathis      Created
-- 2022-09-14  1.1      Dimitrios Stathis      Fixing the overflow issue with
--                                             integer functions (get_min and max_value).
--                                             The problem when a value larger or equal to
--                                             31 is given as input.
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

--! IEEE standard library
LIBRARY ieee;
--! Logic package
USE ieee.std_logic_1164.ALL;
--! Signed and unsigned package
USE ieee.numeric_std.ALL;

--! Utility package, it includes basic arithmetic functions, not synthesizable
PACKAGE util_package IS
  --! This function can be used to calculate the log base 2 function. The result is then rounded up to the highest integer.
  --! \param N : The input value, natural type.
  --! \return Returns a positive integer.
  FUNCTION log2(N               : NATURAL) RETURN POSITIVE;
  --! Return the larger between the two inputs
  --! \param left : input number one, integer
  --! \param right : input number two, integer
  --! \return Returns integer
  FUNCTION max_val(left, right  : INTEGER) RETURN INTEGER;
  --! Returns the min of the two inputs
  --! \param left : input number one, integer
  --! \param right : input number two, integer
  --! \return Returns integer
  FUNCTION min_val(left, right  : INTEGER) RETURN INTEGER;
  --! Returns the maximum value that can be represented by
  --! the given bitwidth. Returns signed.
  --! \param BITWIDTH : Width in bits, natural type
  --! \return Returns signed (same size as BITWIDTH)
  FUNCTION get_max_val(BITWIDTH : NATURAL) RETURN SIGNED;
  --! Returns the minimum value that can be represented by
  --! the given bitwidth. Returns signed.
  --! \param BITWIDTH : Width in bits, natural type
  --! \return Returns signed (same size as BITWIDTH)
  FUNCTION get_min_val(BITWIDTH : NATURAL) RETURN SIGNED;
  --! This function returns m/n rounded up
  --! \param m : Dividend input number, integer type.
  --! \param n : Divisor input number, integer type.
  --! \return Returns an integer
  FUNCTION divUp (m : INTEGER; n : INTEGER) RETURN INTEGER;
  --! This function returns m/n rounded down
  --! \param m : Dividend input number, integer type.
  --! \param n : Divisor input number, integer type.
  --! \return Returns an integer
  FUNCTION divDown (m : INTEGER; n : INTEGER) RETURN INTEGER;
  --! This function saturates numbers to the max or min value
  --! \param A : input (signed)
  --! \param MAX_VALUE : Maximum possible value (signed)
  --! \param MIN_VALUE : Minimum possible value (signed)
  --! \return Returns a signed number, same size as the MAX_VALUE bitwidth
  FUNCTION saturation(A : signed; MAX_VALUE : signed; MIN_VALUE : signed) RETURN signed;
  --! This function saturates numbers to the max or min value
  --! \param A : input (integer)
  --! \param MAX_VALUE : Maximum possible value (signed)
  --! \param MIN_VALUE : Minimum possible value (signed)
  --! \return Returns a signed number, same size as the MAX_VALUE bitwidth
  FUNCTION saturation(A : INTEGER; MAX_VALUE : signed; MIN_VALUE : signed) RETURN signed;

END util_package;

PACKAGE BODY util_package IS

  FUNCTION log2(N : NATURAL) RETURN POSITIVE IS
  BEGIN
    IF N <= 2 THEN
      RETURN 1;
    ELSE
      RETURN 1 + log2(N/2);
    END IF;
  END;

  FUNCTION max_val (left, right : INTEGER)
    RETURN INTEGER IS
  BEGIN -- max
    IF left > right THEN
      RETURN left;
    ELSE
      RETURN right;
    END IF;
  END max_val;

  FUNCTION min_val (left, right : INTEGER)
    RETURN INTEGER IS
  BEGIN -- min
    IF left < right THEN
      RETURN left;
    ELSE
      RETURN right;
    END IF;
  END min_val;

  ----------------------------------------------------
  -- REV 1.1 2022-09-14 ------------------------------
  ----------------------------------------------------
  -- Changed the functions from integer (limited 32 bit) to signed to avoid overflow problems.
  -- We change the way we calculate the max and min value, from the mathematical expression:
  -- 2**(BITWIDTH-1)-1 and -2**(BITWIDTH-1) to the logic expression for max and miv values
  -- in 2's compliment representation.

  FUNCTION get_max_val (BITWIDTH : NATURAL)
    RETURN SIGNED IS
    VARIABLE bitwidth_s : SIGNED(BITWIDTH - 2 DOWNTO 0);
    VARIABLE rtn_s      : SIGNED(BITWIDTH - 1 DOWNTO 0);
  BEGIN
    bitwidth_s := (OTHERS => '1');
    rtn_s      := '0' & bitwidth_s;
    RETURN rtn_s;
  END get_max_val;

  FUNCTION get_min_val (BITWIDTH : NATURAL)
    RETURN SIGNED IS
    VARIABLE bitwidth_s : SIGNED(BITWIDTH - 2 DOWNTO 0);
    VARIABLE rtn_s      : SIGNED(BITWIDTH - 1 DOWNTO 0);
  BEGIN
    bitwidth_s := (OTHERS => '0');
    rtn_s      := '1' & bitwidth_s;
    RETURN rtn_s;
  END get_min_val;

  ----------------------------------------------------
  -- End of modification REV 1.1 ---------------------
  ----------------------------------------------------

  --! This function returns m/n rounded up
  FUNCTION divUp (m : INTEGER; n : INTEGER) RETURN INTEGER IS
  BEGIN
    IF (m MOD n /= 0) THEN
      RETURN ((m/n) + 1);
    ELSE
      RETURN (m/n);
    END IF;
  END divUp;

  --! This function returns m/n rounded down
  FUNCTION divDown (m : INTEGER; n : INTEGER) RETURN INTEGER IS
  BEGIN
    IF (m MOD n /= 0) THEN
      RETURN (m/n);
    ELSE
      RETURN (m/n);
    END IF;
  END divDown;

  FUNCTION saturation(A : signed; MAX_VALUE : signed; MIN_VALUE : signed) RETURN signed IS
    VARIABLE tmp_out : signed(MAX_VALUE'length - 1 DOWNTO 0);
  BEGIN
    IF A >= MAX_VALUE THEN
      tmp_out := MAX_VALUE;
    ELSIF A <= MIN_VALUE THEN
      tmp_out := MIN_VALUE;
    ELSE
      tmp_out := resize(A, tmp_out'length);
    END IF;
    RETURN tmp_out;
  END FUNCTION;

  FUNCTION saturation(A : INTEGER; MAX_VALUE : signed; MIN_VALUE : signed) RETURN signed IS
    VARIABLE tmp_out : signed(MAX_VALUE'length - 1 DOWNTO 0);
  BEGIN
    IF A >= MAX_VALUE THEN
      tmp_out := MAX_VALUE;
    ELSIF A <= MIN_VALUE THEN
      tmp_out := MIN_VALUE;
    ELSE
      tmp_out := to_signed(A, tmp_out'length);
    END IF;
    RETURN tmp_out;
  END FUNCTION;

END;