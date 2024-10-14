-------------------------------------------------------
--! @file nacu.vhd
--! @brief NACU: Non-linear Arithmetic Unit for Neural Networks
--! @details
--! @author Guido Baccelli
--! @version 1.1
--! @date 20/08/2019
--! @bug NONE
--! @todo Remove the register stage after multiplier, if there is no timing problem. Same for the Squash
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
-- Title      : UnitX
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : nacu.vhd
-- Author     : Guido Baccelli
-- Company    : KTH
-- Created    : 20/08/2019
-- Last update: 2021-09-07
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
-- 20/08/2019  1.0      Guido Baccelli          Created
-- 2020-03-15  1.1      Dimitrios Stathis       Code clean up and minor fixes
--                                              for public git
-- 2021-04-21  2.0      Dimitrios Stathis       Changed NACU for SiLagoNN,
--                                              addition of reconfigurable multiplier
--                                              and adder.
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
--! Standard logic package
USE ieee.std_logic_1164.ALL;
--! Standard numeric package for signed and unsigned
USE ieee.numeric_std.ALL;
--! Package with ann_unit types and constants
USE work.DPU_pkg.ALL;

--! This module is the NACU: Non-linear Arithmetic Unit for Neural Networks

--! This module implements the following functions:
--! \verbatim
--! Multiply-Add-Accumulate
--! Sigmoid
--! Hyperbolic Tangent
--! Exponential tail (for use in Softmax)
--! Division (for use in Softmax) 
--! \endverbatim
--! This means the module provides all the required functionality for neuron 
--! activations in common Deep Neural Networks such as CNN and LSTM.
--! The unit also features a reconfigurable MAC. The MAC can operate in
--! different bit-widths (4, 8, or 16 bit inputs). The unit also includes a
--! reconfigurable adder that can add and accumulate according to the same
--! bit-widths. The adder and multiplier split tha 16 bit inputs to sub-operants
--! of the specific width and operate in parallel to all operants. Given a 16 bit
--! input, the NACUv2 can do 4 times 4-bit, 2 times 8-bit, or a single 16-bit operation
--! per multiplier/adder.
ENTITY NACU IS
  GENERIC (
    mac_pipe     : NATURAL := 0; --! Enable or disable the MAC pipeline (0 no pipeline, 1 pipelined)
    squash_pipe  : NATURAL := 0; --! Enable or disable the squash pipeline (0 no pipeline, 1 pipelined)
    div_n_squash : NATURAL := 1  --! Enable division and squash unit (0 no division or squash, 1 both division and squash)
  );
  PORT (
    clk             : IN STD_LOGIC;                                             --! Clock signal
    clear           : IN STD_LOGIC;                                             --! Synchronous Reset
    rst_n           : IN STD_LOGIC;                                             --! Asynchronous Reset

    bit_config      : IN STD_LOGIC_VECTOR(select_w - 1 DOWNTO 0);               --! Configuration of the mult/add bitwidth
    mode_cfg        : IN unsigned (S_DPU_CFG_WIDTH - 1 DOWNTO 0);               --! DPU configuration 
    acc_clear       : IN STD_LOGIC;                                             --! Accumulation clear reset

    direct_acc      : IN STD_LOGIC_VECTOR(ADD_I_W - 1 DOWNTO 0);                --! Direct accumulator input (replaces the add_in1 port of the adder)
    direct_acc_en   : IN STD_LOGIC;                                             --! Enable direct accumulator input

    div_direct      : IN signed(DIV_I_W - 1 DOWNTO 0);                          --! Direct accumulator input to the divider
    divide_acc      : IN STD_LOGIC;                                             --! Enable divide with direct input

    nacu_in_0       : IN signed (S_DPU_IN_WIDTH - 1 DOWNTO 0);                  --! Input 0
    nacu_in_1       : IN signed (S_DPU_IN_WIDTH - 1 DOWNTO 0);                  --! Input 1

    seq_cond_status : OUT STD_LOGIC_VECTOR(SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0); --! Sequencer status output from max/min

    nacu_out        : OUT signed(S_DPU_OUT_WIDTH - 1 DOWNTO 0)                  --! Output
  );
END ENTITY;

--! @brief Structural view of NACU
--! @details A common mathematical basis for the calculation of Sigmoid, Tanh, Exponential and Softmax is exploited to maximize
--! the reuse of internal components. A multiplier-adder chain covers the MAC operation. In this case, the output register is used as accumulator.
--! Sigmoid and Tanh are implemented by means of Piece-Wise Linear interpolation. A LUT-based Squash Unit provides slopes and offset
--! for each interpolation interval, both for Sigmoid and Tanh. The LUT only contains slopes and offsets for Sigmoid with positive inputs.
--! Some mathematical optimizations are used to derive slopes and offset for the Sigmoid with negative inputs and for the whole Tanh curve.
--! The same MAC components are reused to build the PWL interpolation. The Exponential tail is derived from the Sigmoid function. The required division
--! can be carried out by reusing the same divider for the Softmax function. 
--! All these implementation choices maximize area savings while still achieving very good accuracy. 
ARCHITECTURE rtl OF NACU IS

  -- #################### COMPONENTS ####################

  COMPONENT conf_mul_Beh IS
    GENERIC (
      width   : NATURAL;
      s_width : NATURAL
    );
    PORT (
      in_a : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
      in_b : IN STD_LOGIC_VECTOR(WIDTH - 1 DOWNTO 0);
      conf : IN STD_LOGIC_VECTOR(s_width - 1 DOWNTO 0);
      prod : OUT STD_LOGIC_VECTOR(2 * WIDTH - 1 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT adder_nbits IS
    GENERIC (
      width    : NATURAL := 16;
      select_w : NATURAL := 2
    );
    PORT (
      A    : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
      B    : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
      conf : IN STD_LOGIC_VECTOR(select_w - 1 DOWNTO 0);
      SO   : OUT STD_LOGIC_VECTOR(2 ** select_w - 1 DOWNTO 0);
      SUM  : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT Squash_Unit IS
    GENERIC (
      Nb        : INTEGER;
      frac_part : INTEGER
    );
    PORT (
      data_in         : IN signed(Nb - 1 DOWNTO 0);
      data_in_2scompl : IN signed(Nb - 1 DOWNTO 0);
      squash_mode     : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      slope           : OUT signed(Nb - 1 DOWNTO 0);
      offset          : OUT signed(Nb - 1 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT offset_gen IS
    GENERIC (
      Nb            : INTEGER;
      frac_part_lut : INTEGER
    );
    PORT (
      offset_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      offset_in  : IN signed(Nb - 1 DOWNTO 0);
      offset_out : OUT signed(Nb - 1 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT twos_compl IS
    GENERIC (b_width : INTEGER := 16);
    PORT (
      d_in  : IN signed(b_width - 1 DOWNTO 0);
      d_out : OUT signed(b_width - 1 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT Saturation_Unit IS
    PORT (
      d_in   : IN STD_LOGIC_VECTOR(SAT_IN_BITS - 1 DOWNTO 0);
      carry  : IN STD_LOGIC_VECTOR(ADD_C_W - 1 DOWNTO 0);
      d_mode : IN STD_LOGIC_VECTOR(SAT_CONF_BITS - 1 DOWNTO 0);
      d_out  : OUT STD_LOGIC_VECTOR(SAT_OUT_BITS - 1 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT divider_pipe IS
  PORT (
    clk       : IN STD_LOGIC;                --! Clock
    rst_n     : IN STD_LOGIC;                --! Asynchronous reset
    const_one : IN signed(DIV_I_W - 1 DOWNTO 0);  --! Constant one represented in same format as inputs
    dividend  : IN signed(DIV_I_W - 1 DOWNTO 0);  --! Input dividend
    divisor   : IN signed(DIV_I_W - 1 DOWNTO 0);  --! Input divisor
    quotient  : OUT signed(DIV_I_W - 1 DOWNTO 0); --! Output quotient
    remainder : OUT signed(DIV_I_W - 1 DOWNTO 0)  --! Output remainder
  );
  END COMPONENT;

  COMPONENT Maxmin_Unit IS
    GENERIC (Nb : INTEGER); --! Number of bits
    PORT (
      in_l            : IN signed(Nb - 1 DOWNTO 0);
      in_r            : IN signed(Nb - 1 DOWNTO 0);
      sel_max_min_n   : IN STD_LOGIC;
      seq_cond_status : OUT STD_LOGIC_VECTOR(SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0);
      d_out           : OUT signed(Nb - 1 DOWNTO 0)
    );
  END COMPONENT;

  -- #################### SIGNALS ####################

  SIGNAL opcode_reg, opcode                       : unsigned(S_DPU_CFG_WIDTH - 1 DOWNTO 0);               --! Opcode 

  SIGNAL squash_pipe_en, mult_pipe_en, io_regs_en : STD_LOGIC;                                            --! Registers enable

  SIGNAL b_conf                                   : STD_LOGIC_VECTOR(1 DOWNTO 0);                         --! Configuration of reconfigurable multiplier/adder

  -- # INPUTS and constant values
  SIGNAL const_one                                : signed(INP_W - 1 DOWNTO 0);                           --! Constant "1" for Exponential operation
  SIGNAL const_one_resz                           : signed(DIV_I_W - 1 DOWNTO 0);                         --! signal 'const_one' resized to divider input
  SIGNAL in0s, in1s                               : signed(INP_W - 1 DOWNTO 0);                           --! Signed inputs

  SIGNAL in0_2s                                   : signed(INP_W - 1 DOWNTO 0);                           --! 2's complement of in0s

  -- # Saturation in/out
  SIGNAL sat_in                                   : STD_LOGIC_VECTOR(ADD_O_W - 1 DOWNTO 0);               --! Standard Saturation Unit input
  SIGNAL sat_out                                  : STD_LOGIC_VECTOR(MUL_O_W - 1 DOWNTO 0);               --! Final Saturation Unit output	

  -- # Multiplier in/out
  SIGNAL m_in0, m_in1                             : signed(MUL_I_W - 1 DOWNTO 0);                         --! Multiplier input
  SIGNAL m_out                                    : STD_LOGIC_VECTOR(MUL_O_W - 1 DOWNTO 0);               --! Multiplier Output
  SIGNAL m_out_reg                                : STD_LOGIC_VECTOR(MUL_O_W - 1 DOWNTO 0);               --! Multiplier Pipeline Stage output

  -- # Add in/out
  SIGNAL ad_in0, ad_in1, ad_in1_select            : STD_LOGIC_VECTOR(ADD_I_W - 1 DOWNTO 0);               --! Adder input
  SIGNAL add_out                                  : STD_LOGIC_VECTOR(ADD_O_W - 1 DOWNTO 0);               --! Adder output signal
  SIGNAL SO                                       : STD_LOGIC_VECTOR(SLICES - 1 DOWNTO 0);                --! Output of the adder overflowing bits (4 bits since we split to 4)

  -- # Accumulator register
  SIGNAL acc_out                                  : STD_LOGIC_VECTOR(ACC_O_W - 1 DOWNTO 0);               --! Accumulation register signal
  SIGNAL acc_in                                   : STD_LOGIC_VECTOR(ACC_O_W - 1 DOWNTO 0);               --! Accumulator input signal

  -- # Divider in/out
  SIGNAL div_in0, div_in1, div_in1_select         : signed(DIV_I_W - 1 DOWNTO 0);                         --! Divider input
  SIGNAL div_quot, div_rem                        : signed(DIV_O_W - 1 DOWNTO 0);                         --! Divider output

  -- # Squash signals
  SIGNAL sq_in0, sq_in0s                          : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Squash Unit input
  SIGNAL sq_slope                                 : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Slope from Squash Unit
  SIGNAL sq_offs, sq_offs_reg                     : signed(DPU_IN_WIDTH - 1 DOWNTO 0);                    --! Offset from Squash Unit
  SIGNAL exp_result                               : signed(DIV_O_W - 1 DOWNTO 0);                         --! Exponential result signal
  SIGNAL sq_mode, exp_offs_sel                    : STD_LOGIC_VECTOR(1 DOWNTO 0);                         --! Squash Unit mode selector

  SIGNAL s_output                                 : signed(S_DPU_OUT_WIDTH - 1 DOWNTO 0);                 --! Output signal

  -- # MAX signals 
  SIGNAL max_in_left                              : signed (MAX_I_W - 1 DOWNTO 0);                        --! Max/Min input right
  SIGNAL max_in_right                             : signed (MAX_I_W - 1 DOWNTO 0);                        --! Max/Min input left
  SIGNAL max_select                               : STD_LOGIC;                                            --! Select between max and min
  SIGNAL max_out                                  : signed (MAX_I_W - 1 DOWNTO 0);                        --! Maxmin_Unit/Min Output
  SIGNAL seq_cond_status_en                       : STD_LOGIC;                                            --! Enable for the seq_cond_status output register
  SIGNAL seq_cond_status_out                      : STD_LOGIC_VECTOR(SEQ_COND_STATUS_WIDTH - 1 DOWNTO 0); --! Sequencer status output from max/min unit

BEGIN
  -- #################### BEGIN ARCHITECTURE ####################

  io_regs_en <= '0' WHEN opcode = S_IDLE ELSE
    '1'; --! Disables IO registers when NACU is inactive

  --! @TODO remove the register from the configuration is not needed since the signals are registered in the DPU
  opcode <= mode_cfg WHEN mode_cfg /= S_IDLE ELSE
    opcode_reg;

  in0s <= nacu_in_0;
  in1s <= nacu_in_1;

  --! Registered process
  P_reg : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      opcode_reg      <= (OTHERS => '0');
      acc_out         <= (OTHERS => '0');
      seq_cond_status <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      opcode_reg <= mode_cfg;
      -- Output/Accumulator register
      IF acc_clear = '1' THEN
        acc_out <= (OTHERS => '0');
      ELSE
        acc_out <= acc_in;
      END IF;
      IF seq_cond_status_en = '1' THEN
        seq_cond_status <= seq_cond_status_out;
      END IF;
    END IF;
  END PROCESS;

  G_pipeline_mac : IF mac_pipe = 1 GENERATE
    P_mac_pipe : PROCESS (clk, rst_n)
    BEGIN
      IF rst_n = '0' THEN
        m_out_reg <= (OTHERS => '0');
      ELSIF rising_edge(clk) THEN
        -- Multiplier Pipeline stage
        IF clear = '1' THEN
          m_out_reg <= (OTHERS => '0');
        ELSIF mult_pipe_en = '1' THEN
          m_out_reg <= m_out;
        END IF;
      END IF;
    END PROCESS;
  END GENERATE;

  G_n_pipeline_mac : IF mac_pipe = 0 GENERATE
    m_out_reg <= m_out;
  END GENERATE;

  G_squash_pipe : IF div_n_squash = 1 GENERATE
    G_pipeline_squash : IF mac_pipe = 1 GENERATE
      P_squash_pipe : PROCESS (clk, rst_n)
      BEGIN
        IF rst_n = '0' THEN
          sq_offs_reg <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
          -- Squash Unit Pipeline Stage
          IF clear = '1' THEN
            sq_offs_reg <= (OTHERS => '0');
          ELSIF squash_pipe_en = '1' THEN
            sq_offs_reg <= sq_offs;
          END IF;
        END IF;
      END PROCESS;
    END GENERATE;

    G_n_pipeline_squash : IF mac_pipe = 0 GENERATE
      sq_offs_reg <= sq_offs;
    END GENERATE;
  END GENERATE;
  -- ############# Input selection for units #############

  --! This process is used to select the input to each
  --! unit (squash, mul, and adder)

  P_comb : PROCESS (ALL)
    VARIABLE mul_cut : signed(MUL_O_W - 1 DOWNTO fb);
  BEGIN
    -- Squash inputs
    sq_in0             <= (OTHERS => '0');
    sq_in0s            <= (OTHERS => '0');
    -- MAC inputs
    m_in0              <= (OTHERS => '0');
    m_in1              <= (OTHERS => '0');
    -- Div inputs
    div_in0            <= to_signed(1, div_in0'length);
    div_in1            <= to_signed(1, div_in1'length);
    -- Adder inputs
    ad_in0             <= (OTHERS => '0');
    ad_in1             <= (OTHERS => '0');
    -- Acc input
    acc_in             <= sat_out;

    -- Max/Min inputs
    max_in_left        <= (OTHERS => '0');
    max_in_right       <= (OTHERS => '0');
    max_select         <= '0';
    seq_cond_status_en <= '0';

    -- Output
    s_output           <= (OTHERS => '0');

    -- Enable of register
    squash_pipe_en     <= '0';

    -- Multiplier Pipe enable
    mult_pipe_en       <= '1';

    CASE to_integer(opcode) IS
      WHEN S_IDLE             =>
        -- All inputs turn to 0
        -- Squash inputs
        sq_in0       <= (OTHERS => '0');
        sq_in0s      <= (OTHERS => '0');
        -- MAC inputs
        m_in0        <= (OTHERS => '0');
        m_in1        <= (OTHERS => '0');
        -- Div inputs
        div_in0      <= to_signed(0, div_in0'length);
        div_in1      <= to_signed(1, div_in1'length);
        -- Adder inputs
        ad_in0       <= (OTHERS => '0');
        ad_in1       <= (OTHERS => '0');

        -- Max/Min inputs
        max_in_left  <= (OTHERS => '0');
        max_in_right <= (OTHERS => '0');
        max_select   <= '0';

        -- Turn accumulator to zero when idle
        acc_in       <= (OTHERS          => '0');

      WHEN S_SIGM | S_TANHYP | S_EXPON =>
        IF div_n_squash = 1 THEN
          squash_pipe_en <= '1';
          -- Squash inputs
          sq_in0         <= in0s;
          sq_in0s        <= in0_2s;
          -- MAC/Div inputs
          IF (opcode = S_SIGM) OR (opcode = S_TANHYP) THEN
            m_in0   <= in0s;
            m_in1   <= sq_slope;
            div_in0 <= to_signed(0, div_in0'length);
            div_in1 <= to_signed(1, div_in1'length);

          ELSE -- EXPON
            m_in0   <= in0_2s;
            m_in1   <= sq_slope;
            div_in0 <= const_one_resz;
            div_in1 <= signed(add_out((div_in1'length) - 1 DOWNTO 0));

          END IF;
          -- Adder inputs
          mul_cut := signed(m_out_reg(MUL_O_W - 1 DOWNTO fb));
          ad_in0 <= STD_LOGIC_VECTOR(resize(mul_cut, ad_in0'length));
          ad_in1 <= STD_LOGIC_VECTOR(resize(sq_offs_reg, ad_in1'length));

          -- Acc register (output)
          acc_in <= sat_out;
        ELSE
          NULL;
        END IF;

      WHEN S_SM =>
        IF div_n_squash = 1 THEN
          mult_pipe_en <= '0';

          -- Div inputs
          div_in0      <= resize(in0s, div_in0'length);
          div_in1      <= signed(direct_acc);

          -- Acc register (output)
          acc_in       <= STD_LOGIC_VECTOR(div_quot);
        ELSE
          NULL;
        END IF;

      WHEN S_MAC =>
        m_in0  <= in0s;
        m_in1  <= in1s;
        ad_in0 <= m_out_reg;
        ad_in1 <= STD_LOGIC_VECTOR(acc_out);

        -- Acc register
        acc_in <= sat_out;

      WHEN S_MUL =>
        mult_pipe_en <= '0';
        m_in0        <= in0s;
        m_in1        <= in1s;

        -- Acc register (output)
        acc_in       <= m_out;

      WHEN S_ADD =>
        mult_pipe_en <= '0';
        ad_in0       <= STD_LOGIC_VECTOR(resize(in0s, ad_in0'length));
        ad_in1       <= STD_LOGIC_VECTOR(resize(in1s, ad_in1'length));

        -- Acc register (output)
        acc_in       <= sat_out;

      WHEN S_ACC =>
        mult_pipe_en <= '0';
        ad_in0       <= STD_LOGIC_VECTOR(resize(in0s, ad_in0'length));
        ad_in1       <= STD_LOGIC_VECTOR(acc_out);

        -- Acc register (output)
        acc_in       <= sat_out;

      WHEN S_LD_ACC =>
        mult_pipe_en <= '0';
        acc_in       <= STD_LOGIC_VECTOR(resize(in0s, acc_in'length));

      WHEN S_DIV =>
        IF div_n_squash = 1 THEN
          mult_pipe_en <= '0';
          -- @TODO need to check this for fixed point
          div_in0      <= resize(in0s, div_in0'length);
          div_in1      <= resize(in1s, div_in1'length);
          acc_in       <= STD_LOGIC_VECTOR(div_quot);
        ELSE
          NULL;
        END IF;

      WHEN S_SHIFT_L =>
        mult_pipe_en <= '0';
        acc_in       <= STD_LOGIC_VECTOR(shift_left(resize(in0s, acc_in'length), to_integer(in1s)));

      WHEN S_SHIFT_R =>
        mult_pipe_en <= '0';
        acc_in       <= STD_LOGIC_VECTOR(shift_right(resize(in0s, acc_in'length), to_integer(in1s)));

      WHEN S_MAX =>
        mult_pipe_en       <= '0';
        max_in_left        <= in0s;
        max_in_right       <= in1s;
        max_select         <= '1';
        acc_in             <= STD_LOGIC_VECTOR(resize(max_out, acc_in'length));
        seq_cond_status_en <= '1';

      WHEN S_MIN =>
        mult_pipe_en       <= '0';
        max_in_left        <= in0s;
        max_in_right       <= in1s;
        max_select         <= '0';
        acc_in             <= STD_LOGIC_VECTOR(resize(max_out, acc_in'length));
        seq_cond_status_en <= '1';

      WHEN OTHERS =>
        NULL;
    END CASE;

  END PROCESS;

  -- #################### Squash Unit ####################

  G_squash : IF div_n_squash = 1 GENERATE
    --! input 2s complement
    U_2s_compliment : twos_compl
    GENERIC MAP(
      b_width => 16
    )
    PORT MAP(
      d_in  => in0s,
      d_out => in0_2s
    );

    --! Selects type of Nonlinear activator 	
    squash_mode : PROCESS (opcode)
      VARIABLE sq_mode_var : INTEGER;
    BEGIN
      CASE to_integer(opcode) IS
        WHEN S_SIGM =>
          sq_mode_var := 1; -- Sigmoid
        WHEN S_TANHYP =>
          sq_mode_var := 2; -- Hyperbolic Tangent
        WHEN OTHERS =>    -- Exponential
          sq_mode_var := 3;
      END CASE;
      sq_mode <= STD_LOGIC_VECTOR(to_unsigned(sq_mode_var, sq_mode'length));
    END PROCESS;

    --! Squash Unit
    U_squash : Squash_Unit
    GENERIC MAP(
      Nb        => DPU_BITWIDTH,
      frac_part => fb
    )
    PORT MAP(
      -- Inputs
      data_in         => sq_in0,
      data_in_2scompl => sq_in0s,
      squash_mode     => sq_mode,
      -- Outputs
      slope           => sq_slope,
      offset          => sq_offs
    );
  END GENERATE;

  -- #################### Multiplier ####################

  --! Multiplier
  U_Recon_multiplier : conf_mul_Beh
  GENERIC MAP(
    width   => DPU_BITWIDTH,
    s_width => select_w
  )
  PORT MAP(
    in_a => STD_LOGIC_VECTOR(m_in0),
    in_b => STD_LOGIC_VECTOR(m_in1),
    conf => bit_config,
    prod => m_out
  );

  -- #################### Adder ####################	
  -- select ad_in1 port
  ad_in1_select <= ad_in1 WHEN direct_acc_en = '0' ELSE
    direct_acc;
  --! Adder
  U_Recon_adder : adder_nbits
  GENERIC MAP(
    width    => ADD_I_W,
    select_w => select_w
  )
  PORT MAP(
    a    => ad_in0,
    b    => ad_in1_select,
    conf => bit_config,
    SO   => SO,
    sum  => add_out
  );
  -- #################### Exponential ####################
  -- select ad_in1 port
  div_in1_select <= div_in1 WHEN divide_acc = '0' ELSE
    div_direct;
  G_Div : IF div_n_squash = 1 GENERATE
    --! Resize constant one to divider bitwidth
    const_one      <= CONSTANT_ONE (work.DPU_pkg.fb, DPU_IN_WIDTH);
    const_one_resz <= resize(const_one, const_one_resz'length);

    U_divider : divider_pipe
    PORT MAP(
      clk       => clk,
      rst_n     => rst_n,
      const_one => const_one_resz,
      dividend  => div_in0,
      divisor   => div_in1,
      quotient  => div_quot,
      remainder => div_rem
    );

    --! Optimized -1 for Exponential computation
    PROCESS (div_quot)
    BEGIN
      --! Fractional part
      exp_result(fb - 1 DOWNTO 0)                                <= (div_quot(fb - 1 DOWNTO 0));
      --! Sign AND integer part except the lowest integer bit
      exp_result(exp_result'length - 1 DOWNTO DPU_IN_WIDTH - ib) <= (OTHERS => '0');
      --! Lowest integer bit
      exp_result(DPU_IN_WIDTH - ib - 1)                          <= div_quot(DPU_IN_WIDTH - ib);
    END PROCESS;
  END GENERATE;

  -- #################### Saturation Unit #####################

  --! Saturation Unit for all modes except Softmax division
  U_saturation : Saturation_Unit
  PORT MAP(
    d_in   => add_out,
    carry  => SO,
    d_mode => bit_config,
    d_out  => sat_out
  );

  -- #################### MAX/MIN ####################
  U_MAX_MIN : Maxmin_Unit
  GENERIC MAP(Nb => S_DPU_IN_WIDTH) --! Number of bits
  PORT MAP(
    in_l            => max_in_left,
    in_r            => max_in_right,
    sel_max_min_n   => max_select,
    seq_cond_status => seq_cond_status_out,
    d_out           => max_out
  );

  -- #################### Outputs ####################

  --! Output port assignment
  nacu_out <= signed(acc_out);

END rtl;
