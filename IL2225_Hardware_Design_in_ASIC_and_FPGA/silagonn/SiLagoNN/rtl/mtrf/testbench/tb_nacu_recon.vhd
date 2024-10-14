-------------------------------------------------------
--! @file testbench_mac_test.vhd
--! @brief Testbench for reconfigurable mac
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 31/01/2020
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
-- Title      : Testbench for reconfigurable mac
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : testbench_mac_test.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 31/01/2020
-- Last update: 31/01/2020
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 31/01/2020  1.0      Dimitrios Stathis      Created
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
--! Standard IEEE and Work library
LIBRARY IEEE, work, STD;
--! Use Logic library
USE IEEE.STD_LOGIC_1164.ALL;
--! Library for sign/unsign arithmetics
USE IEEE.numeric_std.ALL;
--! Mathematic library for real, used for random numbers
USE IEEE.math_real.ALL;
--! See all items in work library
USE work.ALL;
--! Use misc package for divUp and divDown functions
USE work.util_package.ALL;
--! Use DPU package
USE work.DPU_pkg.ALL;
--! Standard VHDL library
LIBRARY std;
--! Use the env package to end the simulation
USE std.env.ALL;
--! Basic I/O
USE STD.textio.ALL;
--! I/O for logic types
USE IEEE.std_logic_textio.ALL;

---------------------------------------------------------------------------
ENTITY TB IS
END ENTITY;
---------------------------------------------------------------------------
--  Use the following command in vsim to suppress testbench truncation warnings
--  set NumericStdNoWarnings 1
---------------------------------------------------------------------------
ARCHITECTURE TB_NACU_V2 OF TB IS

  CONSTANT div           : NATURAL                            := 0;
  CONSTANT mac_pipe      : NATURAL                            := 0;
  CONSTANT squash_pipe   : NATURAL                            := 0;

  CONSTANT clk_period    : TIME                               := 5 ns;
  CONSTANT bit_width     : INTEGER                            := DPU_pkg.DPU_bitwidth;
  CONSTANT SIM_END       : INTEGER                            := 10000;

  CONSTANT WIDTH_L       : NATURAL                            := divDown(bit_width, 2); --! Constant value for Width of the upper half
  CONSTANT WIDTH_H       : NATURAL                            := divUp(bit_width, 2);   --! Constant value for Width of the lower half
  CONSTANT WIDTH_2L      : NATURAL                            := divDown(bit_width, 4);
  CONSTANT width_2H      : NATURAL                            := divUp(bit_width, 4);
  CONSTANT MAX_VALUE     : signed(bit_width * 2 - 1 DOWNTO 0) := "01111111111111111111111111111111";
  CONSTANT MIN_VALUE     : signed(bit_width * 2 - 1 DOWNTO 0) := "10000000000000000000000000000000";
  CONSTANT MAX_VALUE_0   : signed(bit_width - 1 DOWNTO 0)     := "0111111111111111";
  CONSTANT MIN_VALUE_0   : signed(bit_width - 1 DOWNTO 0)     := "1000000000000000";
  CONSTANT MAX_VALUE_00  : signed(bit_width / 2 - 1 DOWNTO 0) := "01111111";
  CONSTANT MIN_VALUE_00  : signed(bit_width / 2 - 1 DOWNTO 0) := "10000000";

  SIGNAL clk             : STD_LOGIC                          := '0';
  SIGNAL rst_n           : STD_LOGIC                          := '1';
  SIGNAL inst_a          : signed(bit_width - 1 DOWNTO 0);
  SIGNAL inst_b          : signed(bit_width - 1 DOWNTO 0);
  SIGNAL inst_op         : STD_LOGIC;
  SIGNAL res             : signed(2 * bit_width - 1 DOWNTO 0);
  SIGNAL prod            : signed(2 * bit_width - 1 DOWNTO 0);
  SIGNAL cnt             : INTEGER;
  SIGNAL delay0          : signed(2 * bit_width - 1 DOWNTO 0);
  SIGNAL delay1          : signed(2 * bit_width - 1 DOWNTO 0);
  SIGNAL delay2          : signed(2 * bit_width - 1 DOWNTO 0);
  SIGNAL delay3          : signed(2 * bit_width - 1 DOWNTO 0);
  SIGNAL check_signal    : signed(2 * bit_width - 1 DOWNTO 0);

  SIGNAL conf            : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL clear           : STD_LOGIC;                               --! clear all nacu registers
  SIGNAL mode_cfg        : unsigned (S_DPU_CFG_WIDTH - 1 DOWNTO 0); --! DPU configuration 
  SIGNAL acc_clear       : STD_LOGIC;                               --! acc clear for nacu
  SIGNAL seq_cond_status : STD_LOGIC_VECTOR(SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0);

  SIGNAL tmp_out0_reg    : signed(WIDTH_L * 2 - 1 DOWNTO 0);
  SIGNAL tmp_out1_reg    : signed(WIDTH_H * 2 - 1 DOWNTO 0);
  SIGNAL tmp_out00_reg   : signed(WIDTH_2L * 2 - 1 DOWNTO 0);
  SIGNAL tmp_out01_reg   : signed(WIDTH_2L * 2 - 1 DOWNTO 0);
  SIGNAL tmp_out10_reg   : signed(WIDTH_2L * 2 - 1 DOWNTO 0);
  SIGNAL tmp_out11_reg   : signed(WIDTH_2H * 2 - 1 DOWNTO 0);

  SIGNAL tmp_out0_sig    : signed(WIDTH_L * 2 - 1 DOWNTO 0);
  SIGNAL tmp_out1_sig    : signed(WIDTH_H * 2 - 1 DOWNTO 0);
  SIGNAL tmp_out00_sig   : signed(WIDTH_2L * 2 - 1 DOWNTO 0);
  SIGNAL tmp_out01_sig   : signed(WIDTH_2L * 2 - 1 DOWNTO 0);
  SIGNAL tmp_out10_sig   : signed(WIDTH_2L * 2 - 1 DOWNTO 0);
  SIGNAL tmp_out11_sig   : signed(WIDTH_2H * 2 - 1 DOWNTO 0);

BEGIN
  clk   <= NOT clk AFTER clk_period/2;
  rst_n <= '0', '1' AFTER 6 ns;

  PROCESS (clk, rst_n)
    VARIABLE seed1    : POSITIVE := 5;
    VARIABLE seed2    : POSITIVE := 3; -- seed values for random generator
    VARIABLE rand1    : real;          -- random real-number value in range 0 to 1.0
    VARIABLE rand2    : real;          -- random real-number value in range 0 to 1.0
    VARIABLE signed_a : signed(bit_width - 1 DOWNTO 0);
    VARIABLE signed_b : signed(bit_width - 1 DOWNTO 0);
    VARIABLE my_line  : line; -- type 'line' comes from textio
  BEGIN

    IF (rst_n = '0') THEN
      inst_a   <= (OTHERS => '0');
      inst_b   <= (OTHERS => '0');
      inst_op  <= '0';
      cnt      <= 0;
      conf     <= "00";
      mode_cfg <= to_unsigned(S_MAC, mode_cfg'length);
    ELSIF rising_edge(clk) THEN

      cnt <= cnt + 1;

      uniform(seed1, seed2, rand1); -- generate random number
      inst_a <= to_signed(INTEGER(TRUNC(rand1 * 100000.0)), inst_a'length);
      uniform(seed1, seed2, rand2); -- generate random number
      inst_b <= to_signed(INTEGER(TRUNC(rand2 * 100000.0)), inst_b'length);

      write(my_line, STRING'("Iteration : "));
      write(my_line, cnt);
      writeline(output, my_line);

      IF (cnt = SIM_END) THEN
        write(my_line, STRING'("Simulation successful!"));
        writeline(output, my_line);
        finish(0);
      END IF;

    END IF;
  END PROCESS;

  prod_calculation : PROCESS (ALL)
    VARIABLE tmp_a0    : signed(WIDTH_L - 1 DOWNTO 0);
    VARIABLE tmp_b0    : signed(WIDTH_L - 1 DOWNTO 0);
    VARIABLE tmp_a1    : signed(WIDTH_H - 1 DOWNTO 0);
    VARIABLE tmp_b1    : signed(WIDTH_H - 1 DOWNTO 0);

    VARIABLE tmp_out0  : signed(WIDTH_L * 2 - 1 DOWNTO 0);
    VARIABLE tmp_out1  : signed(WIDTH_H * 2 - 1 DOWNTO 0);

    VARIABLE tmp_mul   : signed(31 DOWNTO 0);
    VARIABLE mac       : signed(32 DOWNTO 0);

    VARIABLE tmp_a00   : signed(WIDTH_2L - 1 DOWNTO 0);
    VARIABLE tmp_a10   : signed(WIDTH_2H - 1 DOWNTO 0);
    VARIABLE tmp_a01   : signed(WIDTH_2H - 1 DOWNTO 0);
    VARIABLE tmp_a11   : signed(WIDTH_2H - 1 DOWNTO 0);

    VARIABLE mac_0     : INTEGER;
    VARIABLE mac_1     : INTEGER;

    VARIABLE tmp_b00   : signed(WIDTH_2L - 1 DOWNTO 0);
    VARIABLE tmp_b01   : signed(WIDTH_2L - 1 DOWNTO 0);
    VARIABLE tmp_b10   : signed(WIDTH_2H - 1 DOWNTO 0);
    VARIABLE tmp_b11   : signed(WIDTH_2H - 1 DOWNTO 0);

    VARIABLE tmp_out00 : signed(WIDTH_2L * 2 - 1 DOWNTO 0);
    VARIABLE tmp_out01 : signed(WIDTH_2L * 2 - 1 DOWNTO 0);
    VARIABLE tmp_out10 : signed(WIDTH_2L * 2 - 1 DOWNTO 0);
    VARIABLE tmp_out11 : signed(WIDTH_2H * 2 - 1 DOWNTO 0);

    VARIABLE mac_00    : INTEGER;
    VARIABLE mac_01    : INTEGER;
    VARIABLE mac_10    : INTEGER;
    VARIABLE mac_11    : INTEGER;
  BEGIN
    tmp_a0    := (OTHERS => '0');
    tmp_b0    := (OTHERS => '0');
    tmp_a1    := (OTHERS => '0');
    tmp_b1    := (OTHERS => '0');
    tmp_out0  := (OTHERS => '0');
    tmp_out1  := (OTHERS => '0');
    tmp_mul   := (OTHERS => '0');
    mac       := (OTHERS => '0');
    tmp_a00   := (OTHERS => '0');
    tmp_a10   := (OTHERS => '0');
    tmp_a01   := (OTHERS => '0');
    tmp_a11   := (OTHERS => '0');
    tmp_b00   := (OTHERS => '0');
    tmp_b01   := (OTHERS => '0');
    tmp_b10   := (OTHERS => '0');
    tmp_b11   := (OTHERS => '0');
    tmp_out00 := (OTHERS => '0');
    tmp_out01 := (OTHERS => '0');
    tmp_out10 := (OTHERS => '0');
    tmp_out11 := (OTHERS => '0');
    mac_0     := 0;
    mac_1     := 0;
    mac_00    := 0;
    mac_01    := 0;
    mac_10    := 0;
    mac_11    := 0;
    IF conf = "00" THEN
      tmp_mul := inst_a * inst_b;
      mac     := resize(tmp_mul, mac'length) + resize(delay1, mac'length);
      delay0 <= saturation(mac, MAX_VALUE, MIN_VALUE);

    ELSIF conf = "01" THEN

      tmp_a0   := inst_a(WIDTH_L - 1 DOWNTO 0);
      tmp_a1   := inst_a(bit_width - 1 DOWNTO WIDTH_L);
      tmp_b0   := inst_b(WIDTH_L - 1 DOWNTO 0);
      tmp_b1   := inst_b(bit_width - 1 DOWNTO WIDTH_L);
      mac_0    := to_integer(tmp_a0) * to_integer(tmp_b0) + to_integer(tmp_out0_reg);
      mac_1    := to_integer(tmp_a1) * to_integer(tmp_b1) + to_integer(tmp_out1_reg);

      tmp_out0 := saturation(mac_0, MAX_VALUE_0, MIN_VALUE_0);
      tmp_out1 := saturation(mac_1, MAX_VALUE_0, MIN_VALUE_0);

      tmp_out0_sig <= tmp_out0;
      tmp_out1_sig <= tmp_out1;

      delay0       <= tmp_out1 & tmp_out0;

    ELSIF conf = "11" THEN

      tmp_a00   := inst_a(WIDTH_2L - 1 DOWNTO 0);
      tmp_a01   := inst_a(WIDTH_L - 1 DOWNTO WIDTH_2L);
      tmp_a10   := inst_a(WIDTH_2H + WIDTH_L - 1 DOWNTO WIDTH_L);
      tmp_a11   := inst_a(bit_width - 1 DOWNTO WIDTH_2H + WIDTH_L);

      tmp_b00   := inst_b(WIDTH_2L - 1 DOWNTO 0);
      tmp_b01   := inst_b(WIDTH_L - 1 DOWNTO WIDTH_2L);
      tmp_b10   := inst_b(WIDTH_2H + WIDTH_L - 1 DOWNTO WIDTH_L);
      tmp_b11   := inst_b(bit_width - 1 DOWNTO WIDTH_2H + WIDTH_L);

      mac_00    := to_integer(tmp_a00) * to_integer(tmp_b00) + to_integer(tmp_out00_reg);
      mac_01    := to_integer(tmp_a01) * to_integer(tmp_b01) + to_integer(tmp_out01_reg);
      mac_10    := to_integer(tmp_a10) * to_integer(tmp_b10) + to_integer(tmp_out10_reg);
      mac_11    := to_integer(tmp_a11) * to_integer(tmp_b11) + to_integer(tmp_out11_reg);

      tmp_out00 := saturation(mac_00, MAX_VALUE_00, MIN_VALUE_00);
      tmp_out01 := saturation(mac_01, MAX_VALUE_00, MIN_VALUE_00);
      tmp_out10 := saturation(mac_10, MAX_VALUE_00, MIN_VALUE_00);
      tmp_out11 := saturation(mac_11, MAX_VALUE_00, MIN_VALUE_00);

      tmp_out00_sig <= tmp_out00;
      tmp_out01_sig <= tmp_out01;
      tmp_out10_sig <= tmp_out10;
      tmp_out11_sig <= tmp_out11;

      delay0        <= tmp_out11 & tmp_out10 & tmp_out01 & tmp_out00;

    ELSIF conf = "10" THEN
      REPORT "ERROR conf 10 is not support!" SEVERITY failure;
    END IF;
    -- Register product to align with dut
    IF rst_n = '0' THEN
      delay1        <= (OTHERS => '0');
      delay2        <= (OTHERS => '0');
      delay3        <= (OTHERS => '0');
      tmp_out0_reg  <= (OTHERS => '0');
      tmp_out1_reg  <= (OTHERS => '0');
      tmp_out00_reg <= (OTHERS => '0');
      tmp_out01_reg <= (OTHERS => '0');
      tmp_out10_reg <= (OTHERS => '0');
      tmp_out11_reg <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      delay1        <= delay0;
      delay2        <= delay1;
      delay3        <= delay2;
      tmp_out0_reg  <= tmp_out0_sig;
      tmp_out1_reg  <= tmp_out1_sig;
      tmp_out00_reg <= tmp_out00_sig;
      tmp_out01_reg <= tmp_out01_sig;
      tmp_out10_reg <= tmp_out10_sig;
      tmp_out11_reg <= tmp_out11_sig;
    END IF;
  END PROCESS prod_calculation;

  check_signal <= delay1 WHEN mac_pipe = 0 ELSE
    delay2;

  --! Monitor process
  PROCESS (clk, rst_n)
  BEGIN

    IF (rst_n = '0') THEN

    ELSIF falling_edge(clk) THEN

      IF conf = "00" THEN
        ASSERT (check_signal = res)
        REPORT "!!!!!!!!!!!!!!!!!!!!!!" & CR & "          !!!! Wrong result !!!!" & CR & "          !!!!!!!!!!!!!!!!!!!!!!" & CR &
          "Expected outcome: " & INTEGER'IMAGE(to_integer(delay1)) & " DUT output: " & INTEGER'IMAGE (to_integer(res)) & CR &
          "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a)) & " " & INTEGER'IMAGE(to_integer(inst_b))
          SEVERITY failure;
      ELSIF conf = "01" THEN
        ASSERT (check_signal = res)
        REPORT "!!!!!!!!!!!!!!!!!!!!!!" & CR & "          !!!! Wrong result !!!!" & CR & "          !!!!!!!!!!!!!!!!!!!!!!" & CR &
          "Expected outcome: " & INTEGER'IMAGE(to_integer(delay1(bit_width * 2 - 1 DOWNTO bit_width))) & " DUT output: " & INTEGER'IMAGE(to_integer(res(bit_width * 2 - 1 DOWNTO bit_width))) & CR &
          "Expected outcome: " & INTEGER'IMAGE(to_integer(delay1(bit_width - 1 DOWNTO 0))) & " DUT output: " & INTEGER'IMAGE(to_integer(res(bit_width - 1 DOWNTO 0))) & CR &
          "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a(bit_width - 1 DOWNTO bit_width/2))) & " " & INTEGER'IMAGE(to_integer(inst_b(bit_width - 1 DOWNTO bit_width/2))) & CR &
          "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a(bit_width/2 - 1 DOWNTO 0))) & " " & INTEGER'IMAGE(to_integer(inst_b(bit_width/2 - 1 DOWNTO 0)))
          SEVERITY failure;
      ELSIF conf = "11" THEN
        ASSERT (check_signal = res)
        REPORT "!!!!!!!!!!!!!!!!!!!!!!" & CR & "          !!!! Wrong result !!!!" & CR & "          !!!!!!!!!!!!!!!!!!!!!!" & CR &
          "Expected outcome: " & INTEGER'IMAGE(to_integer(delay1(bit_width/2 - 1 DOWNTO 0))) & " DUT output : " &
          INTEGER'IMAGE(to_integer(res(bit_width/2 - 1 DOWNTO 0))) & CR &
          "Expected outcome: " & INTEGER'IMAGE(to_integer(delay1(bit_width - 1 DOWNTO bit_width/2))) & " DUT output: " &
          INTEGER'IMAGE(to_integer(res(bit_width - 1 DOWNTO bit_width/2))) & CR &
          "Expected outcome: " & INTEGER'IMAGE(to_integer(delay1((bit_width + bit_width/2) - 1 DOWNTO bit_width))) &
          " DUT output: " & INTEGER'IMAGE(to_integer(res((bit_width + bit_width/2 - 1) DOWNTO bit_width))) & CR &
          "Expected outcome: " & INTEGER'IMAGE(to_integer(delay1(bit_width * 2 - 1 DOWNTO bit_width + bit_width/2))) & " DUT output: " &
          INTEGER'IMAGE(to_integer(res(bit_width * 2 - 1 DOWNTO bit_width - bit_width/2))) & CR &
          "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a(WIDTH_2L - 1 DOWNTO 0))) & " " &
          INTEGER'IMAGE(to_integer(inst_b(WIDTH_2L - 1 DOWNTO 0))) & CR &
          "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a(WIDTH_L - 1 DOWNTO WIDTH_2L))) & " " &
          INTEGER'IMAGE(to_integer(inst_b(WIDTH_L - 1 DOWNTO WIDTH_2L))) & CR &
          "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a(WIDTH_2H + WIDTH_L - 1 DOWNTO WIDTH_L))) &
          " " & INTEGER'IMAGE(to_integer(inst_b(WIDTH_2H + WIDTH_L - 1 DOWNTO WIDTH_L))) & CR &
          "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a(bit_width - 1 DOWNTO WIDTH_2H + WIDTH_L))) &
          " " & INTEGER'IMAGE(to_integer(inst_b(bit_width - 1 DOWNTO WIDTH_2H + WIDTH_L)))
          SEVERITY failure;
      END IF;

    END IF;
  END PROCESS;

  --! Component definition
  DUT : ENTITY work.NACU
    GENERIC MAP(
      mac_pipe     => mac_pipe,
      squash_pipe  => squash_pipe,
      div_n_squash => div
    )
    PORT MAP(

      clk             => clk,
      clear           => clear,
      rst_n           => rst_n,

      bit_config      => conf,
      mode_cfg        => mode_cfg,
      acc_clear       => acc_clear,

      nacu_in_0       => inst_a,
      nacu_in_1       => inst_b,

      seq_cond_status => seq_cond_status,

      nacu_out        => prod
    );
  res <= prod;

END ARCHITECTURE TB_NACU_V2;