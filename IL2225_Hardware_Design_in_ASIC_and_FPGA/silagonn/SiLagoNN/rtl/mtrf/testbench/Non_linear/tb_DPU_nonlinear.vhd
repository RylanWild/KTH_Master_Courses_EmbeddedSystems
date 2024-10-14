-------------------------------------------------------
--! @file tb_ann_unit.vhd
--! @brief Testbench of NACU
--! @details 
--! @author Guido Baccelli
--! @version 1.1
--! @date 24/08/2019
--! @bug NONE
--! @todo NONE
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
-- Title      : Testbench of NACU
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : tb_ann_unit.vhd
-- Author     : Guido Baccelli
-- Company    : KTH
-- Created    : 24/08/2019
-- Last update: 2020-03-15
-- Platform   : SiLago
-- Standard   : VHDL'08
-- Supervisor : Dimitrios Stathis
-------------------------------------------------------------------------------
-- Copyright (c) 2019
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 24/08/2019  1.0      Guido Baccelli          Created
-- 2020-03-15  1.1      Dimitrios Stathis       Minor changes and preparation for GIT
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
--! Standard library
LIBRARY std;
--! Standard logic package
USE ieee.std_logic_1164.ALL;
--! Standard numeric package for signed and unsigned
USE ieee.numeric_std.ALL;
--! Package for math with real numbers
USE IEEE.math_real.ALL;
--! Use the DPU package
USE work.DPU_pkg.ALL;
USE work.mac_pkg.ALL;
--! Package with Sigmoid behavior model
USE work.sigmoid_pkg.ALL;
--! Package with Tanh behavior model
USE work.tanh_pkg.ALL;
--! Package with Exponential behavior model
USE work.exp_pkg.ALL;
--! Use of environment package 
USE std.env.ALL;

ENTITY testbench IS
END ENTITY;

--! @brief Testbench Behavioral description

--! @details At each clock cycle, random input values are generated. These are fed to DUT
--! and to the expected behavior model. A delay line after the model aligns results to DUT latencies.
--! At last, a process compares expected results with DUT outputs.
ARCHITECTURE tb_all_ops OF testbench IS

  --! highest latency value
  CONSTANT max_lat : INTEGER := 8;
  SUBTYPE in_range IS NATURAL RANGE DPU_BITWIDTH - 1 DOWNTO 0;                   --! Input bit range
  SUBTYPE div_range IS NATURAL RANGE 2 * DPU_BITWIDTH - 1 DOWNTO 0;              --! Divider input/output bit range

  TYPE finish_array IS ARRAY(0 TO max_lat) OF STD_LOGIC_VECTOR(0 DOWNTO 0);      --! Array of signals for finish delay line
  TYPE pipe_type IS ARRAY(0 TO max_lat) OF SIGNED(S_DPU_OUT_WIDTH - 1 DOWNTO 0); --! Array of signals for delay line
  TYPE lat_array IS ARRAY(0 TO 5) OF INTEGER;                                    --! Array of latency values for each operation

  CONSTANT clk_period  : TIME      := 5 ns;                                      --! Full clock period
  CONSTANT half_period : TIME      := 2.5 ns;                                    --! Half clock period
  CONSTANT oper        : INTEGER   := S_TANHYP;                                  --! Selected operation to simulate

  --! Array that contains latency values. Latency position is equal to Opcode value
  CONSTANT latency     : lat_array := (
    0, -- IDLE
    0, -- MAC
    0, -- SIGM
    0, -- TANHYP
    0, -- EXPON
    0  -- SM
  );

  CONSTANT INP_END    : INTEGER := 10;                                  --! Number of generated inputs
  --CONSTANT SIM_END			: time := clk_period*(INP_END + 1 + (latency(oper) + 1);

  CONSTANT repr_range : real    := REAL(2 ** (DPU_BITWIDTH));           --! Representation range in unsigned format
  CONSTANT range_offs : real    := REAL(2 ** (DPU_BITWIDTH - 1) + 1);   --! Subtracted to 'repr_range' to obtain repr. range in 2's complement
  SUBTYPE opc_range IS NATURAL RANGE S_DPU_CFG_WIDTH - 1 DOWNTO 0;      --! Opcode bit range

  SIGNAL clk          : STD_LOGIC := '1';                               --! Clock signal
  SIGNAL rst_n        : STD_LOGIC := '1';                               --! Asynchronous reset signal
  SIGNAL inst_a       : signed(in_range);                               --! First generated input
  SIGNAL inst_b       : signed(in_range);                               --! Second generated input 
  SIGNAL sm_in        : signed(div_range);                              --! DUT softmax denominator input
  SIGNAL cnt          : INTEGER;                                        --! Input generation counter
  SIGNAL tmp_a        : INTEGER;                                        --! Input in integer format for function model
  SIGNAL tmp_b        : INTEGER;                                        --! Input in integer format for function model
  SIGNAL acc_out      : INTEGER;                                        --! Accumulator for function model
  SIGNAL out0         : STD_LOGIC_VECTOR(S_DPU_OUT_WIDTH - 1 DOWNTO 0); --! DUT standard output
  SIGNAL out0_s       : signed(S_DPU_OUT_WIDTH - 1 DOWNTO 0);           --! DUT standard output
  SIGNAL sm_out       : STD_LOGIC_VECTOR(div_range);                    --! DUT softmax output
  SIGNAL opcode       : STD_LOGIC_VECTOR(opc_range);                    --! DUT opcode input
  SIGNAL res_bit      : STD_LOGIC;                                      --! Correct result control bit
  SIGNAL delays       : pipe_type;                                      --! Delay line outputs
  SIGNAL finish_delay : finish_array := (OTHERS => (OTHERS => '0'));    --! Finish delay line outputs

  COMPONENT reg_n IS
    GENERIC (Nb : INTEGER := 16);
    PORT (
      clk   : IN STD_LOGIC;
      rst_n : IN STD_LOGIC;
      clear : IN STD_LOGIC;
      en    : IN STD_LOGIC;
      d_in  : IN STD_LOGIC_VECTOR(Nb - 1 DOWNTO 0);
      d_out : OUT STD_LOGIC_VECTOR(Nb - 1 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT reg_n_signed IS
    GENERIC (Nb : INTEGER := 16);
    PORT (
      clk   : IN STD_LOGIC;
      rst_n : IN STD_LOGIC;
      clear : IN STD_LOGIC;
      en    : IN STD_LOGIC;
      d_in  : IN signed(Nb - 1 DOWNTO 0);
      d_out : OUT signed(Nb - 1 DOWNTO 0)
    );
  END COMPONENT;
BEGIN
  clk <= NOT clk AFTER half_period WHEN finish_delay(latency(oper)) /= "1" ELSE
    '0' AFTER half_period;                      --! Clock generation 
  rst_n <= '0', '1' AFTER half_period + 1 ns; --! Reset generation

  --! Input generation process
  PROCESS (clk, rst_n)
    VARIABLE seed1                  : POSITIVE := 5; --! Seed values for random generator
    VARIABLE seed2                  : POSITIVE := 3; --! Seed values for random generator              
    VARIABLE rand1                  : real;          --! random real-number value in range 0 to 1.0
    VARIABLE rand2                  : real;          --! random real-number value in range 0 to 1.0
    VARIABLE input_int1, input_int2 : INTEGER;
  BEGIN

    IF (rst_n = '0') THEN
      inst_a <= (OTHERS => '0');
      inst_b <= (OTHERS => '0');
      cnt    <= 0;
      tmp_a  <= 0;
      tmp_b  <= 0;
      opcode <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      --! If number of generated inputs did not exceed INP_END
      IF cnt < INP_END THEN
        uniform(seed1, seed2, rand1); --! Generates random number
        uniform(seed1, seed2, rand2); --! Generates random number
        --! Exponential tail has limited valid input range   
        IF oper = S_EXPON THEN
          input_int1 := INTEGER(TRUNC(-rand1 * (repr_range/2.0))); --! Input range = [-2^(Nb-1), 0]
          input_int2 := INTEGER(TRUNC(-rand2 * (repr_range/2.0))); --! Input range = [-2^(Nb-1), 0]
        ELSE
          input_int1 := INTEGER(TRUNC(rand1 * repr_range - range_offs)); --! Input range = [-2^(Nb-1), 2^(Nb-1)-1]
          input_int2 := INTEGER(TRUNC(rand2 * repr_range - range_offs)); --! Input range = [-2^(Nb-1), 2^(Nb-1)-1]
        END IF;

        --! Assigns integer inputs to signals
        IF oper = S_SM THEN
          inst_a <= to_signed(input_int1, inst_a'length);
          inst_b <= to_signed(0, inst_b'length);
          sm_in  <= to_signed(input_int2, sm_in'length);
        ELSE
          inst_a <= to_signed(input_int1, inst_a'length);
          inst_b <= to_signed(input_int2, inst_b'length);
          sm_in  <= to_signed(0, sm_in'length);
        END IF;
        tmp_a  <= input_int1; --! Assigns integer inputs to function model inputs
        tmp_b  <= input_int2; --! Assigns integer inputs to function model inputs
        cnt    <= cnt + 1;
        opcode <= STD_LOGIC_VECTOR(to_unsigned(oper, opcode'length));
      ELSE
        finish_delay(0) <= "1"; --! End simulation signal is sent to delay line
      END IF;

    END IF;
  END PROCESS;

  --! Behavior models of NACU operation
  PROCESS (clk, rst_n)
    VARIABLE func_res_int : INTEGER;
  BEGIN
    IF (rst_n = '0') THEN
      acc_out   <= 0;
      delays(0) <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      CASE oper IS
        WHEN S_MAC                     =>
          func_res_int := mac_int(a => tmp_a, b => tmp_b, acc => acc_out, nbits => DPU_BITWIDTH, frac => fb);
        WHEN S_SIGM                    =>
          func_res_int := sigmoid_fp11(x => tmp_a);
        WHEN S_TANHYP                  =>
          func_res_int := tanh_fp11(x    => tmp_a);
        WHEN S_EXPON                   =>
          func_res_int := exp_fp11(x     => tmp_a);
        WHEN OTHERS                    =>
          func_res_int := INTEGER(trunc((real(tmp_a)/real(tmp_b)) * real(2 ** (fb)))); --! NACU Division
      END CASE;
      acc_out   <= func_res_int;                              --! Result is saved in accumulator (only used for MAC)
      delays(0) <= to_signed(func_res_int, delays(0)'length); --! Result is sent to delay line
    END IF;
  END PROCESS;

  --! Delay lines generation
  delay_pipe_gen : FOR i IN 0 TO max_lat - 1 GENERATE
    --! Result delay line
    reg_pipe_gen : PROCESS (clk, rst_n)
    BEGIN
      IF rst_n = '0' THEN
        delays(i + 1) <= (OTHERS => '0');
      ELSIF rising_edge(clk) THEN
        delays(i + 1) <= delays(i);
      END IF;
    END PROCESS;

    --! Delay line for end simulation signal
    finish_pipe_gen : PROCESS (clk, rst_n)
    BEGIN
      IF rst_n = '0' THEN
        finish_delay(i + 1) <= (OTHERS => '0');
      ELSIF rising_edge(clk) THEN
        finish_delay(i + 1) <= finish_delay(i);
      END IF;
    END PROCESS;
  END GENERATE;

  --! Compares results from model and DUT
  PROCESS (clk, rst_n)
    VARIABLE res_var    : STD_LOGIC;
    VARIABLE res_signed : signed(S_DPU_OUT_WIDTH - 1 DOWNTO 0);
  BEGIN
    --  IF rst_n = '0' THEN
    --    res_bit <= '0';
    --  ELSIF rising_edge(clk) THEN
    --    CASE oper IS
    --      WHEN S_MAC =>
    --        res_signed := delays(latency(MAC));
    --        ASSERT (delays(latency(MAC)) = signed(out0))
    --        REPORT "Wrong result!"
    --          SEVERITY WARNING;
    --      WHEN S_SIGM =>
    --        res_signed := delays(latency(SIGM));
    --        ASSERT (delays(latency(SIGM)) = signed(out0))
    --        REPORT "Wrong result!"
    --          SEVERITY WARNING;
    --      WHEN S_TANHYP =>
    --        res_signed := delays(latency(TANHYP));
    --        ASSERT (delays(latency(TANHYP)) = signed(out0))
    --        REPORT "Wrong result!"
    --          SEVERITY WARNING;
    --      WHEN S_EXPON =>
    --        res_signed := delays(latency(EXPON));
    --        ASSERT (delays(latency(EXPON)) = signed(out0))
    --        REPORT "Wrong result!"
    --          SEVERITY WARNING;
    --      WHEN OTHERS =>
    --        res_signed := delays(latency(SM));
    --        ASSERT (delays(latency(SM)) = signed(out0))
    --        REPORT "Wrong result!"
    --          SEVERITY WARNING;
    --    END CASE;
    --    IF (res_signed = signed(out0)) AND (cnt > latency(oper)) THEN
    --      res_bit <= '1';
    --    ELSE
    --      res_bit <= '0';
    --    END IF;
    --  END IF;
  END PROCESS;

  --! DUT instantiation
  DUT : ENTITY work.NACU
    GENERIC MAP(
      mac_pipe     => 0,
      squash_pipe  => 0,
      div_n_squash => 1
    )
    PORT MAP(
      clk           => clk,
      clear         => '0',
      rst_n         => rst_n,

      bit_config    => "00",
      mode_cfg      => unsigned(opcode),
      acc_clear     => '0',

      direct_acc => (OTHERS => '0'),
      direct_acc_en => '0',

      div_direct => (OTHERS => '0'),
      divide_acc    => '0',

      nacu_in_0     => inst_a,
      nacu_in_1     => inst_b,

      --      seq_cond_status => NULL,

      nacu_out      => out0_s
    );

  out0 <= STD_LOGIC_VECTOR(out0_s);

END ARCHITECTURE tb_all_ops;