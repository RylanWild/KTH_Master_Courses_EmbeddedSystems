-------------------------------------------------------
--! @file sequencer.vhd
--! @brief Sequencer
--! @details Re-configurable sequencer for the DRRA
--! @author Sadiq Hemani
--! @version 6.0
--! @date 2013-08-14
--! @bug NONE
--! @todo move the registers outside to the devices
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
-- Title	  : Sequencer
-- Project	: SiLago
-------------------------------------------------------------------------------
-- File	   : sequencer.vhd
-- Author	 : Sadiq Hemani
-- Company	: KTH
-- Created	: 2013-08-14
-- Last update: 2022-02-03
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2013
-------------------------------------------------------------------------------
-- Contact	: Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Rev 1: Sadiq Hemani. 2013 08 14.
--			  Rewritten the design to be more parametric where the
--			  instruction formats are records.
--			  Used a state machine (Moore) approach to switch between the different
--			  modes of the Sequencer.
--			  Added Refi1,Refi2,Refi3,DPU,Jump,Delay type of instructions.
--
-- Rev 2: Sadiq Hemani. 2013 08 20.
--			  Changed state machine to be Mealy (from Moore) due to one cycle lost during
--			  config state.
--
-- Rev 3: Sadiq Hemani. 2013 08 26.
--			  Major changes include:
--			  rewriting the decode logic to infer far less flops by
--			  using combinatorial processes that enable registers when needed.
--			  Added a variable pc, to be flexible enough to accommodate no-linear pc increment
--			  modes when refi instructions include extensions.
--			  Added swb instructions. (2013 10 10)
-- Rev 4: Nasim Farahini. 2014 02 26.   
-- Rev 5: Hassan Sohofi. 2015 02 22.
--			  Adding branch instruction.
-- Rev 6: Stathis Dimitrios 2020 02 02
--			  Adding shadow registers   
-- Rev 7: Stathis Dimitrios
--			  Adding the autoloop
-- Rev 8: Addition of BW configuration instruction
-- Rev 9: Stathis Dimitrios fixed sync bug in loop
-- Rev 10: Dimitrios Stathis      Change to adapt new functionality of the autoloop rev1.2
-------------------------------------------------------------------------------

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
--																		 #
--This file is part of SiLago.											 #
--																		 #
--	SiLago platform source code is distributed freely: you can		   #
--	redistribute it and/or modify it under the terms of the GNU		  #
--	General Public License as published by the Free Software Foundation, #
--	either version 3 of the License, or (at your option) any			 #
--	later version.													   #
--																		 #
--	SiLago is distributed in the hope that it will be useful,			#
--	but WITHOUT ANY WARRANTY; without even the implied warranty of	   #
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the		#
--	GNU General Public License for more details.						 #
--																		 #
--	You should have received a copy of the GNU General Public License	#
--	along with SiLago.  If not, see <https://www.gnu.org/licenses/>.	 #
--																		 #
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
--instr_ld is de-asserted at the same time as the last instruction is being sent
--from the tb

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.top_consts_types_package.ALL;
USE work.seq_functions_package.ALL;
USE work.util_package.ALL;
USE work.isa_package.ALL;
USE work.noc_types_n_constants.ALL;
USE work.DPU_pkg.DPU_OP_CONF_WIDTH;

ENTITY sequencer IS
  --GENERIC (
  --  -- ADDRESS : natural RANGE 0 TO 4*COLUMNS;
  --  M : NATURAL);

  PORT (
    clk                : IN STD_LOGIC;
    rst_n              : IN STD_LOGIC;
    instr_ld           : IN STD_LOGIC;
    instr_inp          : IN STD_LOGIC_VECTOR(INSTR_WIDTH - 1 DOWNTO 0);
    seq_address_rb     : IN STD_LOGIC; -- range 0 to 4*ROWS;
    seq_address_cb     : IN STD_LOGIC; -- range 0 to 4*COLUMNS;
    seq_cond_status    : IN STD_LOGIC_VECTOR(SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0);
    ----------------------------------------------------
    -- REV 6 2020-02-07 -------------------------------- 
    ----------------------------------------------------
    immediate          : IN STD_LOGIC;                                         --! Bit signaling the immediate execution of the instruction
    ----------------------------------------------------
    -- End of modification REV 6 -----------------------
    ----------------------------------------------------

    ----------------------------------------------------
    -- REV 8 2021-08-18 --------------------------------
    ----------------------------------------------------
    dpu_op_control     : OUT STD_LOGIC_VECTOR(DPU_OP_CONF_WIDTH - 1 DOWNTO 0); --! Configuration for the arithmetic operations bitwidth

    ----------------------------------------------------
    -- End of modification REV 8 -----------------------
    ----------------------------------------------------

    --<DPU ports>--
    dpu_cfg            : OUT STD_LOGIC_VECTOR(DPU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
    dpu_ctrl_out_2     : OUT STD_LOGIC_VECTOR(DPU_OUTP_A_VECTOR_SIZE - 1 DOWNTO 0);
    dpu_ctrl_out_3     : OUT STD_LOGIC_VECTOR(DPU_OUTP_B_VECTOR_SIZE - 1 DOWNTO 0);
    dpu_acc_clear_rst  : OUT STD_LOGIC;
    dpu_acc_clear      : OUT STD_LOGIC_VECTOR(DPU_ACC_CLEAR_WIDTH - 1 DOWNTO 0);
    dpu_sat_ctrl       : OUT STD_LOGIC_VECTOR(DPU_SAT_CTRL_WIDTH - 1 DOWNTO 0);
    dpu_process_inout  : OUT STD_LOGIC_VECTOR (DPU_PROCESS_INOUT_WIDTH - 1 DOWNTO 0);

    --<AGU ports>--
    reg_port_type      : OUT STD_LOGIC_VECTOR(NR_OF_REG_FILE_PORTS_VECTOR_SIZE - 1 DOWNTO 0);
    reg_start_addrs    : OUT STD_LOGIC_VECTOR(STARTING_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
    reg_no_of_addrs    : OUT STD_LOGIC_VECTOR(NR_OF_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
    reg_initial_delay  : OUT STD_LOGIC_VECTOR(INIT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);

    reg_step_val       : OUT STD_LOGIC_VECTOR(STEP_VALUE_VECTOR_SIZE - 1 DOWNTO 0);
    reg_step_val_sign  : OUT STD_LOGIC_VECTOR(STEP_VALUE_SIGN_VECTOR_SIZE - 1 DOWNTO 0);
    reg_middle_delay   : OUT STD_LOGIC_VECTOR(REG_FILE_MIDDLE_DELAY_PORT_SIZE - 1 DOWNTO 0);
    reg_no_of_rpts     : OUT STD_LOGIC_VECTOR(NUM_OF_REPT_PORT_SIZE - 1 DOWNTO 0);
    reg_rpt_step_value : OUT STD_LOGIC_VECTOR(REP_STEP_VALUE_PORT_SIZE - 1 DOWNTO 0);
    reg_dimarch_mode   : OUT STD_LOGIC;
    reg_use_compr      : OUT STD_LOGIC;
    instr_start        : OUT STD_LOGIC;

    reg_rpt_delay      : OUT STD_LOGIC_VECTOR(REPT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
    reg_mode           : OUT STD_LOGIC_VECTOR(MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
    reg_outp_cntrl     : OUT STD_LOGIC_VECTOR(OUTPUT_CONTROL_VECTOR_SIZE - 1 DOWNTO 0);
    reg_fft_stage      : OUT STD_LOGIC_VECTOR(FFT_STAGE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
    reg_end_fft_stage  : OUT STD_LOGIC_VECTOR(FFT_STAGE_SEL_VECTOR_SIZE - 1 DOWNTO 0);

    NOC_BUS_OUT        : OUT NOC_BUS_TYPE;

    s_bus_out          : OUT STD_LOGIC_VECTOR(SWB_INSTR_PORT_SIZE - 1 DOWNTO 0);
    ----------------------------------------------------
    -- REV 6 2020-02-07 ------------------------------- 
    ----------------------------------------------------
    immediate_out      : OUT STD_LOGIC
    ----------------------------------------------------
    -- End of modification REV 6 -----------------------
    ----------------------------------------------------

  );
END;

ARCHITECTURE behv OF sequencer IS
  SIGNAL seq_address_match                            : STD_LOGIC;                              -- is asserted when the address from the bus matches the address of the sequencer.
  SIGNAL new_instr_ld                                 : STD_LOGIC;                              -- flags that a new instruction is ready
  SIGNAL instr_ld_counter                             : unsigned(INSTR_REG_DEPTH - 1 DOWNTO 0); -- track the number of instrs in the instr. REGISTER
  SIGNAL delay_counter                                : unsigned(DLY_CYCLES_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL pc                                           : unsigned(PC_SIZE - 1 DOWNTO 0);                 -- program counter
  SIGNAL pc_increm                                    : STD_LOGIC_VECTOR(PC_INCREM_WIDTH - 1 DOWNTO 0); --programmable increment value FOR
  SIGNAL pc_increm_set                                : STD_LOGIC_VECTOR(PC_INCREM_WIDTH - 1 DOWNTO 0);
  --pc = 1 by default
  SIGNAL instr_reg                                    : Instr_reg_ty;                               -- Instruction REGISTER
  ----------------------------------------------------
  -- REV 6 2020-02-07 ------------------------------- 
  ----------------------------------------------------
  SIGNAL immediate_reg                                : STD_LOGIC_VECTOR(INSTR_DEPTH - 1 DOWNTO 0); --! Immediate bit for each instruction
  SIGNAL immediate_sig                                : STD_LOGIC;                                  --! Intermediate immediate signal, for delaying the execution of the RACCU instruction

  SIGNAL raccu_in1_sd_sh                              : STD_LOGIC;
  SIGNAL raccu_in1_sh                                 : STD_LOGIC_VECTOR(RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL raccu_in2_sd_sh                              : STD_LOGIC;
  SIGNAL raccu_in2_sh                                 : STD_LOGIC_VECTOR(RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL raccu_cfg_mode_sh                            : STD_LOGIC_VECTOR (RACCU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL raccu_res_address_sh                         : STD_LOGIC_VECTOR (RACCU_RESULT_ADDR_VECTOR_SIZE - 1 DOWNTO 0);

  SIGNAL raccu_in1_sd_sig                             : STD_LOGIC;
  SIGNAL raccu_in1_sig                                : STD_LOGIC_VECTOR(RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL raccu_in2_sd_sig                             : STD_LOGIC;
  SIGNAL raccu_in2_sig                                : STD_LOGIC_VECTOR(RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL raccu_cfg_mode_sig                           : STD_LOGIC_VECTOR (RACCU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL raccu_res_address_sig                        : STD_LOGIC_VECTOR (RACCU_RESULT_ADDR_VECTOR_SIZE - 1 DOWNTO 0);
  ----------------------------------------------------
  -- End of modification REV 6 -----------------------
  ----------------------------------------------------

  SIGNAL valid_instr                                  : STD_LOGIC;                                  -- flag to indicate that a valid instr has been detected in the "instr_code" field
  SIGNAL config_count_en                              : STD_LOGIC;                                  -- flag to indicate whether to load config instructions and increment instr_ld_counter

  -- instruction has been decoded
  SIGNAL instr                                        : STD_LOGIC_VECTOR(INSTR_WIDTH - 1 DOWNTO 0); -- instruction to be decoded
  SIGNAL dpu_instr                                    : DPU_instr_type;
  SIGNAL branch_instr                                 : BRANCH_instr_type;
  SIGNAL jump_instr                                   : JUMP_instr_type;
  SIGNAL delay_instr                                  : WAIT_instr_type;
  SIGNAL swb_instr                                    : STD_LOGIC_VECTOR(INSTR_WIDTH - 1 DOWNTO 0);
  SIGNAL raccu_instr                                  : RACCU_instr_type;

  SIGNAL reg_start_addrs_tmp                          : STD_LOGIC_VECTOR(STARTING_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_no_of_addrs_tmp                          : STD_LOGIC_VECTOR(NR_OF_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_initial_delay_tmp                        : STD_LOGIC_VECTOR(INIT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_rpt_delay_tmp                            : STD_LOGIC_VECTOR(REPT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_mode_tmp                                 : STD_LOGIC_VECTOR(MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_outp_cntrl_tmp                           : STD_LOGIC_VECTOR(OUTPUT_CONTROL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_fft_stage_tmp                            : STD_LOGIC_VECTOR(FFT_STAGE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_end_fft_stage_tmp                        : STD_LOGIC_VECTOR(FFT_STAGE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_step_val_tmp                             : STD_LOGIC_VECTOR(STEP_VALUE_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_step_val_sign_tmp                        : STD_LOGIC; --VECTOR(STEP_VALUE_SIGN_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL reg_middle_delay_tmp                         : STD_LOGIC_VECTOR(REG_FILE_MIDDLE_DELAY_PORT_SIZE - 1 DOWNTO 0);
  SIGNAL reg_no_of_rpts_tmp                           : STD_LOGIC_VECTOR(NUM_OF_REPT_PORT_SIZE - 1 DOWNTO 0);
  SIGNAL reg_rpt_step_value_tmp                       : STD_LOGIC_VECTOR(REP_STEP_VALUE_PORT_SIZE - 1 DOWNTO 0);
  SIGNAL reg_dimarch_mode_tmp                         : STD_LOGIC;
  SIGNAL reg_use_compr_tmp                            : STD_LOGIC;

  SIGNAL instr_refi2                                  : STD_LOGIC_VECTOR(INSTR_WIDTH - 1 DOWNTO 0); --packed			
  SIGNAL instr_refi3                                  : STD_LOGIC_VECTOR(INSTR_WIDTH - 1 DOWNTO 0); --packed
  SIGNAL dpu_acc_clear_tmp                            : STD_LOGIC_VECTOR(DPU_ACC_CLEAR_WIDTH - 1 DOWNTO 0);
  SIGNAL reg_outport_en                               : STD_LOGIC;
  SIGNAL dpu_outport_en                               : STD_LOGIC;
  SIGNAL swb_outport_en                               : STD_LOGIC;
  SIGNAL pc_count_en                                  : STD_LOGIC;
  SIGNAL delay_count_en                               : STD_LOGIC;
  SIGNAL delay_count_eq                               : STD_LOGIC;
  SIGNAL non_lin_pc                                   : STD_LOGIC;
  SIGNAL jump_mode                                    : STD_LOGIC;                      --! indicates when a jump instruction is active
  SIGNAL jump_addrs                                   : unsigned(PC_SIZE - 1 DOWNTO 0); --! Jump address from jump instruction
  SIGNAL subseq_refi_instrs                           : STD_LOGIC;
  SIGNAL ext_flag_middle_delay                        : STD_LOGIC;
  SIGNAL ext_flag_no_of_rpt                           : STD_LOGIC;
  SIGNAL ext_flag_rpt_step_value                      : STD_LOGIC;
  SIGNAL no_more_instr                                : STD_LOGIC;
  SIGNAL instr_ld_counter_rst                         : STD_LOGIC;
  SIGNAL pres_state, next_state                       : State_ty;
  --<RACCU>
  SIGNAL raccu_result_addrs_tmp                       : STD_LOGIC_VECTOR(RACCU_RESULT_ADDR_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL raccu_mode_tmp                               : STD_LOGIC_VECTOR(RACCU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL raccu_op1_tmp                                : STD_LOGIC_VECTOR(RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL raccu_op2_tmp                                : STD_LOGIC_VECTOR(RACCU_OPERAND2_VECTOR_SIZE - 1 DOWNTO 0);
  SIGNAL raccu_reg_out                                : raccu_reg_out_ty;
  SIGNAL raccu_op1_sd                                 : STD_LOGIC;
  SIGNAL raccu_op2_sd                                 : STD_LOGIC;
  SIGNAL loop_jump_mode                               : STD_LOGIC;
  SIGNAL loop_mode                                    : STD_LOGIC;
  ----------------------------------------------------
  -- REV 6 2020-02-14 --------------------------------
  ----------------------------------------------------
  SIGNAL NOC_BUS_OUT_sig                              : NOC_BUS_TYPE;
  ----------------------------------------------------
  -- End of modification REV 6 -----------------------
  ----------------------------------------------------
  ----------------------------------------------------
  -- REV 8 2021-08-18 --------------------------------
  ----------------------------------------------------
  ALIAS bw_control                                    : STD_LOGIC_VECTOR(DPU_OP_CONF_WIDTH - 1 DOWNTO 0) IS instr(INSTR_CODE_RANGE_END - 1 DOWNTO INSTR_CODE_RANGE_END - 2);
  ----------------------------------------------------
  -- End of modification REV 8 -----------------------
  ----------------------------------------------------
  -- segmented bus output 
  ALIAS O_BUS_ENABLE                                  : STD_LOGIC IS NOC_BUS_OUT_sig.bus_enable;
  ALIAS O_instr_code                                  : STD_LOGIC_VECTOR(INS_WIDTH - 1 DOWNTO 0) IS NOC_BUS_OUT_sig.instr_code;

  -- PATH SETUP FLAGS
  ALIAS O_inter                                       : STD_LOGIC IS NOC_BUS_OUT_sig.INSTRUCTION(INTERMEDIATE_NODE_FLAG_l);    -- IF 1 THEN INTERMEDIATE node instruction 
  ALIAS O_inter_f                                     : STD_LOGIC IS NOC_BUS_OUT_sig.INSTRUCTION(INTERMEDIATE_SEGMENT_FLAG_l); -- IF 1 THEN INTERMEDIATE segment source to intermediate 
  ALIAS O_rw                                          : STD_LOGIC IS NOC_BUS_OUT_sig.INSTRUCTION(READ_WRITE_l);                -- IF 1 write else read
  -- ADDRESSES 

  SIGNAL instr_1                                      : STD_LOGIC_VECTOR(INSTR_WIDTH - 1 DOWNTO 0);
  SIGNAL instr_2                                      : STD_LOGIC_VECTOR(INSTR_WIDTH - 1 DOWNTO 0);
  ALIAS instr_code_alias                              : STD_LOGIC_VECTOR(3 DOWNTO 0) IS instr(INSTR_CODE_RANGE_BASE DOWNTO INSTR_CODE_RANGE_END); -- this should be parameterized

  ----------------------------------------------------
  -- REV 7 2020-05-25 --------------------------------
  ----------------------------------------------------
  SIGNAL pc_jump_select                               : STD_LOGIC;                                                                                --! Signal selecting either jump from loop or from jump instruction
  SIGNAL pc_jump_sel_addr                             : unsigned(PC_SIZE - 1 DOWNTO 0);                                                           --! Jump address either from jump or loop 

  SIGNAL pc_from_loop                                 : unsigned(PC_SIZE - 1 DOWNTO 0);                                                           --! Program counter.
  SIGNAL jump_loop                                    : STD_LOGIC;                                                                                --! Signal the sequencer that the goto address should be the one used to update the program counter.
  SIGNAL instr_loop, instr_loop_tmp, instr_loop_sh    : STD_LOGIC;                                                                                --! Bit signaling the configuration of the autoloop unit.
  SIGNAL config_loop, config_loop_tmp, config_loop_sh : For_instr_ty;                                                                             --! Configuration input of autoloop
  ----------------------------------------------------
  -- End of modification REV 7 -----------------------
  ----------------------------------------------------

  ----------------------------------------------------
  -- REV 9 -------------------------------------------
  ----------------------------------------------------
  SIGNAL jump_loop_sig                                : STD_LOGIC;                                                                                --! Signal selecting either jump from loop or from jump instruction (selected between stored and current)
  SIGNAL pc_from_loop_sig                             : unsigned(PC_SIZE - 1 DOWNTO 0);                                                           --! Jump address either from jump or loop (selected between stored and current)
  SIGNAL jump_loop_reg                                : STD_LOGIC;                                                                                --! Signal selecting either jump from loop or from jump instruction (registered when delay instruction is active)
  SIGNAL pc_from_loop_reg                             : unsigned(PC_SIZE - 1 DOWNTO 0);                                                           --! Jump address either from jump or loop (registered when delay instruction is active)
  ----------------------------------------------------
  -- End of modification REV 9 -----------------------
  ----------------------------------------------------

  ----------------------------------------------------
  -- REV 8 2021-08-18 --------------------------------
  ----------------------------------------------------
  SIGNAL dpu_op_control_reg                           : STD_LOGIC_VECTOR(DPU_OP_CONF_WIDTH - 1 DOWNTO 0);                                         --! Configuration for the arithmetic operations bitwidth
  ----------------------------------------------------
  -- End of modification REV 8 -----------------------
  ----------------------------------------------------
BEGIN                                                                                                                                           -- architecture behv

  seq_address_match <= seq_address_rb AND seq_address_cb;
  new_instr_ld      <= seq_address_match AND instr_ld;

  -------------------------------------------------------------------------------------------------------------------
  --  RACCU Instantiation
  -------------------------------------------------------------------------------------------------------------------
  u_Raccu : ENTITY work.RaccuAndLoop
    PORT MAP(
      rst_n             => rst_n,
      clk               => clk,
      instr_loop        => instr_loop,
      config_loop       => config_loop,
      pc                => pc,
      pc_out            => pc_from_loop,
      jump              => jump_loop,
      raccu_in1         => raccu_in1_sig,
      raccu_in2         => raccu_in2_sig,
      raccu_cfg_mode    => raccu_cfg_mode_sig,
      raccu_res_address => raccu_res_address_sig,
      raccu_regout      => raccu_reg_out,
      ----------------------------------------------------
      -- REV 10 2022-03-18 -------------------------------
      ----------------------------------------------------
      is_delay          => delay_count_en,
      ----------------------------------------------------
      -- End of modification REV 10 ----------------------
      ----------------------------------------------------
      en => (OTHERS => '1')
    );

  --<LOADS NEW INSTRUCTIONS TO THE MEMORY>--
  instr_reg_load_proc : PROCESS (clk, rst_n)
  BEGIN               -- PROCESS p0
    IF rst_n = '0' THEN -- asynchronous reset (active low)
      instr_reg     <= (OTHERS => (OTHERS => '0'));
      ----------------------------------------------------
      -- REV 6 2020-02-07 ------------------------------- 
      ----------------------------------------------------
      immediate_reg <= (OTHERS => '0');
      ----------------------------------------------------
      -- End of modification REV 6 -----------------------
      ----------------------------------------------------
    ELSIF rising_edge(clk) THEN -- rising clock edge
      IF (config_count_en = '1') AND (new_instr_ld = '1') THEN
        instr_reg(to_integer(instr_ld_counter))     <= instr_inp;
        ----------------------------------------------------
        -- REV 6 2020-02-07 ------------------------------- 
        ----------------------------------------------------
        immediate_reg(to_integer(instr_ld_counter)) <= immediate;
        ----------------------------------------------------
        -- End of modification REV 6 -----------------------
        ----------------------------------------------------
      END IF;
    END IF;
  END PROCESS instr_reg_load_proc;

  --<INCREMENTS INSTRUCTION LOAD COUNTER>--
  pc_increm_proc : PROCESS (clk, rst_n)
  BEGIN               -- PROCESS p1
    IF rst_n = '0' THEN -- asynchronous reset (active low)
      instr_ld_counter <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN -- rising clock edge
      IF (config_count_en = '1') THEN
        IF (instr_ld_counter < INSTR_DEPTH - 1 AND new_instr_ld = '1') THEN
          instr_ld_counter <= instr_ld_counter + 1;
        END IF;
      END IF;
      IF (instr_ld_counter_rst = '1') THEN
        instr_ld_counter <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS pc_increm_proc;

  instr         <= instr_reg(to_integer(pc));
  instr_1       <= instr_reg(to_integer(pc + 1));
  instr_2       <= instr_reg(to_integer(pc + 2));
  ----------------------------------------------------
  -- REV 6 2020-02-07 ------------------------------- 
  ----------------------------------------------------
  -- Immediate signals 
  immediate_sig <= immediate_reg(to_integer(pc));

  --<RACCU Shadow register>--
  --! Shadow register for raccu configuration (@TODO should be moved in the RACCU)
  shadow : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      raccu_in1_sd_sh      <= ('0');
      raccu_in1_sh         <= (OTHERS => '0');
      raccu_in2_sd_sh      <= ('0');
      raccu_in2_sh         <= (OTHERS => '0');
      raccu_cfg_mode_sh    <= (OTHERS => '0');
      raccu_res_address_sh <= (OTHERS => '0');
      config_loop_sh       <= for_instr_zero;
      instr_loop_sh        <= '0';
    ELSIF rising_edge(clk) THEN
      IF immediate_sig = '1' THEN
        raccu_in1_sd_sh      <= ('0');
        raccu_in1_sh         <= (OTHERS => '0');
        raccu_in2_sd_sh      <= ('0');
        raccu_in2_sh         <= (OTHERS => '0');
        raccu_cfg_mode_sh    <= (OTHERS => '0');
        raccu_res_address_sh <= (OTHERS => '0');
        config_loop_sh       <= for_instr_zero;
        instr_loop_sh        <= '0';
      ELSE
        IF to_integer(unsigned(raccu_mode_tmp)) /= RAC_MODE_IDLE THEN -- Only register new values if new instruction for RACCU is generated
          raccu_in1_sd_sh      <= raccu_op1_sd;
          raccu_in1_sh         <= raccu_op1_tmp;
          raccu_in2_sd_sh      <= raccu_op2_sd;
          raccu_in2_sh         <= raccu_op2_tmp;
          raccu_cfg_mode_sh    <= raccu_mode_tmp;
          raccu_res_address_sh <= raccu_result_addrs_tmp;
          instr_loop_sh        <= instr_loop_tmp;
        END IF;
        IF instr_loop_tmp = '1' THEN
          config_loop_sh <= config_loop_tmp;
          instr_loop_sh  <= instr_loop_tmp;
        END IF;
      END IF;
    END IF;
  END PROCESS shadow;

  -- Send out the instruction when an immediate instruction is executed
  --! Shadow register bypass for raccu configuration (@TODO should be moved in the RACCU)
  sendout : PROCESS (immediate_sig, raccu_mode_tmp, raccu_in1_sd_sh, raccu_in1_sh, raccu_in2_sd_sh, raccu_in2_sh, raccu_cfg_mode_sh, raccu_res_address_sh,
    raccu_op1_sd, raccu_op1_tmp, raccu_op2_sd, raccu_op2_tmp, raccu_result_addrs_tmp, instr_loop_tmp, instr_loop_sh, config_loop_sh, config_loop_tmp)
  BEGIN
    -- Default value of intermediate signals
    raccu_in1_sd_sig      <= ('0');
    raccu_in1_sig         <= (OTHERS => '0');
    raccu_in2_sd_sig      <= ('0');
    raccu_in2_sig         <= (OTHERS => '0');
    raccu_cfg_mode_sig    <= (OTHERS => '0');
    raccu_res_address_sig <= (OTHERS => '0');
    instr_loop            <= '0';
    config_loop           <= for_instr_zero;
    IF immediate_sig = '1' THEN
      IF to_integer(unsigned(raccu_mode_tmp)) = RAC_MODE_IDLE THEN
        raccu_in1_sd_sig      <= raccu_in1_sd_sh;
        raccu_in1_sig         <= raccu_in1_sh;
        raccu_in2_sd_sig      <= raccu_in2_sd_sh;
        raccu_in2_sig         <= raccu_in2_sh;
        raccu_cfg_mode_sig    <= raccu_cfg_mode_sh;
        raccu_res_address_sig <= raccu_res_address_sh;
      ELSE -- If the instruction triggering the immediate signal is a RACCU instruction, then by-pass the shadow register and send out the instruction itself
        raccu_in1_sd_sig      <= raccu_op1_sd;
        raccu_in1_sig         <= raccu_op1_tmp;
        raccu_in2_sd_sig      <= raccu_op2_sd;
        raccu_in2_sig         <= raccu_op2_tmp;
        raccu_cfg_mode_sig    <= raccu_mode_tmp;
        raccu_res_address_sig <= raccu_result_addrs_tmp;
      END IF;
      IF instr_loop_tmp /= '1' THEN -- Its not loop instruction that triggered
        instr_loop  <= instr_loop_sh;
        config_loop <= config_loop_sh;
      ELSE
        instr_loop  <= instr_loop_tmp;
        config_loop <= config_loop_tmp;
      END IF;
    END IF;
  END PROCESS sendout;
  ----------------------------------------------------
  -- End of modification REV 6 -----------------------
  ----------------------------------------------------
  -- TODO, remove the non_lin_pc check is not needed. Control everything from pc_increm
  pc_increm <= pc_increm_set WHEN non_lin_pc = '1' ELSE
    "01";

  --<DETECTS WHEN NO MORE INSTRUCTIONS ARE AVAILABLE>--
  --! Watchdog process to finish the execution of instructions when reach the end
  no_more_instr_proc : PROCESS (instr_ld_counter, pc, pc_count_en, delay_count_eq, loop_mode) IS
  BEGIN -- PROCESS no_more_instr_proc
    no_more_instr <= '0';
    IF (pc_count_en = '1') THEN
      IF (instr_ld_counter = 1) THEN             -- single instruction case
        IF (pc = 1) OR (delay_count_eq = '1') THEN --
          no_more_instr <= '1';
        END IF;
      ELSE
        IF ((pc = instr_ld_counter - 1) OR (pc = instr_ld_counter)) AND (pc >= 1) AND loop_mode = '0' THEN
          no_more_instr <= '1';
        END IF;
      END IF;
    END IF;
  END PROCESS no_more_instr_proc;

  ----------------------------------------------------
  -- End of modification REV 9 -----------------------
  ----------------------------------------------------
  -- Select the registered value or the current one (registered value if old or current if new)
  jump_loop_sig    <= jump_loop OR jump_loop_reg;
  pc_from_loop_sig <= pc_from_loop WHEN (jump_loop = '1') ELSE
    pc_from_loop_reg;
  -- Assign new PC according to the loop 
  pc_jump_select   <= jump_loop_sig OR jump_mode;
  -- TODO : If this is not working make sure that only one of them has a value
  pc_jump_sel_addr <= jump_addrs OR pc_from_loop_sig; -- (Potential bug)
  ----------------------------------------------------
  -- End of modification REV 9 -----------------------
  ----------------------------------------------------

  --<PC MANAGEMENT AND REG>--
  --! Process managing the PC
  pc_reg : PROCESS (clk, rst_n) IS
  BEGIN               -- PROCESS pc_reg
    IF rst_n = '0' THEN -- asynchronous reset (active low)
      pc               <= (OTHERS => '0');
      ----------------------------------------------------
      -- REV 9 -------------------------------------------
      ----------------------------------------------------
      jump_loop_reg    <= '0';
      pc_from_loop_reg <= (OTHERS => '0');
      ----------------------------------------------------
      -- End of modification REV 9 -----------------------
      ----------------------------------------------------
    ELSIF (rising_edge(clk)) THEN -- rising clock edge
      IF delay_count_en = '0' THEN  -- delay_off
        IF pc_count_en = '1' THEN
          IF pc_jump_select = '1' THEN
            ----------------------------------------------------
            -- REV 9 -------------------------------------------
            ----------------------------------------------------
            -- reset loop registers
            jump_loop_reg    <= '0';
            pc_from_loop_reg <= (OTHERS => '0');
            ----------------------------------------------------
            -- End of modification REV 9 -----------------------
            ----------------------------------------------------
            pc               <= pc_jump_sel_addr;
          ELSE
            -- SHOULD CHECK IF PC EXCEEDS THE INSTR_DEPTH BEFORE INCREMENTING
            pc <= pc + unsigned(pc_increm);
          END IF; -- jump_mode
        ELSE
          --if do_not_goto_pczero = '0' then
          pc <= (OTHERS => '0');
          --end if;
        END IF; -- pc_count_en
        ----------------------------------------------------
        -- REV 9 -------------------------------------------
        ----------------------------------------------------
      ELSE    -- delay_on
        -- If the autoloop send a new pc then register it
        IF (jump_loop_reg = '0') THEN
          jump_loop_reg    <= jump_loop;
          pc_from_loop_reg <= pc_from_loop;
        END IF;
        ----------------------------------------------------
        -- End of modification REV 9 -----------------------
        ----------------------------------------------------
      END IF; -- delay_on or off
    END IF;
  END PROCESS pc_reg;

  --<DELAY COUNTER>--
  --! Delay counter process
  del_cnt : PROCESS (clk, rst_n) IS
  BEGIN               -- PROCESS del_cnt
    IF rst_n = '0' THEN -- asynchronous reset (active low)
      delay_counter <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN -- rising clock edge
      IF delay_count_eq = '0' AND delay_count_en = '1' THEN
        delay_counter <= delay_counter + 1;
      ELSE
        delay_counter <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS del_cnt;

  --! Registering for DPU configuration
  --! TODO should be removed, the configuration should be stored locally
  --! in the DPU
  dpu_out : PROCESS (clk, rst_n) IS
  BEGIN               -- PROCESS reg
    IF rst_n = '0' THEN -- asynchronous reset (active low)
      dpu_cfg           <= (OTHERS => '0');
      dpu_ctrl_out_2    <= (OTHERS => '0');
      dpu_ctrl_out_3    <= (OTHERS => '0');
      dpu_acc_clear     <= (OTHERS => '0');
      dpu_sat_ctrl      <= (OTHERS => '0');
      dpu_process_inout <= (OTHERS => '0');
      dpu_acc_clear_rst <= '0';
    ELSIF rising_edge(clk) THEN -- rising clock edge
      IF dpu_outport_en = '1' THEN
        dpu_cfg           <= unpack_dpu_record(instr).mode;
        dpu_ctrl_out_2    <= "00";
        dpu_ctrl_out_3    <= "00";
        dpu_acc_clear     <= dpu_acc_clear_tmp; --unpack_dpu_record(instr).dpu_acc_clear;
        dpu_sat_ctrl      <= unpack_dpu_record(instr).control;
        dpu_acc_clear_rst <= '1';
        dpu_process_inout <= unpack_dpu_record(instr).io_change;
      ELSE
        dpu_acc_clear_rst <= '0';
      END IF;

    END IF;
  END PROCESS dpu_out;

  --! Registering for swb configuration
  --! TODO should be removed, the configuration should be stored locally
  --! in the swb
  swb_out : PROCESS (clk, rst_n) IS
  BEGIN               -- PROCESS swb_out
    IF rst_n = '0' THEN -- asynchronous reset (active low)
      s_bus_out <= (OTHERS => '0');
    ELSIF (rising_edge(clk)) THEN -- rising clock edge

      IF swb_outport_en = '1' THEN
        s_bus_out <= swb_instr(INSTR_WIDTH - 5 DOWNTO 12); --holds the entire instruction as it IS
        --to be forwarded to the s_bus_outp port
      END IF;

    END IF;
  END PROCESS swb_out;

  --! Register process for all configurations
  --! TODO should be removed, the configuration should be
  --! done in the individual component
  reg_out : PROCESS (clk, rst_n) IS
  BEGIN               -- PROCESS reg_rg
    IF rst_n = '0' THEN -- asynchronous reset (active low)
      reg_port_type      <= (OTHERS => '0');
      reg_start_addrs    <= (OTHERS => '0');
      reg_no_of_addrs    <= (OTHERS => '0');
      reg_initial_delay  <= (OTHERS => '0');
      reg_step_val       <= (OTHERS => '0');
      reg_step_val_sign  <= (OTHERS => '0');
      reg_middle_delay   <= (OTHERS => '0');
      reg_no_of_rpts     <= (OTHERS => '0');
      reg_rpt_step_value <= (OTHERS => '0');
      reg_rpt_delay      <= (OTHERS => '0');
      reg_mode           <= (OTHERS => '0');
      reg_outp_cntrl     <= (OTHERS => '0');
      reg_fft_stage      <= (OTHERS => '0');
      reg_end_fft_stage  <= (OTHERS => '0');
      instr_start        <= '0';
      reg_dimarch_mode   <= '0';
      reg_use_compr      <= '0';

    ELSIF (rising_edge(clk)) THEN -- rising clock edge

      IF reg_outport_en = '1' THEN
        reg_port_type        <= unpack_refi1_record(instr).port_no;
        reg_start_addrs      <= reg_start_addrs_tmp;   --unpack_refi1_record(instr).start_addrs;
        reg_no_of_addrs      <= reg_no_of_addrs_tmp;   --unpack_refi1_record(instr).no_of_addrs;
        reg_initial_delay    <= reg_initial_delay_tmp; --unpack_refi1_record(instr).initial_delay;
        instr_start          <= '1';
        reg_rpt_delay        <= reg_rpt_delay_tmp;
        reg_mode             <= reg_mode_tmp;
        reg_outp_cntrl       <= reg_outp_cntrl_tmp;
        reg_fft_stage        <= reg_fft_stage_tmp;
        reg_end_fft_stage    <= reg_end_fft_stage_tmp;
        reg_step_val         <= reg_step_val_tmp;
        reg_step_val_sign(0) <= reg_step_val_sign_tmp;
        reg_middle_delay     <= reg_middle_delay_tmp;
        reg_no_of_rpts       <= reg_no_of_rpts_tmp;
        reg_rpt_step_value   <= reg_rpt_step_value_tmp;
        reg_dimarch_mode     <= reg_dimarch_mode_tmp;
        reg_use_compr        <= reg_use_compr_tmp;

      ELSE
        instr_start <= '0';
      END IF;
    END IF;
  END PROCESS reg_out;

  ----------------------------------------------------
  -- REV 6 2020-02-13 --------------------------------
  ----------------------------------------------------
  --! Register for the immediate signal to sync (TODO should be removed and the sync should be done similar for all configurations)
  P_immediate_reg : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      immediate_out <= '0';
    ELSIF rising_edge(clk) THEN
      immediate_out <= immediate_sig;
    END IF;
  END PROCESS P_immediate_reg;

  --! Register the noc bus (to sync with all other configuration)
  --! TODO this should be removed and the sync should be done by having a common
  --! structure for all
  noc_bus_reg_out : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      noc_bus_out <= IDLE_BUS;
    ELSIF rising_edge(clk) THEN
      noc_bus_out <= NOC_BUS_OUT_sig;
    END IF;
  END PROCESS noc_bus_reg_out;
  ----------------------------------------------------
  -- End of modification REV 6 -----------------------
  ----------------------------------------------------

  ----------------------------------------------------
  -- REV 8 2021-08-18 --------------------------------
  ----------------------------------------------------
  BW_conf_reg : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      dpu_op_control <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      dpu_op_control <= dpu_op_control_reg;
    END IF;
  END PROCESS;
  ----------------------------------------------------
  -- End of modification REV 8 -----------------------
  ----------------------------------------------------

  --<STATE MACHINES>--
  --! This process is the main state machine of the sequencer. It is used to unpack and issue the instruction & control the the configuration of the rest of the units in the DRRA cell.
  c0 : PROCESS (pres_state, raccu_reg_out, new_instr_ld, instr_ld, instr, delay_counter, instr_ld_counter, pc, instr_reg, instr_refi2, instr_refi3, no_more_instr, seq_cond_status, instr_1, instr_2) --MEALY
    VARIABLE del_cycles_tmp    : unsigned(DLY_CYCLES_VECTOR_SIZE DOWNTO 0) := (OTHERS => '0');
    VARIABLE for_basic         : LOOP_instr_type;
    VARIABLE tmp_RACCU_addr    : unsigned(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0);
    VARIABLE tmp_RACCU_value   : STD_LOGIC_VECTOR(RACCU_REG_BITWIDTH - 1 DOWNTO 0);
    VARIABLE tmp_instr3        : STD_LOGIC_VECTOR(INSTR_WIDTH * 3 - 1 DOWNTO 0);
    ---------------------------------------------------
    -- REV 10 2022-03-04 ------------------------------
    ---------------------------------------------------
    VARIABLE refi_instruction  : refi_instr_type;
    VARIABLE sram_instruction  : sram_instr_type;
    VARIABLE route_instruction : route_instr_type;
    ----------------------------------------------------
    -- End of modification REV 10 ----------------------
    ----------------------------------------------------
  BEGIN -- PROCESS c0
    tmp_instr3      := (OTHERS             => '0');
    tmp_RACCU_addr  := (OTHERS             => '0');
    tmp_RACCU_value := (OTHERS             => '0');
    NOC_BUS_OUT_sig.INSTRUCTION <= (OTHERS => '0');
    NOC_BUS_OUT_sig             <= IDLE_BUS;
    valid_instr                 <= '1';
    subseq_refi_instrs          <= '0';
    ext_flag_middle_delay       <= '0';
    ext_flag_no_of_rpt          <= '0';
    ext_flag_rpt_step_value     <= '0';

    delay_count_eq              <= '0';
    delay_count_en              <= '0';
    reg_outport_en              <= '0';
    dpu_outport_en              <= '0';
    swb_outport_en              <= '0';

    non_lin_pc                  <= '0';
    pc_increm_set               <= "01";

    instr_refi2                 <= (OTHERS => '0');
    instr_refi3                 <= (OTHERS => '0');

    dpu_instr                   <= ((OTHERS => '0'), (OTHERS => '0'), (OTHERS => '0'), (OTHERS => '0'), (OTHERS => '0'));
    branch_instr                <= ((OTHERS => '0'), (OTHERS => '0'), (OTHERS => '0'));
    jump_instr                  <= ((OTHERS => '0'), (OTHERS => '0'));
    delay_instr                 <= ((OTHERS => '0'), '0', (OTHERS => '0'));
    raccu_instr                 <= ((OTHERS => '0'), (OTHERS => '0'), '0', (OTHERS => '0'), '0', (OTHERS => '0'), (OTHERS => '0'));
    swb_instr                   <= (OTHERS => '0');
    reg_rpt_delay_tmp           <= (OTHERS => '0');
    reg_mode_tmp                <= "0";
    reg_outp_cntrl_tmp          <= "11";
    reg_fft_stage_tmp           <= (OTHERS => '0');
    reg_end_fft_stage_tmp       <= (OTHERS => '0');
    reg_step_val_tmp            <= (OTHERS => '0');
    reg_step_val_sign_tmp       <= '0';
    reg_middle_delay_tmp        <= (OTHERS => '0');
    reg_no_of_rpts_tmp          <= (OTHERS => '0');
    reg_rpt_step_value_tmp      <= (OTHERS => '0');
    reg_dimarch_mode_tmp        <= '0';
    reg_use_compr_tmp           <= '0';
    config_count_en             <= '0';
    loop_jump_mode              <= '0';
    pc_count_en                 <= '0';
    instr_ld_counter_rst        <= '0';
    raccu_mode_tmp              <= (OTHERS => '0');
    raccu_op1_tmp               <= (OTHERS => '0');
    raccu_op2_tmp               <= (OTHERS => '0');
    raccu_op1_sd                <= '0';
    raccu_op2_sd                <= '0';
    raccu_result_addrs_tmp      <= (OTHERS => '0');
    dpu_acc_clear_tmp           <= (OTHERS => '0');
    reg_start_addrs_tmp         <= (OTHERS => '0');
    reg_no_of_addrs_tmp         <= (OTHERS => '0');
    reg_initial_delay_tmp       <= (OTHERS => '0');
    loop_mode                   <= '0';

    jump_mode                   <= '0';
    jump_addrs                  <= (OTHERS => '0');

    ----------------------------------------------------
    -- REV 7 2020-05-26 --------------------------------
    ----------------------------------------------------
    instr_loop_tmp              <= '0';
    config_loop_tmp             <= for_instr_zero;
    ----------------------------------------------------
    -- End of modification REV 7 -----------------------
    ----------------------------------------------------

    next_state                  <= pres_state;

    ----------------------------------------------------
    -- REV 8 2021-08-18 --------------------------------
    ----------------------------------------------------
    dpu_op_control_reg          <= (OTHERS => '0');
    ----------------------------------------------------
    -- End of modification REV 8 -----------------------
    ----------------------------------------------------

    CASE pres_state IS
      WHEN IDLE_ST =>
        pc_count_en <= '0';

        IF (new_instr_ld = '1') THEN
          next_state      <= SEQ_LOADING_ST;
          config_count_en <= '1';
        END IF;

      WHEN SEQ_LOADING_ST =>
        config_count_en <= '1';

        IF (instr_ld = '0') THEN
          next_state      <= INSTR_DECODE_ST; -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          config_count_en <= '0';             --let config_count_en be asserted for
          --one cycle extra in order to be able
          --to decode the first instruction as
          --well as to write the last instruction
          --in the instruction register in the
          --same cycle
          pc_count_en     <= '0';

        END IF;

      WHEN INSTR_DECODE_ST =>
        config_count_en <= '0';

        IF no_more_instr = '1' THEN
          next_state           <= IDLE_ST;
          pc_count_en          <= '0';
          instr_ld_counter_rst <= '1';

          CASE instr(INSTR_CODE_RANGE_BASE DOWNTO INSTR_CODE_RANGE_END) IS
            WHEN REFI =>
              reg_outport_en <= '1';
            WHEN DPU =>
              dpu_outport_en <= '1';
            WHEN SWB =>
              swb_outport_en <= '1';
            WHEN DELAY =>
              delay_instr    <= unpack_WAIT_record(instr);

              delay_count_en <= '1';
              pc_count_en    <= '0'; -- stop pc for the number of cycles
              -- given in the delay instruction.
            WHEN OTHERS => NULL;
          END CASE;

        END IF;

        pc_count_en <= '1';

        CASE instr_code_alias IS
            ---------------------------------------------------
            -- REV 10 2022-03-04 ------------------------------
            ---------------------------------------------------
          WHEN REFI =>

            IF unpack_refi1_record(instr).extra = "00" OR unpack_refi1_record(instr).extra = "11" THEN
              refi_instruction := unpack_refi1_record(instr);
            ELSIF unpack_refi1_record(instr).extra = "01" THEN
              refi_instruction := unpack_refi2_record(instr & instr_1);
            ELSIF unpack_refi1_record(instr).extra = "10" THEN
              refi_instruction := unpack_refi3_record(instr & instr_1 & instr_2);
            END IF;

            IF refi_instruction.init_addr_sd = '0' THEN
              reg_start_addrs_tmp <= refi_instruction.init_addr;
            ELSE
              reg_start_addrs_tmp <= raccu_reg_out(to_integer(unsigned(refi_instruction.init_addr)))(STARTING_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
            END IF;

            IF refi_instruction.l1_iter_sd = '0' THEN
              reg_no_of_addrs_tmp <= refi_instruction.l1_iter;
            ELSE
              reg_no_of_addrs_tmp <= raccu_reg_out(to_integer(unsigned(refi_instruction.l1_iter)))(NR_OF_ADDRS_VECTOR_SIZE - 1 DOWNTO 0);
            END IF;

            IF refi_instruction.init_delay_sd = '0' THEN
              reg_initial_delay_tmp <= refi_instruction.init_delay;
            ELSE
              reg_initial_delay_tmp <= raccu_reg_out(to_integer(unsigned(refi_instruction.init_delay(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0))))(INIT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
            END IF;

            reg_outport_en <= '1';

            IF unpack_refi1_record(instr).extra = "00" OR unpack_refi1_record(instr).extra = "11" THEN
              reg_rpt_delay_tmp      <= (OTHERS => '0');
              reg_mode_tmp           <= "0";
              reg_outp_cntrl_tmp     <= "11";
              reg_fft_stage_tmp      <= (OTHERS => '0');
              reg_end_fft_stage_tmp  <= (OTHERS => '0');
              reg_step_val_tmp       <= "000001";
              reg_step_val_sign_tmp  <= '0';
              reg_middle_delay_tmp   <= (OTHERS => '0');
              reg_no_of_rpts_tmp     <= (OTHERS => '0');
              reg_rpt_step_value_tmp <= (OTHERS => '0');
              reg_rpt_step_value_tmp <= (OTHERS => '0');

            ELSE
              instr_refi2 <= instr_1;

              IF unpack_refi1_record(instr).extra = "01" THEN

                pc_increm_set          <= "10";
                non_lin_pc             <= '1';
                reg_rpt_delay_tmp      <= (OTHERS => '0');
                reg_mode_tmp           <= "0";
                reg_outp_cntrl_tmp     <= "11";
                reg_fft_stage_tmp      <= (OTHERS => '0');
                reg_end_fft_stage_tmp  <= (OTHERS => '0');
                reg_step_val_tmp       <= refi_instruction.l1_step;
                reg_step_val_sign_tmp  <= refi_instruction.l1_step_sign;
                reg_middle_delay_tmp   <= "00" & refi_instruction.l1_delay;
                reg_no_of_rpts_tmp     <= "0" & refi_instruction.l2_iter;
                reg_rpt_step_value_tmp <= "00" & refi_instruction.l2_step;

              ELSIF unpack_refi1_record(instr).extra = "10" THEN
                instr_refi3            <= instr_2;

                pc_increm_set          <= "11";
                non_lin_pc             <= '1';
                reg_mode_tmp           <= "0";
                reg_step_val_tmp       <= refi_instruction.l1_step;-- why is this refi2 value
                reg_outp_cntrl_tmp     <= "11";
                reg_fft_stage_tmp      <= (OTHERS => '0');
                reg_end_fft_stage_tmp  <= (OTHERS => '0');
                reg_middle_delay_tmp   <= refi_instruction.l1_delay_ext & refi_instruction.l1_delay;
                reg_no_of_rpts_tmp     <= refi_instruction.l2_iter_ext & refi_instruction.l2_iter;
                reg_rpt_step_value_tmp <= refi_instruction.l2_step_ext & refi_instruction.l2_step;
                reg_dimarch_mode_tmp   <= refi_instruction.dimarch;
                reg_use_compr_tmp      <= refi_instruction.compress;

                IF refi_instruction.l2_delay_sd = '0' THEN
                  reg_rpt_delay_tmp <= refi_instruction.l2_delay;
                ELSE
                  reg_rpt_delay_tmp <= raccu_reg_out(to_integer(unsigned(refi_instruction.l1_delay(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0))))(REPT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
                END IF;

              END IF;

              IF refi_instruction.l1_step_sd = '1' THEN
                reg_step_val_tmp <= raccu_reg_out(to_integer(unsigned(refi_instruction.l1_step(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0))))(STEP_VALUE_VECTOR_SIZE - 1 DOWNTO 0);
              END IF;

              IF refi_instruction.l1_delay_sd = '1' THEN
                reg_middle_delay_tmp <= raccu_reg_out(to_integer(unsigned(refi_instruction.l1_delay(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0))))(REG_FILE_MIDDLE_DELAY_PORT_SIZE - 1 DOWNTO 0);
              END IF;

              IF refi_instruction.l2_iter_sd = '1' THEN
                reg_no_of_rpts_tmp <= raccu_reg_out(to_integer(unsigned(refi_instruction.l2_iter(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0))))(NUM_OF_REPT_PORT_SIZE - 1 DOWNTO 0);
              END IF;

            END IF;

          WHEN DPU =>
            dpu_instr         <= unpack_dpu_record(instr);
            dpu_acc_clear_tmp <= unpack_dpu_record(instr).acc_clear;

            dpu_outport_en    <= '1';

          WHEN SWB =>
            swb_instr      <= instr;

            swb_outport_en <= '1';

          WHEN BRANCH =>
            branch_instr <= unpack_branch_record(instr);

            IF (unpack_branch_record(instr).mode AND seq_cond_status) = "00" THEN -- false
              jump_addrs <= unsigned(unpack_branch_record(instr).false_pc);
              jump_mode  <= '1';
            END IF;

          WHEN JUMP =>
            jump_instr <= unpack_jump_record(instr);

            jump_addrs <= unsigned(unpack_jump_record(instr).pc);
            jump_mode  <= '1';

          WHEN DELAY =>
            delay_instr    <= unpack_WAIT_record(instr);
            delay_count_en <= '1';
            pc_count_en    <= '0';                           -- stop pc for the number of cycles
            -- given in the delay instruction.

            IF unpack_WAIT_record(instr).cycle_sd = '0' THEN --bug for delta delay
              del_cycles_tmp := unsigned(unpack_WAIT_record(instr).cycle);

              IF delay_counter = unsigned(unpack_WAIT_record(instr).cycle) THEN
                delay_count_en <= '0';
                delay_count_eq <= '1';
                pc_count_en    <= '1'; -- resumes pc when delay_counter == the number of cycles given in the delay instruction
              END IF;
            ELSE
              del_cycles_tmp := resize(unsigned(raccu_reg_out(to_integer(unsigned(unpack_WAIT_record(instr).cycle)))), del_cycles_tmp'length);

              IF delay_counter = del_cycles_tmp THEN --bug for delta delay
                delay_count_en <= '0';
                delay_count_eq <= '1';
                pc_count_en    <= '1'; -- resumes pc when delay_counter == the number of cycles given in the delay instruction
              END IF;
            END IF;

            ----------------------------------------------------
            -- REV 8 2021-08-18 --------------------------------
            ----------------------------------------------------
          WHEN BW_CONFIG =>
            dpu_op_control_reg <= bw_control;
            ----------------------------------------------------
            -- End of modification REV 8 -----------------------
            ----------------------------------------------------

          WHEN HALT =>
            next_state      <= IDLE_ST;
            config_count_en <= '0';
            pc_count_en     <= '0';

            ----------------------------------------------------
            -- REV 7 2020-05-26 --------------------------------
            ----------------------------------------------------
            -- New loop instruction
          WHEN FOR_LOOP =>
          	for_basic := unpack_LOOP1_record(instr);
            IF for_basic.extra = '0' THEN
              for_basic := unpack_LOOP1_record(instr);
            ELSE
              for_basic := unpack_LOOP2_record(instr & instr_1);
            END IF;
            -- Basic loop  
            config_loop_tmp.loop_id      <= unsigned(for_basic.loopid);
            config_loop_tmp.start_pc     <= pc + 1;
            config_loop_tmp.end_pc       <= unsigned(for_basic.endpc);
            config_loop_tmp.start_sd     <= for_basic.start_sd;
            config_loop_tmp.start        <= signed(for_basic.start);
            config_loop_tmp.iter_sd      <= for_basic.iter_sd;
            config_loop_tmp.iter         <= unsigned(for_basic.iter);
            config_loop_tmp.default_step <= '0';
            config_loop_tmp.step_sd       <= for_basic.step_sd;
            config_loop_tmp.step          <= signed(for_basic.step);
            config_loop_tmp.related_loops <= for_basic.link;

            instr_loop_tmp               <= '1';
            non_lin_pc                   <= '0';
            IF for_basic.extra = '1' THEN
              pc_increm_set                <= "10";
              non_lin_pc                   <= '1';
              -- Non default step
              config_loop_tmp.default_step <= '0';
              -- PC should be PC + 2
              config_loop_tmp.start_pc     <= pc + 2;
            END IF;
            
            IF for_basic.start_sd = '1' THEN
            	config_loop_tmp.start <= resize(signed(raccu_reg_out(to_integer(unsigned(for_basic.start)))), config_loop_tmp.start'length);
            END IF;
            IF for_basic.step_sd = '1' THEN
            	config_loop_tmp.step <= resize(signed(raccu_reg_out(to_integer(unsigned(for_basic.step)))), config_loop_tmp.step'length);
            END IF;
            IF for_basic.iter_sd = '1' THEN
            	config_loop_tmp.iter <= resize(unsigned(raccu_reg_out(to_integer(unsigned(for_basic.iter)))), config_loop_tmp.iter'length);
            END IF;
            	
            ----------------------------------------------------
            -- End of modification REV 7 -----------------------
            ----------------------------------------------------
          WHEN RACCU =>
            raccu_instr            <= unpack_raccu_record(instr);
            raccu_result_addrs_tmp <= unpack_raccu_record(instr).result;
            raccu_mode_tmp         <= unpack_raccu_record(instr).mode;
            IF unpack_raccu_record(instr).operand1_sd = '0' THEN
              raccu_op1_tmp <= unpack_raccu_record(instr).operand1;
            ELSE
              raccu_op1_tmp <= raccu_reg_out(to_integer(unsigned(unpack_raccu_record(instr).operand1)));
            END IF;
            IF unpack_raccu_record(instr).operand2_sd = '0' THEN
              raccu_op2_tmp <= unpack_raccu_record(instr).operand2;
            ELSE
              raccu_op2_tmp <= raccu_reg_out(to_integer(unsigned(unpack_raccu_record(instr).operand2)));
            END IF;

          WHEN ROUTE =>
            route_instruction := unpack_route_record(instr);
            NOC_BUS_OUT_sig <= pack_route_noc_instruction(route_instruction);

          WHEN READ_SRAM | WRITE_SRAM =>
            ------------------------------------------------- UNPACK  -------------------------------------------------
            -- this way off making bits the same size is not parameteized and needs to be updated
            sram_instruction := unpack_sram3_record(instr(INSTR_WIDTH - 1 DOWNTO 0) & instr_1(INSTR_WIDTH - 1 DOWNTO 0) & instr_2(INSTR_WIDTH - 1 DOWNTO 0));
            ------------------------------------------------- STATIC DYNAMIC  -------------------------------------------------
            -- following codes loads the dynamic values from the RACCU register
            -- loop1 iteration & increment is parameterized and can be changed based on different block sizes of RF. 
            -- It can either be bigger or smaller then RACCU so we have to handle sign extention for both cases 
            -- since the value is unsigned this value will be zero for all unsigned values 
            -- increments are signed so they will require forllowing logic 
            ------------------------------------------------- Initial -------------------------------------------------
            IF sram_instruction.init_addr_sd = '1' THEN -- initial Address Static or Dynamic
              tmp_RACCU_addr             := unsigned(sram_instruction.init_addr(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0));
              tmp_RACCU_value            := raccu_reg_out(to_integer(tmp_RACCU_addr));
              sram_instruction.init_addr := STD_LOGIC_VECTOR(resize(unsigned(tmp_RACCU_value), sram_instruction.init_addr'length));
            END IF;
            IF sram_instruction.init_delay_sd = '1' THEN -- initial Delay Static or Dynamic
              tmp_RACCU_addr              := unsigned(sram_instruction.init_delay(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0));
              tmp_RACCU_value             := raccu_reg_out(to_integer(tmp_RACCU_addr));
              sram_instruction.init_delay := STD_LOGIC_VECTOR(resize(unsigned(tmp_RACCU_value), sram_instruction.init_delay'length));
            END IF;
            ------------------------------------------------- Loop 1 ------------------------------------------------- 
            IF sram_instruction.l1_iter_sd = '1' THEN -- Loop 1 iteration  Static or Dynamic
              tmp_RACCU_addr           := unsigned(sram_instruction.l1_iter(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0));
              tmp_RACCU_value          := raccu_reg_out(to_integer(tmp_RACCU_addr));
              sram_instruction.l1_iter := STD_LOGIC_VECTOR(resize(unsigned(tmp_RACCU_value), sram_instruction.l1_iter'length));
              -- ORIGINAL LINE:	
              --sram_instruction.Loop1_iteration(sr_loop1_iteration_width-1 downto RACCU_REG_BITWIDTH) := (others => '0'); -- unsgined sign extention
              --	else    --  When RACCU is bigger then iteration  just un comment following lines 
              --assert false report "RACCU Width is bigger then loop1 interations uncomment the lines below this assert statement to make the design work" severity error;
              --	sram_instruction.Loop1_iteration(sr_loop1_iteration_width-1 downto 0) :="0"&raccu_reg_out(CONV_INTEGER(sram_instruction.Loop1_iteration(RACCU_REG_ADDRS_WIDTH-1 downto 0)));
              --  -- no signed extention is required here 
              --end if;	
            END IF;

            IF sram_instruction.l1_step_sd = '1' THEN -- Loop 1 increment  Static or Dynamic
              tmp_RACCU_addr           := unsigned(sram_instruction.l1_step(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0));
              tmp_RACCU_value          := raccu_reg_out(to_integer(tmp_RACCU_addr));
              sram_instruction.l1_step := STD_LOGIC_VECTOR(resize(signed(tmp_RACCU_value), sram_instruction.l1_step'length));
              --if sr_loop1_iteration_width > RACCU_REG_ADDRS_WIDTH then
              --sram_instruction.l1_step(RACCU_REG_BITWIDTH-1 downto 0) := raccu_reg_out(CONV_INTEGER(sram_instruction.l1_iter(RACCU_REG_ADDRS_WIDTH-1 downto 0)));
              --if sram_instruction.l1_step(RACCU_REG_BITWIDTH-1) = '1' then -- sign extentions 
              --sram_instruction.l1_step(sr_loop1_increment_width-1 downto RACCU_REG_ADDRS_WIDTH) := (others => '1');
              --else 
              --sram_instruction.l1_step(sr_loop1_increment_width-1 downto RACCU_REG_ADDRS_WIDTH) := (others => '0');
              --end if;
              --else
              --assert false report "RACCU Width is bigger then loop1 increment uncomment the lines below this assert statement to make the design work" severity error;
              --sram_instruction.Loop1_Increment := raccu_reg_out(CONV_INTEGER(sram_instruction.Loop1_Increment(RACCU_REG_ADDRS_WIDTH-1 downto 0))) (sr_loop1_increment_width-1 downto 0);
              --end if;
            END IF;

            IF sram_instruction.l1_delay_sd = '1' THEN -- Loop 1 Delay  Static or Dynamic
              tmp_RACCU_addr            := unsigned(sram_instruction.l1_delay(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0));
              tmp_RACCU_value           := raccu_reg_out(to_integer(tmp_RACCU_addr));
              sram_instruction.l1_delay := STD_LOGIC_VECTOR(resize(unsigned(tmp_RACCU_value), sram_instruction.l1_delay'length));
              --sram_instruction.l1_delay := raccu_reg_out(CONV_INTEGER(sram_instruction.l1_delay(RACCU_REG_ADDRS_WIDTH-1 downto 0)))(sr_loop1_delay_width-1 downto 0);
            END IF;

            ------------------------------------------------- Loop 2 -------------------------------------------------
            --- assumtions   
            --RACCU_REG_ADDRS_WIDTH is always smaller then iteration and increment
            -- RACCU_REG_ADDRS_WIDTH is equal to delay size 

            IF sram_instruction.l2_iter_sd = '1' THEN -- Loop 1 iteration  Static or Dynamic
              tmp_RACCU_addr           := unsigned(sram_instruction.l2_iter(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0));
              tmp_RACCU_value          := raccu_reg_out(to_integer(tmp_RACCU_addr));
              sram_instruction.l2_iter := STD_LOGIC_VECTOR(resize(unsigned(tmp_RACCU_value), sram_instruction.l2_iter'length));
              ---sram_instruction.l2_iter(RACCU_REG_BITWIDTH-1 downto 0) := raccu_reg_out(CONV_INTEGER(sram_instruction.l2_iter(RACCU_REG_ADDRS_WIDTH-1 downto 0)));
              --sram_instruction.l2_iter(sr_loop2_iteration_width-1 downto RACCU_REG_ADDRS_WIDTH) := (others => '0'); -- unsgined sign extention
            END IF;

            IF sram_instruction.l2_step_sd = '1' THEN -- Loop 1 increment  Static or Dynamic
              tmp_RACCU_addr           := unsigned(sram_instruction.l2_step(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0));
              tmp_RACCU_value          := raccu_reg_out(to_integer(tmp_RACCU_addr));
              sram_instruction.l2_step := STD_LOGIC_VECTOR(resize(signed(tmp_RACCU_value), sram_instruction.l2_step'length));
              --sram_instruction.l2_step := '0' & raccu_reg_out(CONV_INTEGER(sram_instruction.l2_step(RACCU_REG_ADDRS_WIDTH-1 downto 0)));
              ----ORIGINAL LINE: 
              ----sram_instruction.Loop2_Increment := raccu_reg_out(CONV_INTEGER(sram_instruction.Loop2_Increment(RACCU_REG_ADDRS_WIDTH-1 downto 0)));
              --if sram_instruction.l2_step(RACCU_REG_ADDRS_WIDTH-1) = '1' then -- sign extentions 
              --sram_instruction.l2_step(sr_loop2_increment_width-1 downto RACCU_REG_ADDRS_WIDTH) := (others => '1');
              --else 
              --sram_instruction.l2_step(sr_loop2_increment_width-1 downto RACCU_REG_ADDRS_WIDTH) := (others => '0');
              --end if;
            END IF;
            IF sram_instruction.l2_delay_sd = '1' THEN -- Loop 2 Delay  Static or Dynamic
              tmp_RACCU_addr            := unsigned(sram_instruction.l2_delay(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0));
              tmp_RACCU_value           := raccu_reg_out(to_integer(tmp_RACCU_addr));
              sram_instruction.l2_delay := STD_LOGIC_VECTOR(resize(unsigned(tmp_RACCU_value), sram_instruction.l2_delay'length));
              --sram_instruction.l2_delay := raccu_reg_out(CONV_INTEGER(sram_instruction.l2_delay(RACCU_REG_ADDRS_WIDTH-1 downto 0)))(sr_loop2_delay_width-1 downto 0);
            END IF;
            ------------------------------------------------- READ/WRITE -------------------------------------------------
            --		if instr_code_alias = WRITE_SRAM then 
            --		sram_instruction.rw  := '1';
            --else  
            --sram_instruction.rw  := '0';
            --	end if;
            ------------------------------------------------- SEND on NoC Bus -------------------------------------------------        
            NOC_BUS_OUT_sig <= pack_sram_noc_instruction(sram_instruction); -- sram instruction is placed on noc bus 
            ------------------------------------------------- Increment PC -------------------------------------------------
            -- increment is set to 3 as this is a three part instruction
            pc_increm_set   <= "11";
            non_lin_pc      <= '1';

          WHEN OTHERS =>
            valid_instr <= '0';

        END CASE;
    END CASE;
  END PROCESS c0;

  --! FSM state register process
  reg : PROCESS (clk, rst_n)
  BEGIN               -- PROCESS reg
    IF rst_n = '0' THEN -- asynchronous reset (active low)
      pres_state <= IDLE_ST;
    ELSIF (rising_edge(clk)) THEN -- rising clock edge
      pres_state <= next_state;
    END IF;
  END PROCESS reg;

END;
