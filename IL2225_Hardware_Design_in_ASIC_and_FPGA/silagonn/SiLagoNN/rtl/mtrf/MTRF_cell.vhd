-------------------------------------------------------
--! @file MTRF_cell.vhd
--! @brief MTRF_cell
--! @details 
--! @author Nasim Farahini
--! @version 2.0
--! @date 2020-02-079
--! @bug NONE
--! @todo Check registered process for connection between DiMArch and RF file.
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
-- Title      : MTRF_cell
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : MTRF_cell.vhd
-- Author     : Nasim Farahini
-- Company    : KTH
-- Created    : 2014-02-26
-- Last update: 2021-09-07
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2014
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2014-02-25  1.0      Nasim Farahini          Created
-- 2020-02-07  2.0      Dimitrios Stathis       Added shadow register
-- 2021-08-17  3.0      Dimitrios Stathis       Change to reconfigurable DPU
-- 2021-08-26  3.1      Dimitrios Stathis       Remove the RLE from the cell itself
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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.seq_functions_package.ALL;
USE work.util_package.ALL;
USE work.top_consts_types_package.ALL;
USE work.noc_types_n_constants.NOC_BUS_TYPE;
USE work.DPU_pkg.DPU_OP_CONF_WIDTH;
USE work.DPU_pkg.DPU_CONS_WIDTH;
USE work.DPU_pkg.DPU_IO_CONF_WIDTH;

ENTITY MTRF_cell IS
  PORT (
    clk                  : IN STD_LOGIC;
    rst_n                : IN STD_LOGIC;
    instr_ld             : IN STD_LOGIC;
    instr_inp            : IN STD_LOGIC_VECTOR(INSTR_WIDTH - 1 DOWNTO 0);
    seq_address_rb       : IN STD_LOGIC;
    seq_address_cb       : IN STD_LOGIC;
    ----------------------------------------------------
    -- REV 2 2020-02-07 ------------------------------- 
    ----------------------------------------------------
    immediate            : IN STD_LOGIC;
    ----------------------------------------------------
    -- End of modification REV 2 -----------------------
    ----------------------------------------------------
    --RegFile
    data_in_reg_0        : IN signed(REG_FILE_DATA_WIDTH - 1 DOWNTO 0);
    data_in_reg_1        : IN signed(REG_FILE_DATA_WIDTH - 1 DOWNTO 0);
    --DiMArch
    dimarch_data_in      : IN STD_LOGIC_VECTOR(REG_FILE_MEM_DATA_WIDTH - 1 DOWNTO 0);
    dimarch_data_out     : OUT STD_LOGIC_VECTOR(REG_FILE_MEM_DATA_WIDTH - 1 DOWNTO 0);
    dimarch_rd_2_out     : OUT STD_LOGIC;
    data_out_reg_0_right : OUT signed(REG_FILE_DATA_WIDTH - 1 DOWNTO 0);
    data_out_reg_0_left  : OUT signed(REG_FILE_DATA_WIDTH - 1 DOWNTO 0);
    data_out_reg_1_right : OUT signed(REG_FILE_DATA_WIDTH - 1 DOWNTO 0);
    data_out_reg_1_left  : OUT signed(REG_FILE_DATA_WIDTH - 1 DOWNTO 0);
    --DPU
    dpu_in_0             : IN signed(DPU_IN_WIDTH - 1 DOWNTO 0);   --signed
    dpu_in_1             : IN signed(DPU_IN_WIDTH - 1 DOWNTO 0);   --signed
    dpu_in_2             : IN signed(DPU_IN_WIDTH - 1 DOWNTO 0);   --signed
    dpu_in_3             : IN signed(DPU_IN_WIDTH - 1 DOWNTO 0);   --signed
    dpu_out_0_left       : OUT signed(DPU_OUT_WIDTH - 1 DOWNTO 0); --signed
    dpu_out_0_right      : OUT signed(DPU_OUT_WIDTH - 1 DOWNTO 0); --signed
    dpu_out_1_left       : OUT signed(DPU_OUT_WIDTH - 1 DOWNTO 0); --signed
    dpu_out_1_right      : OUT signed(DPU_OUT_WIDTH - 1 DOWNTO 0); --signed
    --DiMArch instruction
    noc_bus_out          : OUT NOC_BUS_TYPE;
    s_bus_out            : OUT STD_LOGIC_VECTOR(SWB_INSTR_PORT_SIZE - 1 DOWNTO 0)
  );
END ENTITY MTRF_cell;

ARCHITECTURE rtl OF MTRF_cell IS

  SIGNAL dpu_mode_cfg_w                                                                                    : STD_LOGIC_VECTOR(DPU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL dpu_acc_clear_w                                                                                   : STD_LOGIC_VECTOR(DPU_ACC_CLEAR_WIDTH - 1 DOWNTO 0);
  SIGNAL dpu_ctrl_out_0_w                                                                                  : STD_LOGIC_VECTOR(DPU_CTRL_OUT_WIDTH - 1 DOWNTO 0);
  SIGNAL dpu_ctrl_out_1_w                                                                                  : STD_LOGIC_VECTOR(DPU_CTRL_OUT_WIDTH - 1 DOWNTO 0);
  SIGNAL dpu_sat_ctrl_w                                                                                    : STD_LOGIC_VECTOR(DPU_SAT_CTRL_WIDTH - 1 DOWNTO 0);
  SIGNAL dpu_process_inout_w                                                                               : STD_LOGIC_VECTOR(DPU_PROCESS_INOUT_WIDTH - 1 DOWNTO 0);
  SIGNAL dpu_acc_clear_rst_w                                                                               : STD_LOGIC;
  SIGNAL reg_initial_delay_w                                                                               : STD_LOGIC_VECTOR(INIT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL instr_start_w                                                                                     : STD_LOGIC;
  SIGNAL reg_start_addrs_w                                                                                 : STD_LOGIC_VECTOR(STARTING_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_step_val_w                                                                                    : STD_LOGIC_VECTOR(STEP_VALUE_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_step_val_sign_w                                                                               : STD_LOGIC_VECTOR(STEP_VALUE_SIGN_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_no_of_addrs_w                                                                                 : STD_LOGIC_VECTOR(NR_OF_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_port_type_w                                                                                   : STD_LOGIC_VECTOR(NR_OF_REG_FILE_PORTS_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_outp_cntrl_w                                                                                  : STD_LOGIC_VECTOR(OUTPUT_CONTROL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_middle_delay_w                                                                                : STD_LOGIC_VECTOR(REG_FILE_MIDDLE_DELAY_PORT_SIZE - 1 DOWNTO 0);
  SIGNAL reg_no_of_rpts_w                                                                                  : STD_LOGIC_VECTOR(NUM_OF_REPT_PORT_SIZE - 1 DOWNTO 0);
  SIGNAL reg_rpt_step_value_w                                                                              : STD_LOGIC_VECTOR(REP_STEP_VALUE_PORT_SIZE - 1 DOWNTO 0);
  SIGNAL reg_rpt_delay_w                                                                                   : STD_LOGIC_VECTOR(REPT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_mode_w                                                                                        : STD_LOGIC_VECTOR(MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_fft_stage_w, reg_end_fft_stage_w                                                              : STD_LOGIC_VECTOR(FFT_STAGE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL use_compr                                                                                         : STD_LOGIC;
  SIGNAL seq_cond_status_w                                                                                 : STD_LOGIC_VECTOR(SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0);
  SIGNAL dimarch_mode                                                                                      : STD_LOGIC;
  SIGNAL dpu_process_inout                                                                                 : STD_LOGIC_VECTOR(DPU_PROCESS_INOUT_WIDTH - 1 DOWNTO 0);
  ----------------------------------------------------
  -- REV 2 2020-02-07 ------------------------------- 
  ----------------------------------------------------
  SIGNAL immediate_sig                                                                                     : STD_LOGIC; --! Instruction issued from the sequencer is an immediate instruction

  SIGNAL dpu_mode_cfg_w_sig                                                                                : STD_LOGIC_VECTOR(DPU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL dpu_acc_clear_w_sig                                                                               : STD_LOGIC_VECTOR(DPU_ACC_CLEAR_WIDTH - 1 DOWNTO 0);
  SIGNAL dpu_ctrl_out_0_w_sig                                                                              : STD_LOGIC_VECTOR(DPU_CTRL_OUT_WIDTH - 1 DOWNTO 0);
  SIGNAL dpu_ctrl_out_1_w_sig                                                                              : STD_LOGIC_VECTOR(DPU_CTRL_OUT_WIDTH - 1 DOWNTO 0);
  SIGNAL dpu_sat_ctrl_w_sig                                                                                : STD_LOGIC_VECTOR(DPU_SAT_CTRL_WIDTH - 1 DOWNTO 0);
  SIGNAL dpu_process_inout_w_sig                                                                           : STD_LOGIC_VECTOR(DPU_PROCESS_INOUT_WIDTH - 1 DOWNTO 0);
  SIGNAL dpu_acc_clear_rst_w_sig                                                                           : STD_LOGIC;
  SIGNAL noc_bus_out_sig                                                                                   : NOC_BUS_TYPE;
  SIGNAL s_bus_out_sig                                                                                     : STD_LOGIC_VECTOR(SWB_INSTR_PORT_SIZE - 1 DOWNTO 0);
  ----------------------------------------------------
  -- End of modification REV 2 -----------------------
  ----------------------------------------------------

  ----------------------------------------------------
  -- REV 3 2021-08-17 -------------------------------- 
  ----------------------------------------------------
  SIGNAL dpu_out_0                                                                                         : signed(DPU_OUT_WIDTH - 1 DOWNTO 0);               --! Output of the DPU
  SIGNAL dpu_out_1                                                                                         : signed(DPU_OUT_WIDTH - 1 DOWNTO 0);               --! Output of the DPU
  SIGNAL dpu_op_control                                                                                    : STD_LOGIC_VECTOR(DPU_OP_CONF_WIDTH - 1 DOWNTO 0); --! DPU operation control 16-Int, 16-FP, 8-Int, 4-Int
  SIGNAL dpu_constant                                                                                      : STD_LOGIC_VECTOR(DPU_CONS_WIDTH - 1 DOWNTO 0);    --! Constant input from the instruction (sequencer), used for scaling or other operations
  SIGNAL dpu_io_control                                                                                    : STD_LOGIC_VECTOR(DPU_IO_CONF_WIDTH - 1 DOWNTO 0); --! DPU I/O configuration, 00-no change, 01-negate in0/in2, 10-negate in1/in3, 11-return abs
  ----------------------------------------------------
  -- End of modification REV 3 -----------------------
  ----------------------------------------------------
  -- Compression Engine Signal    s
  SIGNAL rf_in_from_dimarch, rf_out_to_dimarch, rle_engine_in, rle_engine_out                              : STD_LOGIC_VECTOR(REG_FILE_MEM_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL rf_block_write, rf_block_write_regin, rf_block_read, rf_block_read_regin, rle_valid_in, dec_com_n : STD_LOGIC;

BEGIN

  seq_gen : ENTITY work.sequencer
    --GENERIC MAP(M => MAX_NR_OF_OUTP_N_HOPS - 1)
    PORT MAP(
      reg_dimarch_mode   => dimarch_mode,
      NOC_BUS_OUT        => noc_bus_out_sig,
      clk                => clk,
      rst_n              => rst_n,
      instr_ld           => instr_ld,
      instr_inp          => instr_inp,
      immediate          => immediate,
      seq_address_rb     => seq_address_rb,
      seq_address_cb     => seq_address_cb,
      seq_cond_status    => seq_cond_status_w,
      dpu_cfg            => dpu_mode_cfg_w,
      dpu_ctrl_out_2     => dpu_ctrl_out_0_w,
      dpu_ctrl_out_3     => dpu_ctrl_out_1_w,
      dpu_acc_clear_rst  => dpu_acc_clear_rst_w,
      dpu_acc_clear      => dpu_acc_clear_w,
      dpu_sat_ctrl       => dpu_sat_ctrl_w,
      dpu_process_inout  => dpu_process_inout_w,
      instr_start        => instr_start_w,
      reg_port_type      => reg_port_type_w,
      reg_start_addrs    => reg_start_addrs_w,
      reg_no_of_addrs    => reg_no_of_addrs_w,
      reg_initial_delay  => reg_initial_delay_w,
      reg_step_val       => reg_step_val_w,
      reg_step_val_sign  => reg_step_val_sign_w,
      reg_middle_delay   => reg_middle_delay_w,
      reg_no_of_rpts     => reg_no_of_rpts_w,
      reg_rpt_step_value => reg_rpt_step_value_w,
      reg_rpt_delay      => reg_rpt_delay_w,
      reg_mode           => reg_mode_w,
      reg_outp_cntrl     => reg_outp_cntrl_w,
      reg_fft_stage      => reg_fft_stage_w,
      reg_end_fft_stage  => reg_end_fft_stage_w,
      reg_use_compr      => use_compr,
      ----------------------------------------------------
      -- REV 2 2020-02-07 ------------------------------- 
      ----------------------------------------------------
      immediate_out      => immediate_sig,
      ----------------------------------------------------
      -- End of modification REV 2 -----------------------
      ----------------------------------------------------

      ----------------------------------------------------
      -- REV 3 2021-08-17 -------------------------------- 
      ----------------------------------------------------
      dpu_op_control     => dpu_op_control,
      ----------------------------------------------------
      -- End of modification REV 2 -----------------------
      ----------------------------------------------------
      s_bus_out          => s_bus_out_sig
    );

  ----------------------------------------------------
  -- REV 2 2020-02-07 ------------------------------- 
  ----------------------------------------------------
  -- Shadow register
  shadowReg : ENTITY work.shadowReg
    PORT MAP(
      rst_n                 => rst_n,
      clk                   => clk,
      -- Launching signal
      immediate             => immediate_sig,
      --<Instruction Inputs>--
      -- DPU
      dpu_cfg               => dpu_mode_cfg_w,
      dpu_ctrl_out_2 => (OTHERS => '0'),
      dpu_ctrl_out_3 => (OTHERS => '0'),
      dpu_acc_clear_rst     => dpu_acc_clear_rst_w,
      dpu_acc_clear         => dpu_acc_clear_w,
      dpu_sat_ctrl          => dpu_sat_ctrl_w,
      dpu_process_inout     => dpu_process_inout_w,
      -- Dimarch related
      NOC_BUS_OUT           => noc_bus_out_sig,
      -- Switchbox
      s_bus_out             => s_bus_out_sig,
      --<Instruction Outputs>--
      -- DPU
      dpu_cfg_out           => dpu_mode_cfg_w_sig,
      --dpu_ctrl_out_2_out    => NULL,
      --dpu_ctrl_out_3_out    => NULL,
      dpu_acc_clear_rst_out => dpu_acc_clear_rst_w_sig,
      dpu_acc_clear_out     => dpu_acc_clear_w_sig,
      dpu_sat_ctrl_out      => dpu_sat_ctrl_w_sig,
      dpu_process_inout_out => dpu_process_inout_w_sig,
      -- Dimarch related
      NOC_BUS_OUT_out       => noc_bus_out,
      -- Switchbox
      s_bus_out_out         => s_bus_out
    );
  ----------------------------------------------------
  -- End of modification REV 2 -----------------------
  ----------------------------------------------------
  dpu_gen : ENTITY work.DPU
    PORT MAP(
      clk               => clk,
      rst_n             => rst_n,
      -- Dpu inputs
      dpu_in_0          => dpu_in_0,
      dpu_in_1          => dpu_in_1,
      dpu_in_2          => dpu_in_2,
      dpu_in_3          => dpu_in_3,
      -- Dpu configuration
      dpu_io_control    => dpu_process_inout_w,
      dpu_op_control    => dpu_op_control,
      dpu_mode_cfg      => dpu_mode_cfg_w_sig,
      dpu_acc_clear_rst => dpu_acc_clear_rst_w_sig,
      dpu_acc_clear     => dpu_acc_clear_w_sig,
      dpu_constant      => dpu_acc_clear_w_sig, -- the constant and acc_clear value share the same space in the instruction
      -- Dpu outputs
      dpu_out_0         => dpu_out_0,
      dpu_out_1         => dpu_out_1,
      -- Feedback to the sequencer 
      seq_cond_status   => seq_cond_status_w
    );

  ----------------------------------------------------
  -- REV 3 2021-08-17 -------------------------------- 
  ----------------------------------------------------
  dpu_out_0_left       <= dpu_out_0;
  dpu_out_1_left       <= dpu_out_1;
  dpu_out_0_right      <= dpu_out_0;
  dpu_out_1_right      <= dpu_out_1;
  ----------------------------------------------------
  -- End of modification REV 3 -----------------------
  ----------------------------------------------------

  -- #################### RLE Engine ####################

  rf_block_write_regin <= '1' WHEN (reg_port_type_w = "00" AND dimarch_mode = '1') ELSE
    '0';
  rf_block_read_regin <= '1' WHEN (reg_port_type_w = "10" AND dimarch_mode = '1') ELSE
    '0';
  rle_valid_in <= '1' WHEN ((rf_block_write OR rf_block_read) AND use_compr) = '1' ELSE
    '0';
  dec_com_n <= '1' WHEN (rf_block_write AND use_compr) = '1' ELSE
    '0';
  --------------------------------------------------------------------------------
  -- TODO check these registered processes (could be sources for bugs)
  --------------------------------------------------------------------------------
  reg_write_rf_block_ops : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      rf_block_write <= '0';
    ELSIF rising_edge(clk) THEN
      IF (instr_start_w = '1' AND dimarch_mode = '1') THEN
        rf_block_write <= rf_block_write_regin;
      END IF;
    END IF;
  END PROCESS;

  reg_read_rf_block_ops : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      rf_block_read <= '0';
    ELSIF rising_edge(clk) THEN
      IF (instr_start_w = '1' AND dimarch_mode = '1') THEN
        rf_block_read <= rf_block_read_regin;
      END IF;
    END IF;
  END PROCESS;
  --------------------------------------------------------------------------------
  ----------------------------------------------------
  -- REV 3.1 2021-08-26 ------------------------------
  ----------------------------------------------------
  write_to_rf_proc : PROCESS (rf_block_write, use_compr, rle_engine_out, dimarch_data_in)
  BEGIN
    IF rf_block_write = '1' THEN -- Writing to RF
      --IF use_compr = '1' THEN
      --  rf_in_from_dimarch <= rle_engine_out;
      --ELSE
      rf_in_from_dimarch <= dimarch_data_in;
      --END IF;
    ELSE
      rf_in_from_dimarch <= (OTHERS => '0');
    END IF;
  END PROCESS;

  read_from_rf_proc : PROCESS (rf_block_read, use_compr, rle_engine_out, rf_out_to_dimarch)
  BEGIN
    IF rf_block_read = '1' THEN -- Reading from RF
      --IF use_compr = '1' THEN
      --  dimarch_data_out <= rle_engine_out;
      --ELSE
      dimarch_data_out <= rf_out_to_dimarch;
      --END IF;
    ELSE
      dimarch_data_out <= (OTHERS => '0');
    END IF;
  END PROCESS;

  --RLE_input_proc : PROCESS (dimarch_data_in, rf_out_to_dimarch, rf_block_write, rf_block_read, use_compr)
  --BEGIN
  --  IF use_compr = '1' THEN
  --    IF rf_block_write = '1' THEN
  --      rle_engine_in <= dimarch_data_in;
  --    ELSIF rf_block_read = '1' THEN
  --      rle_engine_in <= rf_out_to_dimarch;
  --    ELSE
  --      rle_engine_in <= (OTHERS => '0');
  --    END IF;
  --  ELSE
  --    rle_engine_in <= (OTHERS => '0');
  --  END IF;
  --END PROCESS;
  --
  --RLE_engine : ENTITY work.RLE_engine
  --  GENERIC MAP(
  --    Nw => MEM_BLOCK_SIZE,
  --    Wp => RLE_WP, -- Optimal number of Words in parallel
  --    Nb => BITWIDTH
  --  )
  --  PORT MAP(
  --    clk       => clk,
  --    rst_n     => rst_n,
  --    valid_in  => rle_valid_in,
  --    dec_com_n => dec_com_n,
  --    d_in      => rle_engine_in,
  --    d_out     => rle_engine_out
  --  );
  ----------------------------------------------------
  -- End of modification REV 3.1 ---------------------
  ----------------------------------------------------

  -- #################### End RLE Engine ####################

  reg_top : ENTITY work.register_file_top
    PORT MAP(
      dimarch_data_in      => rf_in_from_dimarch,
      dimarch_data_out     => rf_out_to_dimarch,
      dimarch_rd_2_out     => dimarch_rd_2_out,
      rst_n                => rst_n,
      clk                  => clk,
      immediate            => immediate_sig,
      instr_start          => instr_start_w,
      reg_port_type        => reg_port_type_w,
      instr_initial_delay  => reg_initial_delay_w,
      instr_start_addrs    => reg_start_addrs_w,
      instr_step_val       => reg_step_val_w,
      instr_step_val_sign  => reg_step_val_sign_w,
      instr_no_of_addrs    => reg_no_of_addrs_w,
      instr_middle_delay   => reg_middle_delay_w,
      instr_no_of_rpts     => reg_no_of_rpts_w,
      instr_rpt_step_value => reg_rpt_step_value_w,
      instr_rpt_delay      => reg_rpt_delay_w,
      data_in_reg_0        => data_in_reg_0,
      data_in_reg_1        => data_in_reg_1,
      reg_outp_cntrl       => reg_outp_cntrl_w,
      dimarch_mode         => dimarch_mode,
      data_out_reg_0_right => data_out_reg_0_right,
      data_out_reg_0_left  => data_out_reg_0_left,
      data_out_reg_1_right => data_out_reg_1_right,
      data_out_reg_1_left  => data_out_reg_1_left
    );

END ARCHITECTURE rtl;
