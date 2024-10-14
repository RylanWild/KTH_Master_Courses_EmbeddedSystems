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
--! Testbench package
USE work.tb_pkg_dpu.ALL;

---------------------------------------------------------------------------
ENTITY TB IS
END ENTITY;
---------------------------------------------------------------------------
--  Use the following command in vsim to suppress testbench truncation warnings
--  set NumericStdNoWarnings 1
---------------------------------------------------------------------------
ARCHITECTURE TB_DPU_V2 OF TB IS

  CONSTANT clk_period         : TIME      := 5 ns;

  CONSTANT SIM_END            : INTEGER   := 10000;

  SIGNAL clk                  : STD_LOGIC := '0';
  SIGNAL rst_n                : STD_LOGIC := '1';
  SIGNAL cnt                  : INTEGER;

  SIGNAL inst_a               : in_out_data;
  SIGNAL inst_b               : in_out_data;
  SIGNAL inst_c               : in_out_data;
  SIGNAL inst_d               : in_out_data;

  SIGNAL inst_a_d2            : in_out_data;
  SIGNAL inst_b_d2            : in_out_data;
  SIGNAL inst_c_d2            : in_out_data;
  SIGNAL inst_d_d2            : in_out_data;

  SIGNAL inst_a_d1            : in_out_data;
  SIGNAL inst_b_d1            : in_out_data;
  SIGNAL inst_c_d1            : in_out_data;
  SIGNAL inst_d_d1            : in_out_data;

  SIGNAL inst_a_s             : in_out_data;
  SIGNAL inst_b_s             : in_out_data;
  SIGNAL inst_c_s             : in_out_data;
  SIGNAL inst_d_s             : in_out_data;

  SIGNAL inst_io              : STD_LOGIC_VECTOR(DPU_IO_CONF_WIDTH - 1 DOWNTO 0);
  SIGNAL inst_mode            : STD_LOGIC_VECTOR (DPU_MODE_CFG_WIDTH - 1 DOWNTO 0); --! DPU mode configuration;
  SIGNAL conf                 : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL seq_cond_status      : STD_LOGIC_VECTOR(SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0);
  SIGNAL inst_constant        : STD_LOGIC_VECTOR(DPU_CONS_WIDTH - 1 DOWNTO 0); --! Constant input from the instruction (sequencer), used for scaling or other operations

  SIGNAL inst_acc_clear_rst   : STD_LOGIC;
  SIGNAL inst_acc_clear       : STD_LOGIC_VECTOR (DPU_ACC_CLEAR_WIDTH - 1 DOWNTO 0);

  SIGNAL inst_out_0           : in_out_data;
  SIGNAL inst_out_1           : in_out_data;

  SIGNAL inst_out_0_data      : signed(DPU_OUT_WIDTH - 1 DOWNTO 0);
  SIGNAL inst_out_1_data      : signed(DPU_OUT_WIDTH - 1 DOWNTO 0);

  SIGNAL inst_seq_cond_status : STD_LOGIC_VECTOR (SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0); --! Logic status (G, L, E)

  SIGNAL res_0                : signed(bit_width - 1 DOWNTO 0);
  SIGNAL res_1                : signed(bit_width - 1 DOWNTO 0);

  SIGNAL delay0_0             : in_out_data;
  SIGNAL delay1_0             : in_out_data;
  SIGNAL delay2_0             : in_out_data;
  SIGNAL delay3_0             : in_out_data;

  SIGNAL delay0_1             : in_out_data;
  SIGNAL delay1_1             : in_out_data;
  SIGNAL delay2_1             : in_out_data;
  SIGNAL delay3_1             : in_out_data;

  SIGNAL check_signal0        : in_out_data;
  SIGNAL check_signal1        : in_out_data;

BEGIN
  clk   <= NOT clk AFTER clk_period/2;
  rst_n <= '0', '1' AFTER 6 ns;

  PROCESS (clk, rst_n)
    VARIABLE seed1   : POSITIVE := 5;
    VARIABLE seed2   : POSITIVE := 3; -- seed values for random generator
    VARIABLE seed3   : POSITIVE := 9;
    VARIABLE seed4   : POSITIVE := 2;
    VARIABLE rand1   : real; -- random real-number value in range 0 to 1.0
    VARIABLE rand2   : real; -- random real-number value in range 0 to 1.0
    VARIABLE rand3   : real; -- random real-number value in range 0 to 1.0
    VARIABLE rand4   : real; -- random real-number value in range 0 to 1.0
    VARIABLE my_line : line; -- type 'line' comes from textio
  BEGIN

    IF (rst_n = '0') THEN
      inst_a    <= reset_in_out_rec;
      inst_b    <= reset_in_out_rec;
      inst_c    <= reset_in_out_rec;
      inst_d    <= reset_in_out_rec;
      inst_mode <= (OTHERS => '0');
      cnt       <= 0;
      conf      <= "00";
    ELSIF rising_edge(clk) THEN

      cnt <= cnt + 1;

      uniform(seed1, seed2, rand1); -- generate random number
      uniform(seed3, seed2, rand2); -- generate random number
      uniform(seed1, seed3, rand3); -- generate random number
      uniform(seed3, seed4, rand4); -- generate random number

      inst_a <= populate_in_out_rec(INTEGER(TRUNC(rand1 * 100000.0)), conf);
      inst_b <= populate_in_out_rec(INTEGER(TRUNC(rand2 * 100000.0)), conf);
      inst_c <= populate_in_out_rec(INTEGER(TRUNC(rand3 * 100000.0)), conf);
      inst_d <= populate_in_out_rec(INTEGER(TRUNC(rand4 * 100000.0)), conf);

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
    VARIABLE test_out_0  : in_out_data;
    VARIABLE test_out_1  : in_out_data;

    VARIABLE mac0        : INTEGER;
    VARIABLE mac1        : INTEGER;
    VARIABLE mac0_0      : INTEGER;
    VARIABLE mac0_1      : INTEGER;
    VARIABLE mac1_0      : INTEGER;
    VARIABLE mac1_1      : INTEGER;
    VARIABLE mac0_00     : INTEGER;
    VARIABLE mac0_01     : INTEGER;
    VARIABLE mac0_10     : INTEGER;
    VARIABLE mac0_11     : INTEGER;
    VARIABLE mac1_00     : INTEGER;
    VARIABLE mac1_01     : INTEGER;
    VARIABLE mac1_10     : INTEGER;
    VARIABLE mac1_11     : INTEGER;

    VARIABLE tmp_res0    : signed(bit_width * 2 - 1 DOWNTO 0);
    VARIABLE tmp_res1    : signed(bit_width * 2 - 1 DOWNTO 0);
    VARIABLE tmp_res0_0  : signed(bit_width - 1 DOWNTO 0);
    VARIABLE tmp_res0_1  : signed(bit_width - 1 DOWNTO 0);
    VARIABLE tmp_res1_0  : signed(bit_width - 1 DOWNTO 0);
    VARIABLE tmp_res1_1  : signed(bit_width - 1 DOWNTO 0);
    VARIABLE tmp_res0_00 : signed(bit_width / 2 - 1 DOWNTO 0);
    VARIABLE tmp_res0_01 : signed(bit_width / 2 - 1 DOWNTO 0);
    VARIABLE tmp_res0_10 : signed(bit_width / 2 - 1 DOWNTO 0);
    VARIABLE tmp_res0_11 : signed(bit_width / 2 - 1 DOWNTO 0);
    VARIABLE tmp_res1_00 : signed(bit_width / 2 - 1 DOWNTO 0);
    VARIABLE tmp_res1_01 : signed(bit_width / 2 - 1 DOWNTO 0);
    VARIABLE tmp_res1_10 : signed(bit_width / 2 - 1 DOWNTO 0);
    VARIABLE tmp_res1_11 : signed(bit_width / 2 - 1 DOWNTO 0);

    VARIABLE my_line     : line; -- type 'line' comes from textio
  BEGIN

    test_out_0 := reset_in_out_rec;
    test_out_1 := reset_in_out_rec;
    IF rst_n = '0' THEN
      mac0        := 0;
      mac1        := 0;
      mac0_0      := 0;
      mac0_1      := 0;
      mac1_0      := 0;
      mac1_1      := 0;
      mac0_00     := 0;
      mac0_01     := 0;
      mac0_10     := 0;
      mac0_11     := 0;
      mac1_00     := 0;
      mac1_01     := 0;
      mac1_10     := 0;
      mac1_11     := 0;

      tmp_res0    := (OTHERS => '0');
      tmp_res1    := (OTHERS => '0');
      tmp_res0_0  := (OTHERS => '0');
      tmp_res0_1  := (OTHERS => '0');
      tmp_res1_0  := (OTHERS => '0');
      tmp_res1_1  := (OTHERS => '0');
      tmp_res0_00 := (OTHERS => '0');
      tmp_res0_01 := (OTHERS => '0');
      tmp_res0_10 := (OTHERS => '0');
      tmp_res0_11 := (OTHERS => '0');
      tmp_res1_00 := (OTHERS => '0');
      tmp_res1_01 := (OTHERS => '0');
      tmp_res1_10 := (OTHERS => '0');
      tmp_res1_11 := (OTHERS => '0');

    END IF;

    IF conf = "00" THEN

      mac0       := to_integer(tmp_res0) + to_integer(inst_a.data) * to_integer(inst_b.data);
      mac1       := to_integer(tmp_res0) + to_integer(inst_c.data) * to_integer(inst_d.data);

      tmp_res0   := saturation(mac0, TB_MAC_MAX_VALUE, TB_MAC_MIN_VALUE);
      tmp_res1   := saturation(mac1, TB_MAC_MAX_VALUE, TB_MAC_MIN_VALUE);

      test_out_0 := populate_in_out_rec(mac0, conf);
      test_out_1 := populate_in_out_rec(mac1, conf);

      write(my_line, STRING'("### MAC 0 ###"));
      writeline(output, my_line);
      print_mac(mac0, to_integer(inst_a.data), to_integer(inst_b.data));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

      write(my_line, STRING'("### MAC 1 ###"));
      writeline(output, my_line);
      print_mac(mac1, to_integer(inst_c.data), to_integer(inst_d.data));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

    ELSIF conf = "01" THEN
      mac0_0     := to_integer(tmp_res0_0) + to_integer(inst_a.data_0) * to_integer(inst_b.data_0);
      mac0_1     := to_integer(tmp_res0_1) + to_integer(inst_a.data_1) * to_integer(inst_b.data_1);
      mac1_0     := to_integer(tmp_res1_0) + to_integer(inst_c.data_0) * to_integer(inst_c.data_0);
      mac1_1     := to_integer(tmp_res1_1) + to_integer(inst_c.data_1) * to_integer(inst_c.data_1);

      tmp_res0_0 := saturation(mac0_0, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);
      tmp_res0_1 := saturation(mac0_1, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);
      tmp_res1_0 := saturation(mac1_0, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);
      tmp_res1_1 := saturation(mac1_1, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);

      test_out_0 := populate_in_out_rec(mac0_1, mac0_0);
      test_out_1 := populate_in_out_rec(mac1_1, mac1_0);

      write(my_line, STRING'("### MAC 0_0 ###"));
      writeline(output, my_line);
      print_mac(mac0_0, to_integer(inst_a.data_0), to_integer(inst_b.data_0));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

      write(my_line, STRING'("### MAC 0_1 ###"));
      writeline(output, my_line);
      print_mac(mac0_1, to_integer(inst_a.data_1), to_integer(inst_b.data_1));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

      write(my_line, STRING'("### MAC 1_0 ###"));
      writeline(output, my_line);
      print_mac(mac1_0, to_integer(inst_c.data_0), to_integer(inst_d.data_0));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

      write(my_line, STRING'("### MAC 1_1 ###"));
      writeline(output, my_line);
      print_mac(mac1_1, to_integer(inst_c.data_1), to_integer(inst_d.data_1));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

    ELSIF conf = "11" THEN
      mac0_00     := to_integer(tmp_res0_00) + to_integer(inst_a.data_00) * to_integer(inst_b.data_00);
      mac0_01     := to_integer(tmp_res0_01) + to_integer(inst_a.data_01) * to_integer(inst_b.data_01);
      mac0_10     := to_integer(tmp_res0_10) + to_integer(inst_a.data_10) * to_integer(inst_b.data_10);
      mac0_11     := to_integer(tmp_res0_11) + to_integer(inst_a.data_11) * to_integer(inst_b.data_11);

      mac1_00     := to_integer(tmp_res1_00) + to_integer(inst_c.data_00) * to_integer(inst_c.data_00);
      mac1_01     := to_integer(tmp_res1_01) + to_integer(inst_c.data_01) * to_integer(inst_c.data_01);
      mac1_10     := to_integer(tmp_res1_10) + to_integer(inst_c.data_10) * to_integer(inst_c.data_10);
      mac1_11     := to_integer(tmp_res1_11) + to_integer(inst_c.data_11) * to_integer(inst_c.data_11);

      tmp_res0_00 := saturation(mac0_00, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);
      tmp_res0_01 := saturation(mac0_01, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);
      tmp_res0_10 := saturation(mac0_10, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);
      tmp_res0_11 := saturation(mac0_11, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);

      tmp_res1_00 := saturation(mac1_00, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);
      tmp_res1_01 := saturation(mac1_01, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);
      tmp_res1_10 := saturation(mac1_10, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);
      tmp_res1_11 := saturation(mac1_11, TB_MAC_MAX_VALUE_0, TB_MAC_MIN_VALUE_0);

      test_out_0  := populate_in_out_rec(mac0_11, mac0_10, mac0_01, mac0_00);
      test_out_1  := populate_in_out_rec(mac1_11, mac1_10, mac1_01, mac1_00);

      write(my_line, STRING'("### MAC 0_00 ###"));
      writeline(output, my_line);
      print_mac(mac0_00, to_integer(inst_a.data_00), to_integer(inst_b.data_00));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

      write(my_line, STRING'("### MAC 0_01 ###"));
      writeline(output, my_line);
      print_mac(mac0_01, to_integer(inst_a.data_01), to_integer(inst_b.data_01));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

      write(my_line, STRING'("### MAC 0_10 ###"));
      writeline(output, my_line);
      print_mac(mac0_10, to_integer(inst_a.data_10), to_integer(inst_b.data_10));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

      write(my_line, STRING'("### MAC 0_11 ###"));
      writeline(output, my_line);
      print_mac(mac0_11, to_integer(inst_a.data_11), to_integer(inst_b.data_11));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

      write(my_line, STRING'("### MAC 1_00 ###"));
      writeline(output, my_line);
      print_mac(mac1_00, to_integer(inst_c.data_00), to_integer(inst_d.data_00));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

      write(my_line, STRING'("### MAC 1_01 ###"));
      writeline(output, my_line);
      print_mac(mac1_01, to_integer(inst_c.data_01), to_integer(inst_d.data_01));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

      write(my_line, STRING'("### MAC 1_10 ###"));
      writeline(output, my_line);
      print_mac(mac1_10, to_integer(inst_c.data_10), to_integer(inst_d.data_10));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

      write(my_line, STRING'("### MAC 1_11 ###"));
      writeline(output, my_line);
      print_mac(mac1_11, to_integer(inst_c.data_11), to_integer(inst_d.data_11));
      write(my_line, STRING'("#############"));
      writeline(output, my_line);

    ELSIF conf = "10" THEN
      REPORT "ERROR conf 10 is not support!" SEVERITY failure;
    END IF;

    delay0_0 <= test_out_0;
    delay0_1 <= test_out_1;
  END PROCESS prod_calculation;

  --! Delay process for data synch
  P_delay : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      delay1_0  <= reset_in_out_rec;
      delay2_0  <= reset_in_out_rec;
      delay3_0  <= reset_in_out_rec;
      delay1_1  <= reset_in_out_rec;
      delay2_1  <= reset_in_out_rec;
      delay3_1  <= reset_in_out_rec;

      inst_a_d2 <= reset_in_out_rec;
      inst_b_d2 <= reset_in_out_rec;
      inst_c_d2 <= reset_in_out_rec;
      inst_d_d2 <= reset_in_out_rec;

      inst_a_d1 <= reset_in_out_rec;
      inst_b_d1 <= reset_in_out_rec;
      inst_c_d1 <= reset_in_out_rec;
      inst_d_d1 <= reset_in_out_rec;

    ELSIF rising_edge(clk) THEN
      delay1_0  <= delay0_0;
      delay2_0  <= delay1_0;
      delay3_0  <= delay2_0;
      delay1_1  <= delay0_1;
      delay2_1  <= delay1_1;
      delay3_1  <= delay2_1;

      inst_a_d1 <= inst_a;
      inst_b_d1 <= inst_b;
      inst_c_d1 <= inst_c;
      inst_d_d1 <= inst_d;

      inst_a_d2 <= inst_a_d1;
      inst_b_d2 <= inst_b_d1;
      inst_c_d2 <= inst_c_d1;
      inst_d_d2 <= inst_d_d1;
    END IF;
  END PROCESS;

  check_signal0 <= delay1_0 WHEN mac_pipe = 0 ELSE
    delay2_0;
  check_signal1 <= delay1_1 WHEN mac_pipe = 0 ELSE
    delay2_1;

  inst_a_s <= inst_a_d1 WHEN mac_pipe = 0 ELSE
    inst_a_d2;
  inst_b_s <= inst_b_d1 WHEN mac_pipe = 0 ELSE
    inst_b_d2;
  inst_c_s <= inst_c_d1 WHEN mac_pipe = 0 ELSE
    inst_c_d2;
  inst_d_s <= inst_d_d1 WHEN mac_pipe = 0 ELSE
    inst_d_d2;

  --! Monitor process
  --PROCESS (clk, rst_n)
  --BEGIN
  --
  --  IF (rst_n = '0') THEN
  --
  --  ELSIF falling_edge(clk) THEN
  --
  --    IF conf = "00" THEN
  --      ASSERT (check_signal0.DUT_Data = inst_out_0.DUT_data)
  --      REPORT "!!!!!!!!!!!!!!!!!!!!!!" & CR & "          !!!! Wrong result !!!!" & CR & "          !!!!!!!!!!!!!!!!!!!!!!" & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal0.data)) & " DUT output : " & INTEGER'IMAGE (to_integer(inst_out_0.data)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a_s.data)) & " " & INTEGER'IMAGE(to_integer(inst_b_s.data))
  --        SEVERITY failure;
  --      ASSERT (check_signal1.DUT_Data = inst_out_1.DUT_data)
  --      REPORT "!!!!!!!!!!!!!!!!!!!!!!" & CR & "          !!!! Wrong result !!!!" & CR & "          !!!!!!!!!!!!!!!!!!!!!!" & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal1.data)) & " DUT output : " & INTEGER'IMAGE (to_integer(inst_out_1.data)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_c_s.data)) & " " & INTEGER'IMAGE(to_integer(inst_d_s.data))
  --        SEVERITY failure;
  --
  --    ELSIF conf = "01" THEN
  --      ASSERT (check_signal0.DUT_Data = inst_out_0.DUT_data)
  --      REPORT "!!!!!!!!!!!!!!!!!!!!!!" & CR & "          !!!! Wrong result !!!!" & CR & "          !!!!!!!!!!!!!!!!!!!!!!" & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal0.data_0)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_0.data_0)) & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal0.data_1)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_0.data_1)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a_s.data_0)) & " " & INTEGER'IMAGE(to_integer(inst_b_s.data_0)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a_s.data_1)) & " " & INTEGER'IMAGE(to_integer(inst_b_s.data_1))
  --        SEVERITY failure;
  --      ASSERT (check_signal1.DUT_Data = inst_out_1.DUT_data)
  --      REPORT "!!!!!!!!!!!!!!!!!!!!!!" & CR & "          !!!! Wrong result !!!!" & CR & "          !!!!!!!!!!!!!!!!!!!!!!" & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal1.data_0)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_1.data_0)) & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal1.data_1)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_1.data_1)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_c_s.data_0)) & " " & INTEGER'IMAGE(to_integer(inst_d_s.data_0)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_c_s.data_1)) & " " & INTEGER'IMAGE(to_integer(inst_d_s.data_1))
  --        SEVERITY failure;
  --
  --    ELSIF conf = "11" THEN
  --      ASSERT (check_signal0.DUT_Data = inst_out_0.DUT_data)
  --      REPORT "!!!!!!!!!!!!!!!!!!!!!!" & CR & "          !!!! Wrong result !!!!" & CR & "          !!!!!!!!!!!!!!!!!!!!!!" & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal0.data_00)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_0.data_00)) & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal0.data_01)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_0.data_01)) & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal0.data_10)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_0.data_10)) & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal0.data_11)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_0.data_11)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a_s.data_00)) & " " & INTEGER'IMAGE(to_integer(inst_b_s.data_00)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a_s.data_01)) & " " & INTEGER'IMAGE(to_integer(inst_b_s.data_01)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a_s.data_10)) & " " & INTEGER'IMAGE(to_integer(inst_b_s.data_10)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_a_s.data_11)) & " " & INTEGER'IMAGE(to_integer(inst_b_s.data_11))
  --        SEVERITY failure;
  --      ASSERT (check_signal1.DUT_Data = inst_out_1.DUT_data)
  --      REPORT "!!!!!!!!!!!!!!!!!!!!!!" & CR & "          !!!! Wrong result !!!!" & CR & "          !!!!!!!!!!!!!!!!!!!!!!" & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal1.data_00)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_1.data_00)) & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal1.data_01)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_1.data_01)) & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal1.data_10)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_1.data_10)) & CR &
  --        "Expected outcome: " & INTEGER'IMAGE(to_integer(check_signal1.data_11)) & " DUT output : " & INTEGER'IMAGE(to_integer(inst_out_1.data_11)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_c_s.data_00)) & " " & INTEGER'IMAGE(to_integer(inst_d_s.data_00)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_c_s.data_01)) & " " & INTEGER'IMAGE(to_integer(inst_d_s.data_01)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_c_s.data_10)) & " " & INTEGER'IMAGE(to_integer(inst_d_s.data_10)) & CR &
  --        "Inputs are: " & INTEGER'IMAGE(to_integer(inst_c_s.data_11)) & " " & INTEGER'IMAGE(to_integer(inst_d_s.data_11))
  --        SEVERITY failure;
  --
  --    END IF;
  --
  --  END IF;
  --END PROCESS;

  --! Component definition
  DUT : ENTITY work.DPU
    PORT MAP(
      rst_n             => rst_n,
      clk               => clk,

      dpu_in_0          => signed(inst_a.DUT_data),
      dpu_in_1          => signed(inst_b.DUT_data),
      dpu_in_2          => signed(inst_c.DUT_data),
      dpu_in_3          => signed(inst_d.DUT_data),

      dpu_io_control    => inst_io,
      dpu_mode_cfg      => inst_mode,
      dpu_op_control    => conf,
      dpu_constant      => inst_constant,

      dpu_acc_clear_rst => inst_acc_clear_rst,
      dpu_acc_clear     => inst_acc_clear,

      dpu_out_0         => inst_out_0_data,
      dpu_out_1         => inst_out_1_data,

      seq_cond_status   => inst_seq_cond_status
    );

  inst_out_0 <= populate_in_out_rec(STD_LOGIC_VECTOR(inst_out_0_data), conf);
  inst_out_1 <= populate_in_out_rec(STD_LOGIC_VECTOR(inst_out_1_data), conf);

END ARCHITECTURE TB_DPU_V2;