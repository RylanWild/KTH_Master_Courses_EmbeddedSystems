-------------------------------------------------------
--! @file Sat_n_round.vhd
--! @brief Saturation and rounding unit
--! @details This unit operates on the expanded results of the
--! internal accumulate register and turns it back to the 16-bit standard output.
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2021-06-18
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
-- Title      : Saturation and rounding unit
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : Sat_n_round.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2021-06-18
-- Last update: 2021-06-18
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2021-06-18  1.0      Dimitrios Stathis       Created
-- 2022-09-14  1.1      Dimitrios Stathis       Fixed back with overflow in the
--                                              get_max and min_value functions.
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
LIBRARY IEEE, work;
--! Use standard library
USE IEEE.std_logic_1164.ALL;
--! Use numeric standard library for arithmetic operations
USE ieee.numeric_std.ALL;
--! USE DPU package
USE work.DPU_pkg.ALL;
--! Use utility package
USE work.util_package.ALL;
--! This unit can be used to saturate when integer, or saturate and round when we deal with fixed-point

--! The input of this unit is a full range S_DPU_OUT_WIDTH-bit vector and depending on the configuration the unit will
--! give a DPU_OUT_WIDTH-bit vector that will drive the output.
ENTITY Sat_n_round IS
  PORT (
    d_in    : IN STD_LOGIC_VECTOR(S_DPU_OUT_WIDTH - 1 DOWNTO 0);   --! Input data vector
    op_mode : IN unsigned(S_DPU_CFG_WIDTH - 1 DOWNTO 0);           --! Operation mode configuration for the sub-dpu
    d_mode  : IN STD_LOGIC_VECTOR(DPU_OP_CONF_WIDTH - 1 DOWNTO 0); --! DPU operation control 16-Int, 16-FP, 8-Int, 4-Int
    d_out   : OUT STD_LOGIC_VECTOR(DPU_OUT_WIDTH - 1 DOWNTO 0)     --! Output data vector
  );
END Sat_n_round;

--! @brief The saturation and rounding unit is used to turn an S_DPU_OUT_WIDTH-bit and turn it to a DPU_OUT_WIDTH-bit vector
--! @details The input data vector is can be either one integer number, or 2, or 4 numbers concatenated in one vector.
--! Sxxx x.xxx xxxx xxxx
--! Sxxx xx-xxx x.xxx xxxx xxxx-xxx xxxx xxxx 
ARCHITECTURE RTL OF Sat_n_round IS
  -------------------------------------------------------------------------------------------------
  -- Max and min values for the output of the saturation/rounding
  -------------------------------------------------------------------------------------------------
  --! Saturation output bitwidth
  CONSTANT OUT_BITS            : NATURAL                              := DPU_OUT_WIDTH;
  --! Saturation slices bitwidth (/2)
  CONSTANT OUT_SLICE_BIT_2     : NATURAL                              := OUT_BITS/2;
  --! Saturation slices bitwidth (/4)
  CONSTANT OUT_SLICE_BIT_4     : NATURAL                              := OUT_BITS/4;

  ----------------------------------------------------
  -- REV 1.1 2022-09-14 ------------------------------
  ----------------------------------------------------
  -- Changed the functions from integer (limited 32 bit) to signed to avoid overflow problems.
  --! Max value for full bitwidth
  CONSTANT DPU_OUT_MAX_VALUE   : SIGNED(OUT_BITS - 1 DOWNTO 0)        := get_max_val(OUT_BITS);
  --! Min value for full bitwidth
  CONSTANT DPU_OUT_MIN_VALUE   : SIGNED(OUT_BITS - 1 DOWNTO 0)        := get_min_val(OUT_BITS);
  --! Max value for /2 bitwidth
  CONSTANT DPU_OUT_MAX_VALUE_2 : SIGNED(OUT_SLICE_BIT_2 - 1 DOWNTO 0) := get_max_val(OUT_SLICE_BIT_2);
  --! Min value for /2 bitwidth
  CONSTANT DPU_OUT_MIN_VALUE_2 : SIGNED(OUT_SLICE_BIT_2 - 1 DOWNTO 0) := get_min_val(OUT_SLICE_BIT_2);
  --! Max value for /4 bitwidth
  CONSTANT DPU_OUT_MAX_VALUE_4 : SIGNED(OUT_SLICE_BIT_4 - 1 DOWNTO 0) := get_max_val(OUT_SLICE_BIT_4);
  --! Min value for /4 bitwidth
  CONSTANT DPU_OUT_MIN_VALUE_4 : SIGNED(OUT_SLICE_BIT_4 - 1 DOWNTO 0) := get_min_val(OUT_SLICE_BIT_4);

  --! Max value in signed form for full saturation
  CONSTANT MAX_VALUE           : signed(DPU_OUT_WIDTH - 1 DOWNTO 0)   := DPU_OUT_MAX_VALUE;
  --! Min value in signed form for full saturation
  CONSTANT MIN_VALUE           : signed(DPU_OUT_WIDTH - 1 DOWNTO 0)   := DPU_OUT_MIN_VALUE;
  --! Max value in signed form for /2 saturation
  CONSTANT MAX_VALUE_0         : signed(DPU_OUT_WIDTH/2 - 1 DOWNTO 0) := DPU_OUT_MAX_VALUE_2;
  --! Min value in signed form for /2 saturation 
  CONSTANT MIN_VALUE_0         : signed(DPU_OUT_WIDTH/2 - 1 DOWNTO 0) := DPU_OUT_MIN_VALUE_2;
  --! Max value in signed form for /4 saturation
  CONSTANT MAX_VALUE_00        : signed(DPU_OUT_WIDTH/4 - 1 DOWNTO 0) := DPU_OUT_MAX_VALUE_4;
  --! Min value in signed form for /4 saturation
  CONSTANT MIN_VALUE_00        : signed(DPU_OUT_WIDTH/4 - 1 DOWNTO 0) := DPU_OUT_MIN_VALUE_4;
  ----------------------------------------------------
  -- End of modification REV 1.1 ---------------------
  ----------------------------------------------------

  -------------------------------------------------------------------------------------------------
  -- Bit slices of the nacu
  -------------------------------------------------------------------------------------------------
  --! Adder slices type /2
  TYPE tmp_0_ty IS ARRAY (NATURAL RANGE <>) OF signed (SAT_SLICE_BIT_2 - 1 DOWNTO 0);
  --! Adder slices type /4
  TYPE tmp_00_ty IS ARRAY (NATURAL RANGE <>) OF signed (SAT_SLICE_BIT_4 - 1 DOWNTO 0);

  CONSTANT ROUNDED_BIT : POSITIVE := 1 + 2 * ib + fb;

BEGIN

  --! Saturation of accumulator output
  saturation : PROCESS (ALL)
    --! Full input (accumulator result including the carry)
    VARIABLE tmp_sum    : signed(S_DPU_OUT_WIDTH - 1 DOWNTO 0);
    --! Two slices for /2 bitwidth (including the carry in each slice)
    VARIABLE tmp_sum_0  : tmp_0_ty(1 DOWNTO 0);
    --! Four slices for /4 bitwidth (including the carry in each slice)
    VARIABLE tmp_sum_00 : tmp_00_ty(3 DOWNTO 0);
    --! Rounded number when using Q-format
    VARIABLE round      : signed(ROUNDED_BIT - 1 DOWNTO 0);

  BEGIN
    --! Temporary variables  that splits the output of the accumulator
    tmp_sum := signed(d_in);

    FOR i IN 0 TO 1 LOOP
      tmp_sum_0(i) := signed(d_in((SAT_SLICE_BIT_2 * (i + 1) - 1) DOWNTO SAT_SLICE_BIT_2 * i));
    END LOOP;

    FOR i IN 0 TO 3 LOOP
      tmp_sum_00(i) := signed(d_in(SAT_SLICE_BIT_4 * (i + 1) - 1 DOWNTO SAT_SLICE_BIT_4 * i));
    END LOOP;

    round := signed(d_in(S_DPU_OUT_WIDTH - 1 DOWNTO fb + 1));

    CASE d_mode IS
      WHEN "00" =>
        -- When configured for normal operation
        IF tmp_sum > MAX_VALUE THEN
          d_out <= STD_LOGIC_VECTOR(MAX_VALUE);
        ELSIF tmp_sum < MIN_VAlUE THEN
          d_out <= STD_LOGIC_VECTOR(MIN_VAlUE);
        ELSE
          d_out <= d_in(DPU_OUT_WIDTH - 1 DOWNTO 0);
        END IF;

      WHEN "10" =>
        -- When configured for Q4.11 format
        IF (to_integer(op_mode) = S_MUL) OR (to_integer(op_mode) = S_MAC) THEN
          -- When the mode is configured for something that contains a multiplication
          -- Multiplication leads to Sxxx xx-xxx x.xxx xxxx xxxx-xxx xxxx xxxx format
          IF round > MAX_VALUE THEN
            d_out <= STD_LOGIC_VECTOR(MAX_VALUE);
          ELSIF round < MIN_VAlUE THEN
            d_out <= STD_LOGIC_VECTOR(MIN_VAlUE);
          ELSE
            d_out <= STD_LOGIC_VECTOR(round(DPU_OUT_WIDTH - 1 DOWNTO 0));
          END IF;
        ELSE
          -- When mode does not include multiplication then the result is of the format
          -- Sx-xxx x.xxx xxxx xxxx, so no need for rounding just saturation
          IF tmp_sum > MAX_VALUE THEN
            d_out <= STD_LOGIC_VECTOR(MAX_VALUE);
          ELSIF tmp_sum < MIN_VAlUE THEN
            d_out <= STD_LOGIC_VECTOR(MIN_VAlUE);
          ELSE
            d_out <= d_in(DPU_OUT_WIDTH - 1 DOWNTO 0);
          END IF;
        END IF;

      WHEN "01" =>
        -- When configured /2
        FOR i IN 0 TO 1 LOOP
          IF tmp_sum_0(i) > MAX_VALUE_0 THEN
            d_out((OUT_SLICE_BIT_2 * (i + 1) - 1) DOWNTO OUT_SLICE_BIT_2 * i) <= STD_LOGIC_VECTOR(MAX_VALUE_0);
          ELSIF tmp_sum_0(i) < MIN_VAlUE_0 THEN
            d_out((OUT_SLICE_BIT_2 * (i + 1) - 1) DOWNTO OUT_SLICE_BIT_2 * i) <= STD_LOGIC_VECTOR(MIN_VAlUE_0);
          ELSE
            d_out((OUT_SLICE_BIT_2 * (i + 1) - 1) DOWNTO OUT_SLICE_BIT_2 * i) <= d_in((OUT_SLICE_BIT_2 * (i + 1) - 1) DOWNTO OUT_SLICE_BIT_2 * i);
          END IF;
        END LOOP;

      WHEN "11" =>
        -- When configured to /4
        FOR i IN 0 TO 3 LOOP
          IF tmp_sum_00(i) > MAX_VALUE_00 THEN
            d_out(OUT_SLICE_BIT_4 * (i + 1) - 1 DOWNTO OUT_SLICE_BIT_4 * i) <= STD_LOGIC_VECTOR(MAX_VALUE_00);
          ELSIF tmp_sum_00(i) < MIN_VAlUE_00 THEN
            d_out(OUT_SLICE_BIT_4 * (i + 1) - 1 DOWNTO OUT_SLICE_BIT_4 * i) <= STD_LOGIC_VECTOR(MIN_VAlUE_00);
          ELSE
            d_out(OUT_SLICE_BIT_4 * (i + 1) - 1 DOWNTO OUT_SLICE_BIT_4 * i) <= d_in(OUT_SLICE_BIT_4 * (i + 1) - 1 DOWNTO OUT_SLICE_BIT_4 * i);
          END IF;
        END LOOP;

      WHEN OTHERS =>
        -- This should never occur 
        d_out <= d_in(DPU_OUT_WIDTH - 1 DOWNTO 0);

    END CASE;
  END PROCESS;
END RTL;