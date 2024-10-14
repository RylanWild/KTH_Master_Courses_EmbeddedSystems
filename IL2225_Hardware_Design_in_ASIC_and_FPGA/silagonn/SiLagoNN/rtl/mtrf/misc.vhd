-------------------------------------------------------
--! @file misc.vhd
--! @brief Miscellaneous package
--! @details
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2019-10-11
--! @bug NONE
--! @todo Remove the multiple log2 functions, keep only one.
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
-- Title      : miscellaneous
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : misc.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2019-10-11
-- Last update: 2019-10-11
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2019
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2019-10-11  1.0      Dimitrios Stathis      Created
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

--! @brief This is a miscellaneous package. 
--! @details The misc package contains a variety of functions that
--! are mainly used for calculation of constants and bit level
--! functions. This a new package created to combine and replace
--! previous packages that had similar/duplicate functions.
--! \verbatim
--! Packages replaced:
--!   - misc
--!   - util_package
--!   - functions 
--! \endverbatim
PACKAGE misc IS
    --! This function can be used to calculate the log base 2 function. The result is then rounded up to the highest integer.
    --! \param N : The input value, natural type.
    --! \return Returns a positive integer.
    FUNCTION log2_ceil(N          : NATURAL) RETURN POSITIVE;
    --! This function transform a bit vector to its base 10 natural equivalent.
    --! \param B : The input binary number, bit_vector.
    --! \return Returns a natural number.
    FUNCTION b2n (B               : BIT_VECTOR) RETURN NATURAL;
    --! This function transforms a natural number to bit vector.
    --! \param nat : The input number, natural type.
    --! \param length : The length/bitwidth of the resulting bit vector, natural type.
    --! \return Returns the resulting bit_vector with the specified bitwidth.
    FUNCTION n2b (nat : IN NATURAL; length : IN NATURAL) RETURN BIT_VECTOR;
    --! This function can be used to calculate the log base 2 function. This is a different implementation of the log2_ceil function, is kept for back-compatibility, should be removed and only one function kept.
    --! \param i : The input value, natural type.
    --! \return Returns a positive integer.
    FUNCTION log2 (i              : NATURAL) RETURN INTEGER;
    --! This function returns the max of two values.
    --! \param left : First input number, integer type.
    --! \param right : second input number, integer type.
    --! \return Returns an integer
    FUNCTION max_val (left, right : INTEGER) RETURN INTEGER;
    --! This function returns the min of two values.
    --! \param left : First input number, integer type.
    --! \param right : second input number, integer type.
    --! \return Returns an integer
    FUNCTION min_val (left, right : INTEGER) RETURN INTEGER;
END;
PACKAGE BODY misc IS

    FUNCTION log2_ceil(N : NATURAL) RETURN POSITIVE IS
    BEGIN
        IF N <= 2 THEN
            RETURN 1;
        ELSE
            RETURN 1 + log2_ceil(N/2);
        END IF;
    END;

    FUNCTION b2n (B : BIT_VECTOR) RETURN NATURAL IS
        VARIABLE S      : BIT_VECTOR(B'LENGTH - 1 DOWNTO 0) := B;
        VARIABLE N      : NATURAL                           := 0;
    BEGIN
        FOR i IN S'RIGHT TO S'LEFT LOOP
            IF S(i) = '1' THEN
                N := N + (2 ** i);
            END IF;
        END LOOP;
        RETURN N;
    END;

    FUNCTION n2b (nat : IN NATURAL; length : IN NATURAL) RETURN BIT_VECTOR IS
        VARIABLE temp   : NATURAL                         := nat;
        VARIABLE result : BIT_VECTOR(length - 1 DOWNTO 0) := (OTHERS => '0');
    BEGIN
        FOR index IN result'REVERSE_RANGE LOOP
            result(index) := BIT'VAL(temp REM 2);
            temp          := temp / 2;
            EXIT WHEN temp = 0;
        END LOOP;
        RETURN result;
    END n2b;

    FUNCTION log2(i : NATURAL) RETURN INTEGER IS
        VARIABLE tmp    : real    := real(i);
        VARIABLE ret    : INTEGER := 0;
    BEGIN
        WHILE tmp > 1.0 LOOP
            ret := ret + 1;   --accumulates until tmp > 1
            tmp := tmp / 2.0; --divides current tmp by to to store
            --the remainder in tmp
        END LOOP;
        RETURN ret;
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
    BEGIN -- max
        IF left < right THEN
            RETURN left;
        ELSE
            RETURN right;
        END IF;
    END min_val;
END;