-------------------------------------------------------
--! @file DPU.vhd
--! @brief DPU (Data processing unit)
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2021-05-03
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
-- Title      : DPU v2 (Data processing unit)
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : DPU.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2021-05-03
-- Last update: 2021-09-07
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2021-05-03  2.0      Dimitrios Stathis      Created
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
--! Use the DPU package
USE work.DPU_pkg.ALL;

--! This is a DPU for the SiLago fabrics

--! The DPU is a data processing unit. This version is build for the DRRA fabric
--! and is optimized for NNs, but can be modified to fit other applications and
--! designs. The DPU has a set of configuration inputs, together with a set of 
--! data inputs and outputs. In this version the DPU has 4 inputs and 2 outputs,
--! all inputs/outputs have a specific bitwidth. Supported formats: Integer (4-bit, 8-bit, 16-bit)
--! fixed point (Q4.11) format (set inside the DPU package).
ENTITY DPU IS
  PORT (
    rst_n             : IN STD_LOGIC;                                             --! Reset (active-low)
    clk               : IN STD_LOGIC;                                             --! Clock

    dpu_in_0          : IN signed (DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Signed input 0
    dpu_in_1          : IN signed (DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Signed input 1
    dpu_in_2          : IN signed (DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Signed input 2
    dpu_in_3          : IN signed (DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Signed input 3

    dpu_io_control    : IN STD_LOGIC_VECTOR(DPU_IO_CONF_WIDTH - 1 DOWNTO 0);      --! DPU I/O configuration, 00-no change, 01-negate in0/in2, 10-negate in1/in3, 11-return abs
    dpu_mode_cfg      : IN STD_LOGIC_VECTOR (DPU_MODE_CFG_WIDTH - 1 DOWNTO 0);    --! DPU mode configuration
    dpu_op_control    : IN STD_LOGIC_VECTOR(DPU_OP_CONF_WIDTH - 1 DOWNTO 0);      --! DPU operation control 16-Int, 16-FP, 8-Int, 4-Int
    dpu_constant      : IN STD_LOGIC_VECTOR(DPU_CONS_WIDTH - 1 DOWNTO 0);         --! Constant input from the instruction (sequencer), used for scaling or other operations

    dpu_acc_clear_rst : IN STD_LOGIC;                                             --! Reset the acc clear
    dpu_acc_clear     : IN STD_LOGIC_VECTOR (DPU_ACC_CLEAR_WIDTH - 1 DOWNTO 0);   --! Reset count (limit) for the accumulator, after this limit the acc resets.

    dpu_out_0         : OUT signed (DPU_OUT_WIDTH - 1 DOWNTO 0);                  --! Signed output 0
    dpu_out_1         : OUT signed (DPU_OUT_WIDTH - 1 DOWNTO 0);                  --! Signed output 1

    seq_cond_status   : OUT STD_LOGIC_VECTOR (SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0) --! Logic status (G, L, E)
  );
END DPU;

--! @brief This is the architecture of the SiLago DPU
--! @details The DPU is build using a number of separate 
--! data paths. Each data-path is meant to operate independently,
--! but they can also work together if required. The DPU also
--! contains a set of registers, that can be used to store constants
--! that are required for the computation.
ARCHITECTURE RTL OF DPU IS
  ------------------------------------------------------------------
  -- Input/output signals
  ------------------------------------------------------------------
  SIGNAL dpu_in_0_sig      : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Input value 0 that is controlled by the io signal
  SIGNAL dpu_in_1_sig      : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Input value 1 that is controlled by the io signal 
  SIGNAL dpu_in_2_sig      : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Input value 2 that is controlled by the io signal
  SIGNAL dpu_in_3_sig      : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Input value 3 that is controlled by the io signal  
  SIGNAL dpu_out_0_sig     : signed(DPU_OUT_WIDTH - 1 DOWNTO 0);                   --! Output values calculated and saturated by the DPU, its value will be assigned to the output of the DPU depending on the io signal
  SIGNAL dpu_out_1_sig     : signed(DPU_OUT_WIDTH - 1 DOWNTO 0);                   --! Output values calculated and saturated by the DPU, its value will be assigned to the output of the DPU depending on the io signal  
  ------------------------------------------------------------------
  -- NACU connections
  ------------------------------------------------------------------
  SIGNAL acc_clear         : STD_LOGIC;                                            --! Clear accumulator of nacu 0 and 1
  SIGNAL nacu_op_config    : STD_LOGIC_VECTOR(select_w - 1 DOWNTO 0);              --! Configuration signal for nacu operations
  SIGNAL nacu_mode_0       : unsigned (S_DPU_CFG_WIDTH - 1 DOWNTO 0);              --! NACU mode for unit 0
  SIGNAL nacu_mode_1       : unsigned (S_DPU_CFG_WIDTH - 1 DOWNTO 0);              --! NACU mode for unit 1
  SIGNAL nacu_in_0_0       : signed (S_DPU_IN_WIDTH - 1 DOWNTO 0);                 --! Input 0 for NACU 0
  SIGNAL nacu_in_0_1       : signed (S_DPU_IN_WIDTH - 1 DOWNTO 0);                 --! Input 1 for NACU 0
  SIGNAL nacu_in_1_0       : signed (S_DPU_IN_WIDTH - 1 DOWNTO 0);                 --! Input 0 for NACU 1
  SIGNAL nacu_in_1_1       : signed (S_DPU_IN_WIDTH - 1 DOWNTO 0);                 --! Input 1 for NACU 1
  SIGNAL seq_cond_status_0 : STD_LOGIC_VECTOR(SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0); --! Comparison result of nacu 0
  SIGNAL seq_cond_status_1 : STD_LOGIC_VECTOR(SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0); --! Comparison result of nacu 1
  SIGNAL nacu_out_0        : signed(S_DPU_OUT_WIDTH - 1 DOWNTO 0);                 --! Output result (2 x Bitwidth) from nacu 0
  SIGNAL nacu_out_1        : signed(S_DPU_OUT_WIDTH - 1 DOWNTO 0);                 --! Output result (2 x Bitwidth) from nacu 1
  SIGNAL direct_acc_0      : STD_LOGIC_VECTOR(ADD_I_W - 1 DOWNTO 0);               --! Direct accumulator input to NACU 0
  SIGNAL direct_acc_1      : STD_LOGIC_VECTOR(ADD_I_W - 1 DOWNTO 0);               --! Direct accumulator input to NACU 1
  SIGNAL direct_acc_en_0   : STD_LOGIC;                                            --! Enable the direct input to the NACU 0
  SIGNAL direct_acc_en_1   : STD_LOGIC;                                            --! Enable the direct input to the NACU 1
  SIGNAL direct_div_0      : STD_LOGIC_VECTOR(ADD_I_W - 1 DOWNTO 0);               --! Direct accumulator input to NACU 0
  SIGNAL direct_div_1      : STD_LOGIC_VECTOR(ADD_I_W - 1 DOWNTO 0);               --! Direct accumulator input to NACU 1
  SIGNAL direct_div_en_0   : STD_LOGIC;                                            --! Enable the direct input to the NACU 0
  SIGNAL direct_div_en_1   : STD_LOGIC;                                            --! Enable the direct input to the NACU 1
  ------------------------------------------------------------------
  -- Internal registers
  ------------------------------------------------------------------
  SIGNAL IR_in_0           : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Input to internal register 0
  SIGNAL IR_in_1           : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Input to internal register 1
  SIGNAL IR_0              : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Internal register 0
  SIGNAL IR_1              : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Internal register 1
  ------------------------------------------------------------------
  -- DPU mode and drive
  ------------------------------------------------------------------
  SIGNAL mode, mode_reg    : unsigned(DPU_MODE_CFG_WIDTH - 1 DOWNTO 0);            --! DPU mode configuration
  ------------------------------------------------------------------
  -- Accumulator clear control
  ------------------------------------------------------------------
  SIGNAL counter           : unsigned(DPU_ACC_CLEAR_WIDTH - 1 DOWNTO 0);           --! Counter (iterations of accumulation)
  SIGNAL acc_clear_enable  : STD_LOGIC;                                            --! Enable ACC reset
  ------------------------------------------------------------------
  -- Saturation
  ------------------------------------------------------------------
  SIGNAL sat_in_0          : STD_LOGIC_VECTOR(ACC_O_W - 1 DOWNTO 0);               --! Saturation input
  SIGNAL sat_in_1          : STD_LOGIC_VECTOR(ACC_O_W - 1 DOWNTO 0);               --! Saturation input
  SIGNAL sat_out_0         : STD_LOGIC_VECTOR(DPU_OUT_WIDTH - 1 DOWNTO 0);         --! Saturation output
  SIGNAL sat_out_1         : STD_LOGIC_VECTOR(DPU_OUT_WIDTH - 1 DOWNTO 0);         --! Saturation output
  ------------------------------------------------------------------
  -- Scaler
  ------------------------------------------------------------------
  SIGNAL scaler_in         : STD_LOGIC_VECTOR(DPU_IN_WIDTH - 1 DOWNTO 0);          --! Scaler input Data
  SIGNAL scale_factor      : STD_LOGIC_VECTOR(DPU_CONS_WIDTH - 1 DOWNTO 0);        --! Scaling value
  SIGNAL scale_up_dw       : STD_LOGIC;                                            --! Scale up or down from or to the current configuration, '1' scale up
  SIGNAL scaler_en         : STD_LOGIC;                                            --! Enable signal
  SIGNAL scaler_out        : STD_LOGIC_VECTOR(DPU_OUT_WIDTH - 1 DOWNTO 0);         --! Scaler output data 
  ------------------------------------------------------------------
  -- OTHERS
  ------------------------------------------------------------------
  SIGNAL dpu_in_0_neg      : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! in0*(-1)
  SIGNAL dpu_in_2_neg      : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! in2*(-1)
  SIGNAL dpu_in_1_neg      : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! in1*(-1)
  SIGNAL dpu_in_3_neg      : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! in3*(-1)
  SIGNAL acc_reg_SM        : STD_LOGIC_VECTOR(ACC_O_W - 1 DOWNTO 0);               --! Temp storage of the accumulation results for the softmax
  SIGNAL acc_reg_SM_in     : STD_LOGIC_VECTOR(ACC_O_W - 1 DOWNTO 0);               --! Input to Temp storage of the softmax accumulation
  SIGNAL acc_reg_SM_en     : STD_LOGIC;                                            --! Enable the store to temp softmax
BEGIN
  -- First nacu gives the cond status to the sequencer
  seq_cond_status <= seq_cond_status_0;
  --##############################
  -- Negation
  --------------------------------
  U_in_0_neg : ENTITY work.twos_compl
    GENERIC MAP(
      b_width => DPU_IN_WIDTH
    )
    PORT MAP(
      d_in  => dpu_in_0,
      d_out => dpu_in_0_neg
    );
  U_in_2_neg : ENTITY work.twos_compl
    GENERIC MAP(
      b_width => DPU_IN_WIDTH
    )
    PORT MAP(
      d_in  => dpu_in_2,
      d_out => dpu_in_2_neg
    );
  U_in_1_neg : ENTITY work.twos_compl
    GENERIC MAP(
      b_width => DPU_IN_WIDTH
    )
    PORT MAP(
      d_in  => dpu_in_1,
      d_out => dpu_in_1_neg
    );
  U_in_3_neg : ENTITY work.twos_compl
    GENERIC MAP(
      b_width => DPU_IN_WIDTH
    )
    PORT MAP(
      d_in  => dpu_in_3,
      d_out => dpu_in_3_neg
    );
  --##############################

  U_NACU_0 : ENTITY work.NACU
    GENERIC MAP(
      mac_pipe     => mac_pipe,
      squash_pipe  => squash_pipe,
      div_n_squash => div_n_squash_0
    )
    PORT MAP(
      clk             => clk,
      clear           => '0',
      rst_n           => rst_n,
      bit_config      => nacu_op_config,
      mode_cfg        => nacu_mode_0,
      acc_clear       => acc_clear,
      direct_acc      => direct_acc_0,
      direct_acc_en   => direct_acc_en_0,
      divide_acc      => direct_div_en_0,
      div_direct      => signed(direct_div_0),
      nacu_in_0       => nacu_in_0_0,
      nacu_in_1       => nacu_in_0_1,
      seq_cond_status => seq_cond_status_0,
      nacu_out        => nacu_out_0
    );

  U_NACU_1 : ENTITY work.NACU
    GENERIC MAP(
      mac_pipe     => mac_pipe,
      squash_pipe  => squash_pipe,
      div_n_squash => div_n_squash_1
    )
    PORT MAP(
      clk             => clk,
      clear           => '0',
      rst_n           => rst_n,
      bit_config      => nacu_op_config,
      mode_cfg        => nacu_mode_1,
      acc_clear       => acc_clear,
      direct_acc      => direct_acc_1,
      direct_acc_en   => direct_acc_en_1,
      divide_acc      => direct_div_en_1,
      div_direct      => signed(direct_div_1),
      nacu_in_0       => nacu_in_1_0,
      nacu_in_1       => nacu_in_1_1,
      seq_cond_status => seq_cond_status_1,
      nacu_out        => nacu_out_1
    );

  --##############################
  -- Registers
  --------------------------------
  --! Register process for the internal registers and other signals
  P_reg : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      IR_0           <= (OTHERS => '0');
      IR_1           <= (OTHERS => '0');
      mode_reg       <= (OTHERS => '0');
      acc_reg_SM     <= (OTHERS => '0');
      nacu_op_config <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      -- Internal registers
      IR_0 <= IR_in_0;
      IR_1 <= IR_in_1;
      -- mode
      IF dpu_op_control = "10" THEN
        nacu_op_config <= "00";
      ELSE
        nacu_op_config <= dpu_op_control;
      END IF;
      mode_reg <= unsigned(dpu_mode_cfg);
      -- Softmax accumulation register
      IF acc_reg_SM_en = '1' THEN
        acc_reg_SM <= acc_reg_SM_in;
      END IF;
    END IF;
  END PROCESS;
  --##############################

  --##############################
  -- Output control,
  -- Saturation and rounding
  --------------------------------
  --@TODO also do absolute value when needed
  --##############################

  U_sat_n_round_inst_0 : ENTITY work.Sat_n_round
    PORT MAP(
      d_in    => sat_in_0,
      d_mode  => dpu_op_control,
      op_mode => nacu_mode_0,
      d_out   => sat_out_0
    );

  U_sat_n_round_inst_1 : ENTITY work.Sat_n_round
    PORT MAP(
      d_in    => sat_in_1,
      d_mode  => dpu_op_control,
      op_mode => nacu_mode_1,
      d_out   => sat_out_1
    );

  dpu_out_0 <= ABS(dpu_out_0_sig) WHEN dpu_io_control = "11" ELSE
    dpu_out_0_sig;
  dpu_out_1 <= ABS(dpu_out_1_sig) WHEN dpu_io_control = "11" ELSE
    dpu_out_1_sig;

  dpu_in_0_sig <= dpu_in_0_neg WHEN dpu_io_control = "01" ELSE
    dpu_in_0;

  dpu_in_2_sig <= dpu_in_2_neg WHEN dpu_io_control = "01" ELSE
    dpu_in_2;

  dpu_in_1_sig <= dpu_in_1_neg WHEN dpu_io_control = "10" ELSE
    dpu_in_1;

  dpu_in_3_sig <= dpu_in_3_neg WHEN dpu_io_control = "10" ELSE
    dpu_in_3;
  --##############################
  -- Mode selection and driver
  --------------------------------
  --  mode <= unsigned(dpu_mode_cfg) WHEN to_integer(unsigned(dpu_mode_cfg)) /= IDLE ELSE mode_reg;
  mode <= mode_reg;
  P_comb : PROCESS (ALL)
  BEGIN
    scaler_in       <= (OTHERS => '0');
    scaler_en       <= '0';
    scale_up_dw     <= '0';
    scale_factor    <= (OTHERS => '0');
    nacu_in_0_0     <= (OTHERS => '0');
    nacu_in_0_1     <= (OTHERS => '0');
    nacu_in_1_0     <= (OTHERS => '0');
    nacu_in_1_1     <= (OTHERS => '0');
    nacu_mode_0     <= (OTHERS => '0');
    nacu_mode_1     <= (OTHERS => '0');
    direct_acc_0    <= (OTHERS => '0');
    direct_acc_1    <= (OTHERS => '0');
    direct_acc_en_0 <= '0';
    direct_acc_en_1 <= '0';
    sat_in_0        <= (OTHERS => '0');
    sat_in_1        <= (OTHERS => '0');
    dpu_out_0_sig   <= (OTHERS => '0');
    dpu_out_1_sig   <= (OTHERS => '0');
    direct_div_en_0 <= '0';
    direct_div_0    <= STD_LOGIC_VECTOR(to_signed(1, direct_div_0'length));
    direct_div_en_1 <= '0';
    direct_div_1    <= (OTHERS => '0');
    IR_in_0         <= IR_0;
    IR_in_1         <= IR_1;
    acc_reg_SM_in   <= acc_reg_SM;
    CASE to_integer(mode) IS
      WHEN IDLE =>
        -- Do nothing
        NULL;
      WHEN ADD =>
        -- Addition
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= dpu_in_1_sig;
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= dpu_in_3_sig;
        nacu_mode_0   <= to_unsigned(S_ADD, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_ADD, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN SUM_ACC =>
        -- Accumulation
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= (OTHERS => '0');
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= (OTHERS => '0');
        nacu_mode_0   <= to_unsigned(S_ACC, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_ACC, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN ADD_CONST =>
        -- Addition with IR
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= IR_0;
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= IR_1;
        nacu_mode_0   <= to_unsigned(S_ADD, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_ADD, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN SUBT =>
        -- Subtract
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= dpu_in_1_neg;
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= dpu_in_3_neg;
        nacu_mode_0   <= to_unsigned(S_ADD, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_ADD, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN SUBT_ABS =>
        -- Absolute value of subtraction
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= dpu_in_1_neg;
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= dpu_in_3_neg;
        nacu_mode_0   <= to_unsigned(S_ADD, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_ADD, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= ABS(signed(sat_out_0));
        dpu_out_1_sig <= ABS(signed(sat_out_1));
      WHEN MULT =>
        -- Multiply
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= dpu_in_1_sig;
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= dpu_in_3_sig;
        nacu_mode_0   <= to_unsigned(S_MUL, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_MUL, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN MULT_ADD =>
        -- Multiply and add
        nacu_in_0_0 <= dpu_in_0_sig;
        nacu_in_0_1 <= dpu_in_1_sig;
        -- enable direct input to the adder
        --------------------------------------------------------------------------------------------
        IF dpu_op_control = "10" THEN
          direct_acc_0 <= STD_LOGIC_VECTOR(shift_left(resize(dpu_in_2, direct_acc_0'length), fb));
        ELSE
          direct_acc_0 <= STD_LOGIC_VECTOR(resize(dpu_in_2, direct_acc_0'length));
        END IF;
        direct_acc_en_0 <= '1';
        --------------------------------------------------------------------------------------------
        nacu_in_1_0     <= (OTHERS => '0');
        nacu_in_1_1     <= (OTHERS => '0');
        nacu_mode_0     <= to_unsigned(S_MAC, nacu_mode_1'length);
        nacu_mode_1     <= to_unsigned(S_IDLE, nacu_mode_1'length);
        sat_in_0        <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1        <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig   <= signed(sat_out_0);
        dpu_out_1_sig   <= signed(sat_out_1);
      WHEN MULT_CONST =>
        -- Multiply with constant
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= IR_0;
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= IR_1;
        nacu_mode_0   <= to_unsigned(S_MUL, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_MUL, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN MAC =>
        -- Multiply and accumulate
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= dpu_in_1_sig;
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= dpu_in_3_sig;
        nacu_mode_0   <= to_unsigned(S_MAC, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_MAC, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN LD_IR =>
        -- Load internal registers
        IR_in_0 <= dpu_in_0_sig;
        IR_in_1 <= dpu_in_2_sig;
      WHEN AXPY =>
        -- A times IR plus Y
        nacu_in_0_0 <= dpu_in_0_sig;
        nacu_in_0_1 <= IR_0;
        nacu_in_1_0 <= dpu_in_2_sig;
        nacu_in_1_1 <= IR_1;
        --------------------------------------------------------------------------------------------
        IF dpu_op_control = "10" THEN
          direct_acc_0 <= STD_LOGIC_VECTOR(shift_left(resize(dpu_in_1, direct_acc_0'length), fb));
          direct_acc_0 <= STD_LOGIC_VECTOR(shift_left(resize(dpu_in_3, direct_acc_0'length), fb));
        ELSE
          direct_acc_0 <= STD_LOGIC_VECTOR(resize(dpu_in_1, direct_acc_0'length));
          direct_acc_1 <= STD_LOGIC_VECTOR(resize(dpu_in_3, direct_acc_1'length));
        END IF;
        direct_acc_en_0 <= '1';
        direct_acc_en_1 <= '1';
        --------------------------------------------------------------------------------------------
        nacu_mode_0     <= to_unsigned(S_MAC, nacu_mode_1'length);
        nacu_mode_1     <= to_unsigned(S_MAC, nacu_mode_1'length);
        sat_in_0        <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1        <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig   <= signed(sat_out_0);
        dpu_out_1_sig   <= signed(sat_out_1);
      WHEN MAX_MIN_ACC =>
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= signed(sat_out_0);
        nacu_in_1_0   <= dpu_in_0_sig;
        nacu_in_1_1   <= signed(sat_out_1);
        nacu_mode_0   <= to_unsigned(S_MAX, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_MIN, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN MAX_MIN_CONST =>
        -- Max and Min with constant (IR)
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= IR_0;
        nacu_in_1_0   <= dpu_in_0_sig;
        nacu_in_1_1   <= IR_0;
        nacu_mode_0   <= to_unsigned(S_MAX, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_MIN, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN MAX_MIN =>
        -- Min and Max
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= dpu_in_1_sig;
        nacu_in_1_0   <= dpu_in_0_sig;
        nacu_in_1_1   <= dpu_in_1_sig;
        nacu_mode_0   <= to_unsigned(S_MAX, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_MIN, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN SHIFT_L =>
        -- Shift left
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= dpu_in_1_sig;
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= dpu_in_3_sig;
        nacu_mode_0   <= to_unsigned(S_SHIFT_L, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_SHIFT_L, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN SHIFT_R =>
        -- Shift right
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= dpu_in_1_sig;
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= dpu_in_3_sig;
        nacu_mode_0   <= to_unsigned(S_SHIFT_R, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_SHIFT_R, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN SIGM =>
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= (OTHERS => '0');
        nacu_in_1_0   <= (OTHERS => '0');
        nacu_in_1_1   <= (OTHERS => '0');
        nacu_mode_0   <= to_unsigned(S_SIGM, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_IDLE, nacu_mode_1'length);
        sat_in_0      <= (OTHERS => '0');
        sat_in_1      <= (OTHERS => '0');
        dpu_out_1_sig <= (OTHERS => '0');
        dpu_out_0_sig <= signed(nacu_out_0(DPU_OUT_WIDTH - 1 DOWNTO 0)); -- SIGM only uses 16-bit output the rest are unused
      WHEN TANHYP =>
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= (OTHERS => '0');
        nacu_in_1_0   <= (OTHERS => '0');
        nacu_in_1_1   <= (OTHERS => '0');
        nacu_mode_0   <= to_unsigned(S_TANHYP, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_IDLE, nacu_mode_1'length);
        sat_in_0      <= (OTHERS => '0');
        sat_in_1      <= (OTHERS => '0');
        dpu_out_1_sig <= (OTHERS => '0');
        dpu_out_0_sig <= signed(nacu_out_0(DPU_OUT_WIDTH - 1 DOWNTO 0)); -- SIGM only uses 16-bit output the rest are unused
      WHEN EXPON =>
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= (OTHERS => '0');
        nacu_in_1_0   <= (OTHERS => '0');
        nacu_in_1_1   <= (OTHERS => '0');
        nacu_mode_0   <= to_unsigned(S_EXPON, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_IDLE, nacu_mode_1'length);
        sat_in_0      <= (OTHERS => '0');
        sat_in_1      <= (OTHERS => '0');
        dpu_out_1_sig <= (OTHERS => '0');
        dpu_out_0_sig <= signed(nacu_out_0(DPU_OUT_WIDTH - 1 DOWNTO 0));
      WHEN LK_RELU =>
        -- First DPU does the comparison second DPU does the multiplication in case is < 0
        nacu_in_0_0   <= dpu_in_0;
        nacu_in_0_1   <= to_signed(0, nacu_in_0_1'length);
        nacu_in_1_0   <= dpu_in_0;
        nacu_in_1_1   <= resize(signed('0' & unsigned(dpu_constant)), nacu_in_0_1'length);
        nacu_mode_0   <= to_unsigned(S_MAX, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_MUL, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_1_sig <= (OTHERS => '0');
        IF to_integer(unsigned(seq_cond_status_0)) = SEQ_STATUS_GT THEN
          dpu_out_0_sig <= signed(sat_out_0);
        ELSE
          dpu_out_0_sig <= signed(sat_out_1);
        END IF;
      WHEN RELU =>
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= to_signed(0, nacu_in_0_1'length);
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= to_signed(0, nacu_in_0_1'length);
        nacu_mode_0   <= to_unsigned(S_MAX, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_MAX, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_1_sig <= (OTHERS => '0');
        -- @TODO we probably do not need the if here, since the max will return either 0 or the input
        IF to_integer(unsigned(seq_cond_status_0)) = SEQ_STATUS_GT THEN
          dpu_out_0_sig <= signed(sat_out_0);
        ELSE
          dpu_out_0_sig <= (OTHERS => '0');
        END IF;
        IF to_integer(unsigned(seq_cond_status_1)) = SEQ_STATUS_GT THEN
          dpu_out_1_sig <= signed(sat_out_1);
        ELSE
          dpu_out_1_sig <= (OTHERS => '0');
        END IF;
      WHEN DIV =>
        -- Division
        -- @TODO need to include the remainder
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= dpu_in_1_sig;
        nacu_in_1_0   <= (OTHERS => '0');
        nacu_in_1_1   <= (OTHERS => '0');
        nacu_mode_0   <= to_unsigned(S_DIV, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_IDLE, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= (OTHERS => '0');
        dpu_out_1_sig <= (OTHERS => '0');
        dpu_out_0_sig <= signed(sat_out_0);
      WHEN ACC_SOFTMAX =>
        -- Soft max accumulation TODO
        nacu_in_0_0     <= dpu_in_0_sig;
        --------------------------------------------------------------------------------------------
        direct_acc_0    <= (OTHERS => '0');
        direct_acc_en_0 <= '0';
        direct_acc_1    <= (OTHERS => '0');
        direct_acc_en_1 <= '0';
        --------------------------------------------------------------------------------------------
        nacu_in_0_1     <= (OTHERS => '0');
        nacu_in_1_0     <= dpu_in_0_sig;
        nacu_in_1_1     <= (OTHERS => '0');
        nacu_mode_0     <= to_unsigned(S_IDLE, nacu_mode_1'length);
        nacu_mode_1     <= to_unsigned(S_ACC, nacu_mode_1'length);
        sat_in_0        <= (OTHERS => '0');
        sat_in_1        <= STD_LOGIC_VECTOR(nacu_out_1);
        acc_reg_SM_in   <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig   <= (OTHERS => '0');
        dpu_out_1_sig   <= signed(sat_out_1);
      WHEN SM =>
        -- Softmax division (divide with accumulator)
        nacu_in_0_0     <= dpu_in_0_sig;
        --------------------------------------------------------------------------------------------
        direct_div_en_0 <= '1';
        direct_div_0    <= acc_reg_SM;
        direct_div_en_1 <= '0';
        direct_div_1    <= (OTHERS => '0');
        --------------------------------------------------------------------------------------------
        nacu_in_0_1     <= (OTHERS => '0');
        nacu_in_1_0     <= (OTHERS => '0');
        nacu_in_1_1     <= (OTHERS => '0');
        nacu_mode_0     <= to_unsigned(S_DIV, nacu_mode_1'length);
        nacu_mode_1     <= to_unsigned(S_IDLE, nacu_mode_1'length);
        sat_in_0        <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1        <= (OTHERS => '0');
        dpu_out_1_sig   <= (OTHERS => '0');
        dpu_out_0_sig   <= signed(sat_out_0);
      WHEN LD_ACC =>
        -- Load accumulators with initial value
        nacu_in_0_0 <= dpu_in_0_sig;
        nacu_in_0_1 <= (OTHERS => '0');
        nacu_in_1_0 <= dpu_in_2_sig;
        nacu_in_1_1 <= (OTHERS => '0');
        nacu_mode_0 <= to_unsigned(S_LD_ACC, nacu_mode_1'length);
        nacu_mode_1 <= to_unsigned(S_LD_ACC, nacu_mode_1'length);
      WHEN SCALE_DW            =>
        -- Scale down from 16-bit to the configured width TODO
        nacu_in_0_0   <= (OTHERS => '0');
        nacu_in_0_1   <= (OTHERS => '0');
        nacu_in_1_0   <= (OTHERS => '0');
        nacu_in_1_1   <= (OTHERS => '0');
        nacu_mode_0   <= to_unsigned(S_IDLE, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_IDLE, nacu_mode_1'length);
        sat_in_0      <= (OTHERS => '0');
        sat_in_1      <= (OTHERS => '0');
        scale_up_dw   <= '0';
        scaler_en     <= '1';
        scaler_in     <= STD_LOGIC_VECTOR(dpu_in_0);
        scale_factor  <= dpu_constant;
        sat_in_0      <= (OTHERS => '0');
        sat_in_1      <= (OTHERS => '0');
        dpu_out_1_sig <= (OTHERS => '0');
        dpu_out_0_sig <= signed(scaler_out);
      WHEN SCALE_UP            =>
        -- Scale up from the configured width to 16 bit TODO
        nacu_in_0_0   <= (OTHERS => '0');
        nacu_in_0_1   <= (OTHERS => '0');
        nacu_in_1_0   <= (OTHERS => '0');
        nacu_in_1_1   <= (OTHERS => '0');
        nacu_mode_0   <= to_unsigned(S_IDLE, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_IDLE, nacu_mode_1'length);
        sat_in_0      <= (OTHERS => '0');
        sat_in_1      <= (OTHERS => '0');
        scale_up_dw   <= '1';
        scaler_en     <= '1';
        scaler_in     <= STD_LOGIC_VECTOR(dpu_in_0);
        scale_factor  <= dpu_constant;
        sat_in_0      <= (OTHERS => '0');
        sat_in_1      <= (OTHERS => '0');
        dpu_out_1_sig <= (OTHERS => '0');
        dpu_out_0_sig <= signed(scaler_out);
      WHEN MAC_inter =>
        -- Multiply and accumulate with internal register
        nacu_in_0_0   <= dpu_in_0_sig;
        nacu_in_0_1   <= IR_0;
        nacu_in_1_0   <= dpu_in_2_sig;
        nacu_in_1_1   <= IR_1;
        nacu_mode_0   <= to_unsigned(S_MAC, nacu_mode_1'length);
        nacu_mode_1   <= to_unsigned(S_MAC, nacu_mode_1'length);
        sat_in_0      <= STD_LOGIC_VECTOR(nacu_out_0);
        sat_in_1      <= STD_LOGIC_VECTOR(nacu_out_1);
        dpu_out_0_sig <= signed(sat_out_0);
        dpu_out_1_sig <= signed(sat_out_1);
      WHEN OTHERS =>
        NULL;
    END CASE;
  END PROCESS;

  --##############################

  --##############################
  -- Accumulator clear
  --------------------------------

  P_acc_clear : PROCESS (counter, dpu_constant, acc_clear_enable, dpu_acc_clear_rst)
  BEGIN
    acc_clear <= '0';
    IF ((acc_clear_enable = '1') AND (counter = unsigned(dpu_constant))) OR (dpu_acc_clear_rst = '1') THEN
      acc_clear <= '1';
    END IF;
  END PROCESS;

  P_count : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      counter <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      IF acc_clear = '1' THEN
        counter <= (OTHERS => '0');
      ELSE
        counter <= counter + 1;
      END IF;
    END IF;
  END PROCESS;

  --##############################

  --##############################
  -- Scaling
  --------------------------------
  U_scaler : ENTITY work.scaler
    PORT MAP(
      rst_n        => rst_n,
      clk          => clk,
      data_in      => scaler_in,
      scale_factor => scale_factor,
      scale_up_dw  => scale_up_dw,
      op_conf      => nacu_op_config,
      enable       => scaler_en,
      data_out     => scaler_out
    );
  --##############################

END RTL;
