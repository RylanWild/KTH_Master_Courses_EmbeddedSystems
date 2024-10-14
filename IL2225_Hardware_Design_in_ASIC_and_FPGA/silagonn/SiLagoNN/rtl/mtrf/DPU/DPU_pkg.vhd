-------------------------------------------------------
--! @file DPU_pkg.vhd
--! @brief Package for the DPU
--! @details 
--! @author Dimitrios Stathis
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
-- Title   : Package for the DPU
-- Project : SiLago
-------------------------------------------------------------------------------
-- File         : DPU_pkg.vhd
-- Author       : Dimitrios Stathis
-- Company      : KTH
-- Created      : 2021-02-16
-- Last update  : 2021-02-16
-- Platform     : SiLago
-- Standard     : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2019
-------------------------------------------------------------------------------
-- Contact      : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions    : 
-- Date        Version  Author                  Description
-- 2021-02-16  1.0      Dimitrios Stathis       Created
-- 2022-09-14  1.1      Dimitrios Stathis       Fixed back with overflow in the
--                                              get_min and max_value functions
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
--! Utility package
USE work.util_package.ALL;
--! DPU in-out BITWIDTH
USE work.top_consts_types_package.BITWIDTH;
--! DPU_MODE_SEL
USE work.top_consts_types_package.DPU_MODE_SEL;
--! DPU_ACC_CLEAR_VECTOR_SIZE
USE work.top_consts_types_package.DPU_ACC_CLEAR_VECTOR_SIZE;
--! DPU_SATURAT
USE work.top_consts_types_package.DPU_SATURAT;

--! \page DPU_package_page DPU package for types and constants
--! \tableofcontents
--! This page contains the detail description for the DPU package.
--! The package defines constants and functions that are used to
--! for the DPU. We split the details of the DPU in too two groups.
--! The first group contains the details for the top design for the
--! DPU and the second the details for the the sub-DPU design.
--! \subsection top_dpu Top level DPU
--! The DPU is created in a hierarchical design. Each DPU is build
--! by combining separate sub-DPU structures. Each sub-DPU can operate
--! independently from each other, depending on the DPU configuration=>
--! \subsection sub_dpu Sub-DPU level
--! The Sub-DPU level implements a single dataflow path. It contains a
--! simple set of operation. The operation is selected depending on
--! the DPU level configuration mode.

--! @brief DPU package for the DRRA fabric
--! @details This package contains the definition of the constants, types,
--! and functions used in the DPU and sub-DPU designs.
PACKAGE DPU_pkg IS

  --------------------------------------------------------------------------------
  -- Constatnts
  --------------------------------------------------------------------------------
  -- Top DPU constatnts
  CONSTANT DPU_BITWIDTH          : NATURAL                              := BITWIDTH; --! DPU in-out bitwidth
  --CONSTANT DPU_MODE_SEL              : NATURAL   := 5;  --! @TODO same as above
  --CONSTANT DPU_ACC_CLEAR_VECTOR_SIZE : NATURAL   := 8;  --! @TODO same as above
  --CONSTANT DPU_SATURAT               : NATURAL   := 2;  --! @TODO same as above

  --! \defgroup DPU_design_constants
  --! @{
  --! \brief Design constant definition for the top level DPU
  --! \details These constants are used for defining the bitwidth and other constants for the top level DPU.
  --! For further info see \ref top_dpu

  --! Division and squash unit for first NACU inside the DPU
  CONSTANT div_n_squash_0        : NATURAL                              := 1;
  --! Division and squash unit for the second NACU inside the DPU
  CONSTANT div_n_squash_1        : NATURAL                              := 0;
  --! MAC pipeline inside the NACU
  CONSTANT mac_pipe              : NATURAL                              := 0;
  --! Squash pipeline inside the NACU
  CONSTANT squash_pipe           : NATURAL                              := 0;

  --! Number of DPU Input data ports
  --CONSTANT NR_OF_DPU_IN_PORTS        : NATURAL   := 4;
  --! Number of DPU Output data ports
  -- CONSTANT NR_OF_DPU_OUT_PORTS       : NATURAL   := 2;
  --! DPU Input data bitwidth
  CONSTANT DPU_IN_WIDTH          : INTEGER                              := DPU_BITWIDTH;
  --! Width of 'dpu_mode_cfg' signal
  CONSTANT DPU_MODE_CFG_WIDTH    : INTEGER                              := DPU_MODE_SEL;
  --! DPU Output data bitwidth
  CONSTANT DPU_OUT_WIDTH         : INTEGER                              := DPU_BITWIDTH;
  --! Width of 'seq_cond_status' signal
  CONSTANT SEQ_COND_STATUS_WIDTH : INTEGER                              := 2;
  --! Width of 'dpu_acc_clear' signal
  CONSTANT DPU_ACC_CLEAR_WIDTH   : INTEGER                              := DPU_ACC_CLEAR_VECTOR_SIZE;
  --! DPU operation config  
  CONSTANT DPU_OP_CONF_WIDTH     : INTEGER                              := 2;
  --! DPU I/O config
  CONSTANT DPU_IO_CONF_WIDTH     : INTEGER                              := 2;
  --! DPU Constant width
  CONSTANT DPU_CONS_WIDTH        : INTEGER                              := DPU_ACC_CLEAR_WIDTH; --! @TODO connect to higher level package
  -----
  -- Inst : 4
  -- IO : 2
  -- MODE : 5
  -- OP : 3
  -- ACC_clear : 8
  -- Constant : 5

  -- Reconfiguration constants
  --! Number of bits for the configuration of the multiplier/adder
  CONSTANT select_w              : NATURAL                              := 2;
  --! Number of slices in the adder
  CONSTANT SLICES                : NATURAL                              := 2 ** select_w;
  --! Number of bits per adder slice
  CONSTANT SLICE_BITS            : NATURAL                              := DPU_BITWIDTH * 2/SLICES;

  -- Format constants for NACU
  --! Number of integer bits (for fixed-point data)
  CONSTANT ib                    : NATURAL                              := 4;
  --! Number of fraction bits
  CONSTANT fb                    : NATURAL                              := DPU_BITWIDTH - 1 - ib;

  --! Number of pipeline stages inside dividers
  CONSTANT DIV_PIPE_NUM          : INTEGER                              := 3;
  --! '0'                                                               = Behavioral divider (for simulation), '1' = DesignWare divider (for synthesis)
  CONSTANT DIV_SYN_SIM_N         : STD_LOGIC                            := '1';

  -- seq_cond_status constants
  --! Sequencer status lower
  CONSTANT SEQ_STATUS_LT         : INTEGER                              := 0;
  --! Sequencer status greater
  CONSTANT SEQ_STATUS_GT         : INTEGER                              := 1;
  --! Sequencer status equal
  CONSTANT SEQ_STATUS_EQ         : INTEGER                              := 2;

  --! @}

  -- ==============================================================================================================================================
  -- DPU opcodes
  -- ==============================================================================================================================================
  --! \defgroup DPU_modes
  --! @{
  --! \brief Definition for the configuration modes for the top DPU
  --! \details These constants define the operation modes for the 
  --! top level of the DPU (opcodes).

  --! Idle opcode
  CONSTANT IDLE                  : INTEGER                              := 0; -- out0, out1 = none
  --! Opcode 2-input addition 
  CONSTANT ADD                   : INTEGER                              := 1; -- out0 = in0 + in1 , out1 = in2 + in3
  --! Opcode input+accumulator addition
  CONSTANT SUM_ACC               : INTEGER                              := 2; -- acc0 = in0 + acc0 , acc1 = in2 + acc1
  --! Opcode input+int Reg addition
  CONSTANT ADD_CONST             : INTEGER                              := 3; -- out0 = in0 + dpureg0 , out1 = in2 + dpureg1
  --! Opcode 2-input subtraction
  CONSTANT SUBT                  : INTEGER                              := 4; -- out0 = in1 - in0 , out1 = in3 - in2
  --! Opcode 2-input subtraction with absolute value
  CONSTANT SUBT_ABS              : INTEGER                              := 5; -- out0 = |in1 - in0| , out1 = |in3 - in2|
  --! UNUSED Opcode 
  CONSTANT MODE_6                : INTEGER                              := 6;
  --! Opcode 2-input multiplication
  CONSTANT MULT                  : INTEGER                              := 7;  -- out0 = in0 * in1 , out1 = in2 * in3
  --! Opcode 3-operand multiply-add
  CONSTANT MULT_ADD              : INTEGER                              := 8;  -- out0 = in0*in1+in2
  --! Opcode input-constant multiplication
  CONSTANT MULT_CONST            : INTEGER                              := 9;  -- out0 = in0 * dpureg0 , out1 = in2 * dpureg1
  --! Opcode 2-input MAC operation
  CONSTANT MAC                   : INTEGER                              := 10; -- acc0 = (in0 * in1) + acc0  , acc1 = (in2 * in3) + acc1
  --! Opcode Load internal register
  CONSTANT LD_IR                 : INTEGER                              := 11; -- IntReg0 = In0, IntReg1 = In1
  --! Opcode input*constant MAC operation
  CONSTANT AXPY                  : INTEGER                              := 12; -- out0 = (in0 * const) + in1 , out1 = (in2 * const) + in3
  --! Opcode max with accumulator
  CONSTANT MAX_MIN_ACC           : INTEGER                              := 13; -- out0 = max(in0, acc0) , out1 = min(in1, acc1)
  --! Opcode max with constant
  CONSTANT MAX_MIN_CONST         : INTEGER                              := 14; -- out0 = max(in0, const) , out1 = min(in1, const)
  --! Unused Opcode
  CONSTANT MODE_15               : INTEGER                              := 15;
  --! Opcode 2-input max
  CONSTANT MAX_MIN               : INTEGER                              := 16; -- out0 = max(in0, in1) , out1 = min(in2, in3)
  --! Opcode 2-input shift left
  CONSTANT SHIFT_L               : INTEGER                              := 17; -- out0 = in0 sla in1 , out1 = in2 sla in3
  --! Opcode 2-input shift right
  CONSTANT SHIFT_R               : INTEGER                              := 18; -- out0 = in0 sra in1 , out1 = in2 sra in3
  --! Opcode sigmoid activator
  CONSTANT SIGM                  : INTEGER                              := 19; -- out0 = sigmoid(in0) , out1 = sigmoid(in1)
  --! Opcode hyperbolic tangent activator
  CONSTANT TANHYP                : INTEGER                              := 20; -- out0 = tanh(in0) , out1 = tanh(in1)
  --! Opcode exponential 
  CONSTANT EXPON                 : INTEGER                              := 21; -- out0 = exp(in0) , out1 = exp(in1) (if DIV_NUM = 2)
  --! Opcode leaky Rectifier Linear Unit activator
  CONSTANT LK_RELU               : INTEGER                              := 22; -- out0 = max(in0,0),  , out1 = max(in2,0)
  --! Opcode Exponential Linear Unit activator
  CONSTANT RELU                  : INTEGER                              := 23; -- out0 = in0 if in0 > 0, else a*(in1-1) , out1 = in2 if in2 > 0, else a*(in3-1)
  --! Opcode standard division
  CONSTANT DIV                   : INTEGER                              := 24; -- out0 = in0/in1 , out1 = in0 % in1
  --! Opcode Softmax denominator accumulation
  CONSTANT ACC_SOFTMAX           : INTEGER                              := 25; -- out0 = in0 + (acc)
  --! Opcode Softmax division
  CONSTANT SM                    : INTEGER                              := 26; -- out0 = in0/(acc) , out1 = none
  --! Opcode Load accumulator 0
  CONSTANT LD_ACC                : INTEGER                              := 27; -- ACC0 = in0 , ACC1 = in1
  --! Opcode for scaling down
  CONSTANT SCALE_DW              : INTEGER                              := 28; -- Scale down, uses the scaling factor (constant input)
  --! Opcode for scaling up
  CONSTANT SCALE_UP              : INTEGER                              := 29; -- Scale up, uses the scaling factor (constant input)
  --! Opcode mac with internal register
  CONSTANT MAC_inter             : INTEGER                              := 30; -- acc0 = in0*intReg0 + acc0, acc1 = in2*intReg1 +acc1
  --! Unused OP code
  CONSTANT MODE_31               : INTEGER                              := 31;

  --! @}

  -- ==============================================================================================================================================

  -- (sub-DPU) NACU Constants 

  --! \defgroup sub_dpu_constants
  --! @{
  --! \ingroup DPU_design_constants
  --! \brief These are constants that are used for the sub-DPU design.
  --! \details These are design constants that are define the sup-DPU design,
  --! such as bit-widths, etc.

  --! Bitwidth for controlling the sub-DPU module (selecting mode)
  CONSTANT S_DPU_CFG_WIDTH       : NATURAL                              := 4;
  --! Sub-dpu input bit-width
  CONSTANT S_DPU_IN_WIDTH        : NATURAL                              := DPU_BITWIDTH;
  --! Sup-dpu output bit-width
  CONSTANT S_DPU_OUT_WIDTH       : NATURAL                              := 2 * DPU_BITWIDTH;
  --! @}

  --! \defgroup sub_dpu_opcodes
  --! @{
  --! \ingroup sub_dpu_constants
  --! \brief These are the definitions for the sub-DPU modes.
  --! \details These modes are used to configure the sub-DPU module

  --! Opcode idle state
  CONSTANT S_IDLE                : INTEGER                              := 0;
  --! Opcode Multiply-Add-Accumulate
  CONSTANT S_MAC                 : INTEGER                              := 1;
  --! Opcode Sigmoid 
  CONSTANT S_SIGM                : INTEGER                              := 2;
  --! Opcode Hyperbolic Tangent
  CONSTANT S_TANHYP              : INTEGER                              := 3;
  --! Opcode Exponential
  CONSTANT S_EXPON               : INTEGER                              := 4;
  --! Opcode Softmax division
  CONSTANT S_SM                  : INTEGER                              := 5;
  --! Opcode Multiplication
  CONSTANT S_MUL                 : INTEGER                              := 6;
  --! Opcode ADD
  CONSTANT S_ADD                 : INTEGER                              := 7;
  --! Opcode ACC
  CONSTANT S_ACC                 : INTEGER                              := 8;
  --! Opcode to load accumulator 
  CONSTANT S_LD_ACC              : INTEGER                              := 9;
  --! Opcode for div
  CONSTANT S_DIV                 : INTEGER                              := 10;
  --! Opcode 2-input shift left
  CONSTANT S_SHIFT_L             : INTEGER                              := 11;
  --! Opcode 2-input shift right
  CONSTANT S_SHIFT_R             : INTEGER                              := 12;
  --! Opcode Max
  CONSTANT S_MAX                 : INTEGER                              := 13;
  --! Opcode Min
  CONSTANT S_MIN                 : INTEGER                              := 14;

  --! @}

  --! \defgroup sub_dpu_modules
  --! @{
  --! \ingroup sub_dpu_constants
  --! \brief These are the definitions for the constants used by the sub-dpu's modules=>
  --! \details Modules include adder, multiplier, saturation unit, shifter, divider, squash unit

  --! Sub-Dpu input width
  CONSTANT INP_W                 : NATURAL                              := DPU_IN_WIDTH;
  --! Sub-Dpu output width
  CONSTANT OUT_W                 : NATURAL                              := DPU_OUT_WIDTH;

  --! Sub-Dpu multiplier input width
  CONSTANT MUL_I_W               : NATURAL                              := DPU_IN_WIDTH;
  --! Sub-Dpu multiplier output width
  CONSTANT MUL_O_W               : NATURAL                              := 2 * MUL_I_W;

  --! Sub-Dpu adder input width
  CONSTANT ADD_I_W               : NATURAL                              := MUL_O_W;
  --! Sub-Dpu adder output width
  CONSTANT ADD_O_W               : NATURAL                              := ADD_I_W;
  --! Sub-DPU carry output width 
  CONSTANT ADD_C_W               : NATURAL                              := SLICES;

  --! Sub-Dpu accumulator output width
  CONSTANT ACC_O_W               : NATURAL                              := 2 * DPU_IN_WIDTH;

  --! Sub-DPU divider input width
  CONSTANT DIV_I_W               : NATURAL                              := ACC_O_W;
  --! Sub-DPU divider output width
  CONSTANT DIV_O_W               : NATURAL                              := ACC_O_W;

  --! Sub-DPU max/min input width
  CONSTANT MAX_I_W               : NATURAL                              := DPU_IN_WIDTH;
  CONSTANT MAX_O_W               : NATURAL                              := MAX_I_W;

  --! Saturation unit configuration bits
  CONSTANT SAT_CONF_BITS         : NATURAL                              := 2;
  --! Saturation input bitwidth
  CONSTANT SAT_IN_BITS           : NATURAL                              := 32;
  --! Saturation output bitwidth
  CONSTANT SAT_OUT_BITS          : NATURAL                              := SAT_IN_BITS;
  --! Saturation slices bitwidth (/2)
  CONSTANT SAT_SLICE_BIT_2       : NATURAL                              := SAT_OUT_BITS/2;
  --! Saturation slices bitwidth (/4)
  CONSTANT SAT_SLICE_BIT_4       : NATURAL                              := SAT_OUT_BITS/4;
  ----------------------------------------------------
  -- REV 1.1 2022-09-14 ------------------------------
  ----------------------------------------------------
  --Turned the function from integer (limited 32 bit range) to signed to avoid the issue
  --! Max value for full saturation
  CONSTANT MAX_FULL_SAT          : SIGNED(SAT_OUT_BITS - 1 DOWNTO 0)    := get_max_val(SAT_OUT_BITS);
  --! Min value for full saturation
  CONSTANT MIN_FULL_SAT          : SIGNED(SAT_OUT_BITS - 1 DOWNTO 0)    := get_min_val(SAT_OUT_BITS);
  --! Max value for /2 saturation
  CONSTANT MAX_2_SAT             : SIGNED(SAT_SLICE_BIT_2 - 1 DOWNTO 0) := get_max_val(SAT_SLICE_BIT_2);
  --! Min value for /2 saturation
  CONSTANT MIN_2_SAT             : SIGNED(SAT_SLICE_BIT_2 - 1 DOWNTO 0) := get_min_val(SAT_SLICE_BIT_2);
  --! Max value for /4 saturation
  CONSTANT MAX_4_SAT             : SIGNED(SAT_SLICE_BIT_4 - 1 DOWNTO 0) := get_max_val(SAT_SLICE_BIT_4);
  --! Min value for /4 saturation
  CONSTANT MIN_4_SAT             : SIGNED(SAT_SLICE_BIT_4 - 1 DOWNTO 0) := get_min_val(SAT_SLICE_BIT_4);
  ----------------------------------------------------
  -- End of modification REV 1.1 ---------------------
  ----------------------------------------------------

  --! Adder slices type /2
  TYPE sum_0_ty IS ARRAY (NATURAL RANGE <>) OF signed (SLICE_BITS * 2 DOWNTO 0);
  --! Adder slices type /4
  TYPE sum_00_ty IS ARRAY (NATURAL RANGE <>) OF signed (SLICE_BITS DOWNTO 0);
  --! Adder input output type
  TYPE adder_array_inOut_ty IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(SLICE_BITS - 1 DOWNTO 0);

  --! @}

  --! Function calculating fixed point number 1 in different formats
  --! \param fb : natural, number of fraction bits
  --! \param Nb : natural, bitwidth
  --! \return Signed, representation of number '1' in the selected format
  FUNCTION CONSTANT_ONE (fb, Nb : NATURAL) RETURN signed;

END PACKAGE DPU_pkg;

--! Package body for the DPU package
PACKAGE BODY DPU_pkg IS

  --! Implementation of the function CONSTANT_ONE
  FUNCTION CONSTANT_ONE (fb, Nb : NATURAL) RETURN signed IS
    VARIABLE const_one            : signed (Nb - 1 DOWNTO 0);
  BEGIN

    IF fb < Nb - 1 THEN
      --! Constant One generation
      const_one := to_signed(2 ** (fb), const_one'length);
    ELSIF fb = Nb - 1 THEN
      --! If fixed-point format has no integer bits, 1 can not be represented, so we saturate to 1-2^(-frac_point)
      const_one := to_signed(2 ** (Nb - 1) - 1, const_one'length);
    ELSE
      REPORT "ERROR: FB larger than bitwidth" SEVERITY FAILURE;
    END IF;

    RETURN const_one;

  END FUNCTION;

END PACKAGE BODY;