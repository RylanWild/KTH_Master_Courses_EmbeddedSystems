-------------------------------------------------------
--! @file Saturation_Unit.vhd
--! @brief Saturation Unit for use inside DPU
--! @details 
--! @author Guido Baccelli
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
-- Title      : Saturation Unit for use inside DPU
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : Saturation_Unit.vhd
-- Author     : Guido Baccelli
-- Company    : KTH
-- Created    : 11/01/2019
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
-- 11/01/2019  1.0      Guido Baccelli          Created
-- 2021-05-26  2.0      Dimitrios Stathis       The module is re-written to
--                                              saturate numbers with reconfigurable
--                                              bitwidth.
-- 2022-09-14  2.1      Dimitrios Stathis       Fixed the get_min and max_value overflow error
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
--! Package for DPU types and constants
USE work.DPU_pkg.ALL;
--! Utilities package
USE work.util_package.ALL;

--! This module saturates the input to the max/min representable numbers in output

--! The module gets as input the output of the accumulator and the carry out.
--! Both the output and the carry from the accumulator come in the form of
--! slices. The slices can be combined or used as is depending on the 
--! configuration. In this version we assume that the input and output has
--! the same width, the saturation happens due to the carry output of the
--! adder. It should work for any combination of input output widths, as
--! long as the input width is larger compared to the output (but it is 
--! not tested).
--! !!!NOTE!!! This unit is used for the full saturate the result of the accumulator
--! only, the input is the full size of the accumulator and the carry bits from the 
--! accumulator.
ENTITY Saturation_Unit IS

  PORT (
    d_in   : IN STD_LOGIC_VECTOR(SAT_IN_BITS - 1 DOWNTO 0);   --! Input data
    carry  : IN STD_LOGIC_VECTOR(ADD_C_W - 1 DOWNTO 0);       --! Input carry from accumulator/adder
    d_mode : IN STD_LOGIC_VECTOR(SAT_CONF_BITS - 1 DOWNTO 0); --! Opcode 
    d_out  : OUT STD_LOGIC_VECTOR(SAT_OUT_BITS - 1 DOWNTO 0)  --! Output data
  );
END ENTITY;

--! @brief Behavioral description with combinatorial process
--! @details The saturation unit breaks down the input to slices,
--! combined with the appropriate carry bits. Then it saturates the
--! output accordingly. Important, we do not round in this stage.
--! The saturation unit only considers the dynamic range, not 
--! the resolution (all the numbers are treated as integer values).
ARCHITECTURE bhv OF Saturation_Unit IS

  ----------------------------------------------------
  -- REV 2.1 2022-09-14 ------------------------------
  ----------------------------------------------------
  -- Changed the functions from integer (limited 32 bit) to signed to avoid overflow problems.

  --! Max value in signed form for full saturation
  CONSTANT MAX_VALUE    : signed(SAT_OUT_BITS - 1 DOWNTO 0)    := MAX_FULL_SAT;--, SAT_OUT_BITS);
  --! Min value in signed form for full saturation;--
  CONSTANT MIN_VALUE    : signed(SAT_OUT_BITS - 1 DOWNTO 0)    := MIN_FULL_SAT;--, SAT_OUT_BITS);
  --! Max value in signed form for /2 saturation
  CONSTANT MAX_VALUE_0  : signed(SAT_SLICE_BIT_2 - 1 DOWNTO 0) := MAX_2_SAT;--, SAT_SLICE_BIT_2);
  --! Min value in signed form for /2 saturation 
  CONSTANT MIN_VALUE_0  : signed(SAT_SLICE_BIT_2 - 1 DOWNTO 0) := MIN_2_SAT;--, SAT_SLICE_BIT_2);
  --! Max value in signed form for /4 saturation
  CONSTANT MAX_VALUE_00 : signed(SAT_SLICE_BIT_4 - 1 DOWNTO 0) := MAX_4_SAT;--, SAT_SLICE_BIT_4);
  --! Min value in signed form for /4 saturation
  CONSTANT MIN_VALUE_00 : signed(SAT_SLICE_BIT_4 - 1 DOWNTO 0) := MIN_4_SAT;--, SAT_SLICE_BIT_4);
  ----------------------------------------------------
  -- End of modification REV 2.1 ---------------------
  ----------------------------------------------------

BEGIN

  --! Saturation of accumulator output
  saturation : PROCESS (ALL)
    --! Full input (accumulator result including the carry)
    VARIABLE tmp_sum    : signed(SAT_OUT_BITS DOWNTO 0);
    --! Two slices for /2 bitwidth (including the carry in each slice)
    VARIABLE tmp_sum_0  : sum_0_ty(1 DOWNTO 0);
    --! Four slices for /4 bitwidth (including the carry in each slice)
    VARIABLE tmp_sum_00 : sum_00_ty(3 DOWNTO 0);

  BEGIN
    --! Temporary variables  that splits the output of the accumulator
    tmp_sum := signed(carry(3) & d_in);

    FOR i IN 0 TO 1 LOOP
      tmp_sum_0(i) := signed(carry(2 * i + 1) & d_in((SAT_SLICE_BIT_2 * (i + 1) - 1) DOWNTO SAT_SLICE_BIT_2 * i));
    END LOOP;

    FOR i IN 0 TO 3 LOOP
      tmp_sum_00(i) := signed(carry(i) & d_in(SAT_SLICE_BIT_4 * (i + 1) - 1 DOWNTO SAT_SLICE_BIT_4 * i));
    END LOOP;

    CASE d_mode IS
      WHEN "00" =>
        --! When configured for normal operation
        IF tmp_sum > MAX_VALUE THEN
          d_out <= STD_LOGIC_VECTOR(MAX_VALUE);
        ELSIF tmp_sum < MIN_VAlUE THEN
          d_out <= STD_LOGIC_VECTOR(MIN_VAlUE);
        ELSE
          d_out <= d_in;
        END IF;

      WHEN "01" =>
        --! When configured /2
        FOR i IN 0 TO 1 LOOP
          IF tmp_sum_0(i) > MAX_VALUE_0 THEN
            d_out((SAT_SLICE_BIT_2 * (i + 1) - 1) DOWNTO SAT_SLICE_BIT_2 * i) <= STD_LOGIC_VECTOR(MAX_VALUE_0);
          ELSIF tmp_sum_0(i) < MIN_VAlUE_0 THEN
            d_out((SAT_SLICE_BIT_2 * (i + 1) - 1) DOWNTO SAT_SLICE_BIT_2 * i) <= STD_LOGIC_VECTOR(MIN_VAlUE_0);
          ELSE
            d_out((SAT_SLICE_BIT_2 * (i + 1) - 1) DOWNTO SAT_SLICE_BIT_2 * i) <= d_in((SAT_SLICE_BIT_2 * (i + 1) - 1) DOWNTO SAT_SLICE_BIT_2 * i);
          END IF;
        END LOOP;

      WHEN "11" =>
        --! When configured to /4
        FOR i IN 0 TO 3 LOOP
          IF tmp_sum_00(i) > MAX_VALUE_00 THEN
            d_out(SAT_SLICE_BIT_4 * (i + 1) - 1 DOWNTO SAT_SLICE_BIT_4 * i) <= STD_LOGIC_VECTOR(MAX_VALUE_00);
          ELSIF tmp_sum_00(i) < MIN_VAlUE_00 THEN
            d_out(SAT_SLICE_BIT_4 * (i + 1) - 1 DOWNTO SAT_SLICE_BIT_4 * i) <= STD_LOGIC_VECTOR(MIN_VAlUE_00);
          ELSE
            d_out(SAT_SLICE_BIT_4 * (i + 1) - 1 DOWNTO SAT_SLICE_BIT_4 * i) <= d_in(SAT_SLICE_BIT_4 * (i + 1) - 1 DOWNTO SAT_SLICE_BIT_4 * i);
          END IF;
        END LOOP;

      WHEN OTHERS =>
        --! This should never occur 
        d_out <= d_in;

    END CASE;
  END PROCESS;

END ARCHITECTURE;