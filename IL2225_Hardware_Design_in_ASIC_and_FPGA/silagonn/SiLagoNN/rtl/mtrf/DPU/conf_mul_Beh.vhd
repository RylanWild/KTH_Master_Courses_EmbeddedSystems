-------------------------------------------------------
--! @file conf_mul_Beh.vhd
--! @brief Reconfigurable precision signed multiplier
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2020-12-07
--! @bug NONE
--! @todo Check the calculation of "add_11_c00" it is possible that we should use unsigned addition without extension of the sign for the carry bits
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
-- Title      : Reconfigurable precision signed multiplier
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : conf_mul_Beh.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2020-12-07
-- Last update: 2020-12-07
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2020
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2020-12-07  1.0      Dimitrios Stathis      Created
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
USE IEEE.numeric_std.ALL;
--! Use misc package for utility functions
USE work.util_package.ALL;

--! This is a reconfigurable multiplier. It can operate in different fixed point precision.

--! The input of the multiplier is a N-bit bit stream. The stream can be treated as a N-bit signed 
--! number, two N/2-bit signed numbers, or four N/4-bit signed numbers. The output is a 2N-bit bit stream.
--! The output is splitted in one, two, or four, depending on the configuration.
ENTITY conf_mul_Beh IS
  GENERIC (
    WIDTH   : NATURAL := 8; --! Input WIDTH (N)
    s_width : NATURAL := 1  --! Width of the select signals
  );
  PORT (
    in_a : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);     --! Input A, N-bit
    in_b : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);     --! Input B, N-bit
    conf : IN STD_LOGIC_VECTOR(s_width - 1 DOWNTO 0);   --! Configuration bits, define the multiplication, 00 -> full N multiplication, 01 -> N/2 multiplication, 11 -> N/4 multiplication
    prod : OUT STD_LOGIC_VECTOR(2 * WIDTH - 1 DOWNTO 0) --! Product output, 2N-bit
  );
END ENTITY conf_mul_Beh;

--! @brief This is the architecture of a reconfigurable multiplier (16-bit)
--! @details In this version we are using a shift and ADD architecture instead of the
--! conventional array multiplier, the multiplication is decomposed in to 4 smaller
--! multipliers. The products of the smaller multiplication are shifted and then added
--! to generate the final result. A sign extension is used to switch between the two modes.
--! The smallest possible is 8-bit multiplication that can be splitted in 2x4 bit multiplication.
ARCHITECTURE rtl OF conf_mul_Beh IS

  --! Component deceleration for recursion
  COMPONENT conf_mul_Beh IS
    GENERIC (
      WIDTH   : NATURAL; --! Input WIDTH (N)
      s_width : NATURAL  --! Width of the select signals
    );
    PORT (
      in_a : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);     --! Input A, N-bit
      in_b : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);     --! Input B, N-bit
      conf : IN STD_LOGIC_VECTOR(s_width - 1 DOWNTO 0);   --! Configuration bits, define the multiplication, 00 -> full N multiplication, 01 -> N/2 multiplication, 11 -> N/4 multiplication
      prod : OUT STD_LOGIC_VECTOR(2 * WIDTH - 1 DOWNTO 0) --! Product output, 2N-bit
    );
  END COMPONENT;

  CONSTANT WIDTH_L    : NATURAL := divDown(WIDTH, 2);             --! Constant value for Width of the upper half
  CONSTANT WIDTH_H    : NATURAL := divUp(WIDTH, 2);               --! Constant value for Width of the lower half
  CONSTANT WIDTH_00   : NATURAL := 2 * (WIDTH_L + 1);             --! Constant value for width of the 00 partial product (plus 1 for the sign extension)
  CONSTANT WIDTH_01   : NATURAL := WIDTH_L + 1 + WIDTH_H;         --! Constant value for width of the 01 partial product
  CONSTANT WIDTH_10   : NATURAL := WIDTH_L + 1 + WIDTH_H;         --! Constant value for width of the 10 partial product
  CONSTANT WIDTH_11   : NATURAL := 2 * WIDTH_H;                   --! Constant value for width of the 11 partial product

  SIGNAL temp_a1      : signed(WIDTH_H - 1 DOWNTO 0);             --! MSBs of A
  SIGNAL temp_a0      : signed(WIDTH_L DOWNTO 0);                 --! LSBs of A
  SIGNAL temp_b1      : signed(WIDTH_H - 1 DOWNTO 0);             --! MSBs of B
  SIGNAL temp_b0      : signed(WIDTH_L DOWNTO 0);                 --! LSBs of B

  SIGNAL in_mul_00_a  : signed(WIDTH_L DOWNTO 0);                 --! Input A to the 00 multiplier
  SIGNAL in_mul_00_b  : signed(WIDTH_L DOWNTO 0);                 --! Input B to the 00 multiplier

  SIGNAL in_mul_01_a  : signed(WIDTH_H - 1 DOWNTO 0);             --! Input A to the 01 multiplier
  SIGNAL in_mul_01_b  : signed(WIDTH_L DOWNTO 0);                 --! Input B to the 01 multiplier

  SIGNAL in_mul_10_a  : signed(WIDTH_L DOWNTO 0);                 --! Input A to the 10 multiplier
  SIGNAL in_mul_10_b  : signed(WIDTH_H - 1 DOWNTO 0);             --! Input B to the 10 multiplier

  SIGNAL in_mul_11_a  : signed(WIDTH_H - 1 DOWNTO 0);             --! Input A to the 11 multiplier
  SIGNAL in_mul_11_b  : signed(WIDTH_H - 1 DOWNTO 0);             --! Input B to the 11 multiplier

  SIGNAL temp_m       : signed(2 * WIDTH - 1 DOWNTO 0);           --! Product of the full width multiplication
  SIGNAL temp_m00     : signed(WIDTH_00 - 1 DOWNTO 0);            --! Partial product of the 00 multiplier (signed)
  SIGNAL temp_m00_v   : STD_LOGIC_VECTOR(WIDTH_00 - 1 DOWNTO 0);  --! Partial product of the 00 multiplier (std logic vector)
  SIGNAL temp_m01     : signed(WIDTH_01 - 1 DOWNTO 0);            --! Partial product of the 01 multiplier
  SIGNAL temp_m10     : signed(WIDTH_10 - 1 DOWNTO 0);            --! Partial product of the 10 multiplier
  SIGNAL temp_m11     : signed(WIDTH_11 - 1 DOWNTO 0);            --! Partial product of the 11 multiplier (signed)
  SIGNAL temp_m11_v   : STD_LOGIC_VECTOR(WIDTH_11 - 1 DOWNTO 0);  --! Partial product of the 11 multiplier (std logic vector)

  SIGNAL carry_00     : signed(WIDTH_00 - 1 DOWNTO WIDTH_00 - 2); --! Carry bits (MSBs) of the 00's partial product (overlap with shifted partial product 11)
  SIGNAL add_11_c00   : signed (WIDTH_11 - 1 DOWNTO 0);           --! Addition result of the 11's partial product and the carry bits of the 00's partial product
  SIGNAL add_01_10    : signed(WIDTH_01 DOWNTO 0);                --! Addition result of the partial product 01 and 10
  SIGNAL add_00_11    : signed(2 * WIDTH - 1 DOWNTO 0);           --! Addition result between the shifted 11's partial product and 00's partial product (we use the addition result of the carry bits and concatenate the 00)

  SIGNAL in_shift_m00 : signed(WIDTH_00 - 1 DOWNTO 0);            --! Controlled input for the shift & add stage. When the partial products 00 and 11 is going to be used this signal is '0'
  SIGNAL in_shift_m01 : signed(WIDTH_01 - 1 DOWNTO 0);            --! Controlled input for the shift & add stage. When the partial products 00 and 11 is going to be used this signal is '0'
  SIGNAL in_shift_m10 : signed(WIDTH_10 - 1 DOWNTO 0);            --! Controlled input for the shift & add stage. When the partial products 00 and 11 is going to be used this signal is '0'
  SIGNAL in_shift_m11 : signed(WIDTH_11 - 1 DOWNTO 0);            --! Controlled input for the shift & add stage. When the partial products 00 and 11 is going to be used this signal is '0'

  SIGNAL sign_ex_a    : STD_LOGIC;                                --! sign extension for A's LSBs
  SIGNAL sign_ex_b    : STD_LOGIC;                                --! sign extension for B's LSBs

  SIGNAL shift_01_10  : signed(2 * WIDTH - 1 DOWNTO 0);           --! Sifted version of add_01_10
  SIGNAL pprod_00     : signed(2 * WIDTH_L - 1 DOWNTO 0);         --! Final partial product 00, resized

  SIGNAL prod_tmp_N   : STD_LOGIC_VECTOR(2 * WIDTH - 1 DOWNTO 0); --! Product of the full WIDTH multiplication (in STD_LOGIC_VECTOR)
  SIGNAL prod_tmp_N2  : STD_LOGIC_VECTOR(2 * WIDTH - 1 DOWNTO 0); --! Products of 00 and 11 in a single std_logic_vector
  SIGNAL combine      : STD_LOGIC_VECTOR(2 * WIDTH - 1 DOWNTO 0); --! Final output of the mul, selected between the 2 types of products
  SIGNAL this_conf    : STD_LOGIC;                                --! Configuration for this level
  SIGNAL next_conf    : STD_LOGIC_VECTOR(s_width - 2 DOWNTO 0);   --! configuration for the next level;

BEGIN
  --------------------------------------------------------------------------------
  -- Generation of configuration signals
  G_WIDTH_LE_8 : IF s_width = 1 GENERATE
    this_conf <= conf(0);
  END GENERATE G_WIDTH_LE_8;

  G_WIDTH_G_8 : IF s_width > 1 GENERATE

    this_conf <= conf(0);

    Next_Conf_G : FOR i IN s_width - 2 DOWNTO 0 GENERATE
      next_conf(i) <= conf(0) AND conf(i + 1);
    END GENERATE Next_Conf_G;

  END GENERATE G_WIDTH_G_8;
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
  -- Split binary to two and extend the sign of lower half
  sign_ex_a   <= in_a(WIDTH_L - 1) AND this_conf;
  temp_a0     <= SIGNED(sign_ex_a & in_a(WIDTH_L - 1 DOWNTO 0));
  temp_a1     <= SIGNED(in_a(WIDTH - 1 DOWNTO WIDTH_L));

  sign_ex_b   <= in_b(WIDTH_L - 1) AND this_conf;
  temp_b0     <= SIGNED(sign_ex_b & in_b(WIDTH_L - 1 DOWNTO 0));
  temp_b1     <= SIGNED(in_b(WIDTH - 1 DOWNTO WIDTH_L));
  --------------------------------------------------------------------------------
  --reports : PROCESS (temp_a0)
  --BEGIN
  --  REPORT "temp_a0 : " & to_string(temp_a0) SEVERITY failure;
  --END PROCESS reports;
  --------------------------------------------------------------------------------
  -- Partial product inputs
  in_mul_00_a <= temp_a0;
  in_mul_00_b <= temp_b0;

  G_AND_A01 : FOR i IN 0 TO in_mul_01_a'length - 1 GENERATE
    in_mul_01_a(i) <= temp_a1(i) AND (NOT this_conf);
  END GENERATE G_AND_A01;

  G_AND_B01 : FOR i IN 0 TO in_mul_01_b'length - 1 GENERATE
    in_mul_01_b(i) <= temp_b0(i) AND (NOT this_conf);
  END GENERATE G_AND_B01;

  G_AND_A10 : FOR i IN 0 TO in_mul_10_a'length - 1 GENERATE
    in_mul_10_a(i) <= temp_a0(i) AND (NOT this_conf);
  END GENERATE G_AND_A10;

  G_AND_B10 : FOR i IN 0 TO in_mul_10_b'length - 1 GENERATE
    in_mul_10_b(i) <= temp_b1(i) AND (NOT this_conf);
  END GENERATE G_AND_B10;

  in_mul_11_a <= temp_a1;
  in_mul_11_b <= temp_b1;
  --------------------------------------------------------------------------------

  --------------------------------------------------------------------------------
  -- Partial Products
  WIDTH_LE_8 : IF s_width = 1 GENERATE
    temp_m00 <= in_mul_00_b * in_mul_00_a;
    temp_m01 <= in_mul_01_b * in_mul_01_a;
    temp_m10 <= in_mul_10_b * in_mul_10_a;
    temp_m11 <= in_mul_11_b * in_mul_11_a;
  END GENERATE WIDTH_LE_8;

  --! @TODO Need to fix the 10, this generate should be called only for widths that will not lead to less than 4 (or 5 bits if it is extended) multiplication (s_width should not go to 0)
  WIDTH_G_8 : IF s_width > 1 GENERATE
    --------------------------------------------------------------------------------
    --! Recursive call for the low part of computation
    U_mul_l : conf_mul_Beh
    GENERIC MAP(
      width   => (WIDTH_L + 1),
      s_width => s_width - 1
    )
    PORT MAP(
      in_a => STD_LOGIC_VECTOR(in_mul_00_a),
      in_b => STD_LOGIC_VECTOR(in_mul_00_b),
      conf => next_conf,
      prod => temp_m00_v
    );
    --------------------------------------------------------------------------------
    temp_m00 <= signed(temp_m00_v); --in_mul_00_b * in_mul_00_a;
    temp_m01 <= in_mul_01_b * in_mul_01_a;
    temp_m10 <= in_mul_10_b * in_mul_10_a;
    --------------------------------------------------------------------------------
    --! Recursive call for the low part of computation
    U_mul_h : conf_mul_Beh
    GENERIC MAP(
      width   => (WIDTH_H),
      s_width => s_width - 1
    )
    PORT MAP(
      in_a => STD_LOGIC_VECTOR(in_mul_11_a),
      in_b => STD_LOGIC_VECTOR(in_mul_11_b),
      conf => next_conf,
      prod => temp_m11_v
    );
    --------------------------------------------------------------------------------
    temp_m11 <= signed(temp_m11_v); -- in_mul_11_b * in_mul_11_a;
  END GENERATE WIDTH_G_8;
  --------------------------------------------------------------------------------

  --------------------------------------------------------------------------------
  -- Inputs to the shifter (turn to zero if not needed)
  G_AND_m00 : FOR i IN 0 TO in_shift_m00'length - 1 GENERATE
    in_shift_m00(i) <= temp_m00(i) AND (NOT this_conf);
  END GENERATE G_AND_m00;

  in_shift_m01 <= temp_m01;
  in_shift_m10 <= temp_m10;

  G_AND_m11 : FOR i IN 0 TO in_shift_m11'length - 1 GENERATE
    in_shift_m11(i) <= temp_m11(i) AND (NOT this_conf);
  END GENERATE G_AND_m11;

  --------------------------------------------------------------------------------

  --------------------------------------------------------------------------------
  -- Partial adders
  -- add 01 and 10 partial products (resized to +1 to get the carry out)
  add_01_10   <= resize(in_shift_m01, (in_shift_m01'LENGTH + 1)) + resize(in_shift_m10, (in_shift_m10'LENGTH + 1));
  carry_00    <= in_shift_m00(WIDTH_00 - 1 DOWNTO WIDTH_00 - 2);
  add_11_c00  <= in_shift_m11 + ('0' & carry_00);
  add_00_11   <= add_11_c00 & in_shift_m00(WIDTH_00 - 3 DOWNTO 0);
  --------------------------------------------------------------------------------

  --------------------------------------------------------------------------------
  -- Shifters
  shift_01_10 <= shift_left(resize(add_01_10, shift_01_10'LENGTH), WIDTH_L);
  --------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------
  -- Adders
  --temp_m      <= shift_m00 + shift_m01 + shift_m11;
  temp_m      <= add_00_11 + shift_01_10;
  --------------------------------------------------------------------------------

  --------------------------------------------------------------------------------
  -- Output selection
  prod_tmp_N  <= STD_LOGIC_VECTOR(temp_m);
  pprod_00    <= temp_m00(2 * WIDTH_L - 1 DOWNTO 0);
  combine     <= STD_LOGIC_VECTOR(temp_m11) & STD_LOGIC_VECTOR(pprod_00);

  G_AND_pN2 : FOR i IN 0 TO prod_tmp_N2'length - 1 GENERATE
    prod_tmp_N2(i) <= combine(i) AND this_conf;
  END GENERATE G_AND_pN2;
  prod <= prod_tmp_N OR prod_tmp_N2;
  ---------------------------------------------------------------------------------
END ARCHITECTURE rtl;