-------------------------------------------------------
--! @file divider_pipe.vhd
--! @brief Pipelined divider
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
-- Title      : Pipelined divider
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : divider_pipe.vhd
-- Author     : Guido Baccelli
-- Company    : KTH
-- Created    : 26/01/2019
-- Last update: 2022-05-13
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2019
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 26/01/2019  1.0      Guido Baccelli      Created
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
--! DesignWare IP cores library
LIBRARY DWARE;
--! Standard logic package
USE ieee.std_logic_1164.ALL;
--! Standard numeric package for signed and unsigned
USE ieee.numeric_std.ALL;
--! Package for DPU Types and Constants
USE work.DPU_pkg.ALL;
--! Packages from DesignWare library
USE DWARE.DWpackages.ALL;
--! Packages from DesignWare library
USE DWARE.DW_Foundation_comp_arith.ALL;

--! This module is a pipelined divider for fixed-point numbers

--! This module implements a divider for fixed-point numbers with generic number 
--! of pipeline stages, operands bitwidth and number of fractional bits.
--! Given two operands originally on 'N' bits and with a 'fb' number of fractional bits, the actual inputs 
--! to the divider must be extended to '2*N' bits but retaining the same number of fractional bits. This 
--! means that the final divider inputs have 'DIV_I_W=2*N' with same 'fb' as the initial inputs. These
--! assumptions lead to quotient and remainder with same fb as the inputs. The quotient and remainder
--! at the output of this module have bitwidth 'DIV_I_W', so to bring them back to 'N' bits they have to be saturated
--! by an external module.
ENTITY divider_pipe IS
  PORT (
    clk       : IN STD_LOGIC;                --! Clock
    rst_n     : IN STD_LOGIC;                --! Asynchronous reset
    const_one : IN signed(DIV_I_W - 1 DOWNTO 0);  --! Constant one represented in same format as inputs
    dividend  : IN signed(DIV_I_W - 1 DOWNTO 0);  --! Input dividend
    divisor   : IN signed(DIV_I_W - 1 DOWNTO 0);  --! Input divisor
    quotient  : OUT signed(DIV_I_W - 1 DOWNTO 0); --! Output quotient
    remainder : OUT signed(DIV_I_W - 1 DOWNTO 0)  --! Output remainder
  );
END ENTITY;

--! @brief Structural description for DesignWare divider, behavioral for simulation
--! @details All inputs and outputs of divider of this module have the same fixed-point format.
--! In case the divisor is 0, a protection mechanism changes the dividend to max or min representable
--! number, depending on the dividend sign. The divisor is changed to one so that quotient=dividend and
--! remainder=0. In order to obtain quotient and remainder on same fixed-point format as inputs, 
--! the dividend is left shifted by the number of fractional bits 'fb'. In case the divider
--! has to be syn, the constant 'DIV_SYN_SIM_N' must be set to '1' so that the DesignWare pipelined divider is used.
--! If the divider has to be simulated, 'DIV_SYN_SIM_N' must be set to '0' so that a behavioral model is used. This model 
--! simply uses the '/' and 'rem' operators to get quotient and remainder and feeds them to a delay line that emulates
--! the pipeline stages.
ARCHITECTURE bhv OF divider_pipe IS

  --! The range is based on assumption that DIV_I_W is two times the original inputs bitwidth
  SUBTYPE frac_part_range IS INTEGER RANGE 0 TO (DIV_I_W/2) - 1;
  TYPE type_array_dividend IS ARRAY(frac_part_range) OF signed(DIV_I_W - 1 DOWNTO 0);
  TYPE pipeline_type IS ARRAY(0 TO div_pipe_num) OF signed(DIV_I_W - 1 DOWNTO 0);

  --! Chooses between synthesis and simulation
  CONSTANT DIV_SYN_SIM_N               : STD_LOGIC := '1';
  --! Max number that can be represented on 'DIV_I_W' bits and 2's complement format
  CONSTANT max_num                     : INTEGER   := 2 ** (DIV_I_W - 1) - 1;
  --! Min number that can be represented on 'DIV_I_W' bits and 2's complement format
  CONSTANT min_num                     : INTEGER   := - 2 ** (DIV_I_W - 1);

  --! Delay line signals for quotient and remainder
  SIGNAL pipe_quotient, pipe_rem       : pipeline_type;

  --! Array of dividers with all fractional bit numbers in 'frac_part_range'
  SIGNAL dividend_array                : type_array_dividend;
  --! Temporary operands
  SIGNAL dividend_tmp, divisor_tmp     : signed(DIV_I_W - 1 DOWNTO 0);
  --! Final operands
  SIGNAL dividend_final, divisor_final : signed(DIV_I_W - 1 DOWNTO 0);
  --! Temporary quotient and remainder
  SIGNAL quotient_tmp, remainder_tmp   : signed(DIV_I_W - 1 DOWNTO 0);
  --! Division by zero control signal (unused)
  SIGNAL divide_by_zero                : STD_LOGIC;

  --! Temporary std_logic signal
  SIGNAL quotient_std                  : STD_LOGIC_VECTOR(DIV_I_W - 1 DOWNTO 0);
  --! Temporary std_logic signal
  SIGNAL remainder_std                 : STD_LOGIC_VECTOR(DIV_I_W - 1 DOWNTO 0);

BEGIN

  dividend_gen : FOR i IN frac_part_range GENERATE
    dividend_array(i) <= shift_left(dividend, i);
  END GENERATE;

  dividend_tmp <= dividend_array(fb);
  divisor_tmp  <= divisor;

  sel_inputs_proc : PROCESS (dividend_tmp, divisor_tmp, const_one)
    VARIABLE dividend_var, divisor_var : signed(DIV_I_W - 1 DOWNTO 0);
  BEGIN
    IF divisor_tmp = 0 THEN
      IF dividend_tmp > 0 THEN
        dividend_var := to_signed(max_num, dividend_var'length);
      ELSE
        dividend_var := to_signed(min_num, dividend_var'length);
      END IF;
      divisor_var := const_one;
    ELSE
      dividend_var := dividend_tmp;
      divisor_var  := divisor_tmp;
    END IF;
    dividend_final <= dividend_var;
    divisor_final  <= divisor_var;
  END PROCESS;

  division : DW_div_pipe
  GENERIC MAP(
    a_width     => DIV_I_W,
    b_width     => DIV_I_W,
    tc_mode     => 1,
    rem_mode    => 1,
    num_stages  => div_pipe_num + 1, --effective num is div_pipe_num
    stall_mode  => 0,
    rst_mode    => 1,
    op_iso_mode => 4
  )
  PORT MAP(
    clk         => clk,
    rst_n       => rst_n,
    en          => '1',
    a           => STD_LOGIC_VECTOR(dividend_final),
    b           => STD_LOGIC_VECTOR(divisor_final),
    quotient    => quotient_std,
    remainder   => remainder_std,
    divide_by_0 => divide_by_zero
  );

  quotient  <= signed(quotient_std);
  remainder <= signed(remainder_std);

END ARCHITECTURE;
