-------------------------------------------------------
--! @file MAC_test.vhd
--! @brief MAC n_bit test-kit
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2021-03-12
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
-- Title      : MAC n_bit test-kit
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : MAC_test.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2021-03-12
-- Last update: 2021-03-12
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2021-03-12  1.0      Dimitrios Stathis      Created
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

--! IEEE and work Library
LIBRARY IEEE, work;
--! Use standard library
USE IEEE.std_logic_1164.ALL;
--! Use numeric standard library for arithmetic operations
USE ieee.numeric_std.ALL;
--! Use DPU package
USE work.DPU_pkg.ALL;

--!

--!
ENTITY MAC_nbits IS
  GENERIC (
    width    : NATURAL := 16;
    select_w : NATURAL := 2
  );
  PORT (
    rst_n : IN STD_LOGIC; --! Reset (active-low)
    clk   : IN STD_LOGIC; --! Clock
    A     : IN signed(width - 1 DOWNTO 0);
    B     : IN signed (width - 1 DOWNTO 0);
    conf  : IN STD_LOGIC_VECTOR(select_w - 1 DOWNTO 0);
    O     : OUT signed(width * 2 - 1 DOWNTO 0)
  );
END MAC_nbits;

--! @brief 
--! @details
ARCHITECTURE Struck OF MAC_nbits IS

  CONSTANT SLICES       : NATURAL                        := 2 ** select_w;      --! Number of slices
  CONSTANT SLICE_BITS   : NATURAL                        := (width * 2)/SLICES; --! Slice width for the adder
  CONSTANT MAX_VALUE    : signed(width * 2 - 1 DOWNTO 0) := "01111111111111111111111111111111";
  CONSTANT MIN_VALUE    : signed(width * 2 - 1 DOWNTO 0) := "10000000000000000000000000000000";
  CONSTANT MAX_VALUE_0  : signed(width - 1 DOWNTO 0)     := "0111111111111111";
  CONSTANT MIN_VALUE_0  : signed(width - 1 DOWNTO 0)     := "1000000000000000";
  CONSTANT MAX_VALUE_00 : signed(width / 2 - 1 DOWNTO 0) := "01111111";
  CONSTANT MIN_VALUE_00 : signed(width / 2 - 1 DOWNTO 0) := "10000000";

  TYPE sum_0_ty IS ARRAY (NATURAL RANGE <>) OF signed (SLICE_BITS * 2 DOWNTO 0);
  TYPE sum_00_ty IS ARRAY (NATURAL RANGE <>) OF signed (SLICE_BITS DOWNTO 0);

  SIGNAL mul     : STD_LOGIC_VECTOR(width * 2 - 1 DOWNTO 0);
  SIGNAL sum     : STD_LOGIC_VECTOR(width * 2 - 1 DOWNTO 0);
  SIGNAL acc     : signed(width * 2 - 1 DOWNTO 0);
  SIGNAL SO      : STD_LOGIC_VECTOR(2 ** select_w - 1 DOWNTO 0);
  SIGNAL acc_reg : STD_LOGIC_VECTOR(width * 2 - 1 DOWNTO 0);

BEGIN
  U_mult : ENTITY work.conf_mul_Beh
    GENERIC MAP(
      WIDTH   => WIDTH,
      s_width => select_w
    )
    PORT MAP(
      in_a => STD_LOGIC_VECTOR(A),
      in_b => STD_LOGIC_VECTOR(B),
      conf => conf,
      prod => mul
    );

  -- Accumulator
  U_accumulator : ENTITY work.adder_nbits
    GENERIC MAP(
      width    => width * 2,
      select_w => select_w
    )
    PORT MAP(
      A    => mul,
      B    => acc_reg,
      conf => conf,
      SO   => SO,
      SUM  => sum
    );

  --! Saturation of accumulator output
  saturation : PROCESS (ALL)

    VARIABLE tmp_sum    : signed(width * 2 DOWNTO 0);
    VARIABLE tmp_sum_0  : sum_0_ty(1 DOWNTO 0);
    VARIABLE tmp_sum_00 : sum_00_ty(3 DOWNTO 0);

  BEGIN
    --! Temporary variables  that splits the output of the accumulator
    tmp_sum := signed(SO(3) & sum);

    FOR i IN 0 TO 1 LOOP
      tmp_sum_0(i) := signed(SO(2 * i + 1) & sum((width * (i + 1) - 1) DOWNTO width * i));
    END LOOP;

    FOR i IN 0 TO 3 LOOP
      tmp_sum_00(i) := signed(SO(i) & sum(width/2 * (i + 1) - 1 DOWNTO width/2 * i));
    END LOOP;

    CASE conf IS
      WHEN "00" =>
        --! When configured for normal operation
        IF tmp_sum > MAX_VALUE THEN
          acc <= MAX_VALUE;
        ELSIF tmp_sum < MIN_VAlUE THEN
          acc <= MIN_VAlUE;
        ELSE
          acc <= signed(sum);
        END IF;

      WHEN "01" =>
        --! When configured /2
        FOR i IN 0 TO 1 LOOP
          IF tmp_sum_0(i) > MAX_VALUE_0 THEN
            acc((width * (i + 1) - 1) DOWNTO width * i) <= MAX_VALUE_0;
          ELSIF tmp_sum_0(i) < MIN_VAlUE_0 THEN
            acc((width * (i + 1) - 1) DOWNTO width * i) <= MIN_VAlUE_0;
          ELSE
            acc((width * (i + 1) - 1) DOWNTO width * i) <= signed(sum((width * (i + 1) - 1) DOWNTO width * i));
          END IF;
        END LOOP;

      WHEN "11" =>
        --! When configured to /4
        FOR i IN 0 TO 3 LOOP
          IF tmp_sum_00(i) > MAX_VALUE_00 THEN
            acc(width/2 * (i + 1) - 1 DOWNTO width/2 * i) <= MAX_VALUE_00;
          ELSIF tmp_sum_00(i) < MIN_VAlUE_00 THEN
            acc(width/2 * (i + 1) - 1 DOWNTO width/2 * i) <= MIN_VAlUE_00;
          ELSE
            acc(width/2 * (i + 1) - 1 DOWNTO width/2 * i) <= signed(sum(width/2 * (i + 1) - 1 DOWNTO width/2 * i));
          END IF;
        END LOOP;

      WHEN OTHERS =>
        --! This should never occur 
        acc <= signed(sum);
        NULL;

    END CASE;
  END PROCESS;

  --! Accumulator register
  P_acc_reg : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      acc_reg <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      acc_reg <= STD_LOGIC_VECTOR(acc);
    END IF;
  END PROCESS;

  O <= signed(acc_reg);
END Struck;