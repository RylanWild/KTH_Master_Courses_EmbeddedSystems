-------------------------------------------------------
--! @file scaler.vhd
--! @brief Unit that can be used for scaling a input number from 16 to 4 or 8 bit and vice-versa
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2021-06-20
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
-- Title      : Unit that can be used for scaling a input number from 16 to 4 or 8 bit and vice-versa
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : scaler.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2021-06-20
-- Last update: 2021-06-20
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2021-06-20  1.0      Dimitrios Stathis      Created
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
--! Use DPU package for DPU constants
USE work.DPU_pkg.ALL;
--! Use utility package for the functions
USE work.util_package.ALL;

--! This is a unit tha can be used for scaling between 16 and 8 or 4 bit vectors.

--! The input to the unit is an input vector of one 16 bit, 2x8bit or 4x4bit numbers.
--! Together with the data in vector the scaling factor is given together with an
--! enable signal, the op configuration, and a scale up or down signal.
--! When the enable signal is active the scaler is reading the scale up and down 
--! and op config to decode the input data and decide how to scale the data.
--! When scale-up is selected, the data are scaled from the op-configuration to 16-bit.
--! When scale-down is selected, the data are scaled down from 16 to the op-configuration.
--! The scaling down from 16-bit to 8 bit requires 2 cycles, it requires two 16-bit numbers 
--! and outputs one 2x8-bit vector. When scaling up from 8-bit, it receives one 2x8-bit 
--! scale and outputs two 16-bit numbers in two cycles. Scaling up or down to and from 4-bit
--! works in a similar way, with the differences of 4 cycles/vectors instead of 2.
ENTITY scaler IS
  PORT (
    rst_n        : IN STD_LOGIC;                                        --! Reset (active-low)
    clk          : IN STD_LOGIC;                                        --! Clock
    data_in      : IN STD_LOGIC_VECTOR(DPU_IN_WIDTH - 1 DOWNTO 0);      --! Input Data
    scale_factor : IN STD_LOGIC_VECTOR(DPU_CONS_WIDTH - 1 DOWNTO 0);    --! Scaling value
    scale_up_dw  : IN STD_LOGIC;                                        --! Scale up or down from or to the current configuration, '1' scale up
    op_conf      : IN STD_LOGIC_VECTOR(DPU_OP_CONF_WIDTH - 1 DOWNTO 0); --! Current configuration operation
    enable       : IN STD_LOGIC;                                        --! Enable signal
    data_out     : OUT STD_LOGIC_VECTOR(DPU_OUT_WIDTH - 1 DOWNTO 0)     --! Output data 
  );
END scaler;

--! @brief The architecture of the scaler is using a two process design.
--! @details The architecture is using a set of registers and an FSM to
--! scale the numbers. The scaling happens using a multiplier and multiple 
--! cycles. The number of cycles required is controlled by a counter.
--! We are using a compile register that is using to combine the networks.
ARCHITECTURE RTL OF scaler IS
  --! Number of slices for /2
  CONSTANT slice_0         : INTEGER := 2;
  --! Number of slices for /4
  CONSTANT slice_00        : INTEGER := 4;
  --! Saturation output bitwidth
  CONSTANT OUT_BITS        : NATURAL := DPU_OUT_WIDTH;
  --! Saturation slices bitwidth (/2)
  CONSTANT OUT_SLICE_BIT_2 : NATURAL := OUT_BITS/slice_0;
  --! Saturation slices bitwidth (/4)
  CONSTANT OUT_SLICE_BIT_4 : NATURAL := OUT_BITS/slice_00;
  --! Adder slices type /2
  TYPE tmp_0_ty IS ARRAY (NATURAL RANGE <>) OF signed (OUT_SLICE_BIT_2 - 1 DOWNTO 0);
  --! Adder slices type /4
  TYPE tmp_00_ty IS ARRAY (NATURAL RANGE <>) OF signed (OUT_SLICE_BIT_4 - 1 DOWNTO 0);
  TYPE STATE_TY IS (IDLE, SCALE_UP_8, SCALE_UP_4, SCALE_DW_8, SCALE_DW_4);                 --! State type
  SIGNAL compile_reg, compile_reg_in       : STD_LOGIC_VECTOR(DPU_OUT_WIDTH - 1 DOWNTO 0); --! Output register that compiles the final output (for scaling down)
  SIGNAL input_temp_reg, input_temp_reg_in : STD_LOGIC_VECTOR(DPU_OUT_WIDTH - 1 DOWNTO 0); --! Temporary store of the input number (for scaling up)
  SIGNAL input_reg_en, compile_reg_en      : STD_LOGIC;                                    --! Enable signals for the registers
  SIGNAL counter_en                        : STD_LOGIC;                                    --! Enable signals for the registers
  SIGNAL state, state_next                 : STATE_TY;                                     --! State register and next state variable
  SIGNAL counter, counter_next             : unsigned(1 DOWNTO 0);                         --! Counters for the FSM
BEGIN

  --! Register process
  P_reg : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      compile_reg    <= (OTHERS => '0');
      input_temp_reg <= (OTHERS => '0');
      state          <= IDLE;
      counter        <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      IF compile_reg_en = '1' THEN
        compile_reg <= compile_reg_in;
      END IF;
      -- TODO remove input register if not needed
      IF input_reg_en = '1' THEN
        input_temp_reg <= input_temp_reg_in;
      END IF;
      IF counter_en = '1' THEN
        counter <= counter_next;
      END IF;
      IF enable = '1' THEN
        state <= state_next;
      END IF;
    END IF;
  END PROCESS;

  --! FSM process
  P_FSM : PROCESS (ALL)
    VARIABLE tmp_data     : signed(DPU_OUT_WIDTH - 1 DOWNTO 0);
    VARIABLE in_0_slice   : tmp_0_ty(slice_0 - 1 DOWNTO 0);
    VARIABLE in_00_slice  : tmp_00_ty(slice_00 - 1 DOWNTO 0);
    VARIABLE out_0_slice  : signed (OUT_SLICE_BIT_2 - 1 DOWNTO 0);
    VARIABLE out_00_slice : tmp_00_ty(slice_00 - 1 DOWNTO 0);
    VARIABLE tmp_out_data : signed(DPU_OUT_WIDTH - 1 DOWNTO 0);
    VARIABLE tmp_8        : signed(DPU_CONS_WIDTH + OUT_SLICE_BIT_2 - 1 DOWNTO 0);
    VARIABLE tmp_4        : signed(DPU_CONS_WIDTH + OUT_SLICE_BIT_4 - 1 DOWNTO 0);
    VARIABLE tmp_16       : signed(DPU_CONS_WIDTH + OUT_BITS - 1 DOWNTO 0);
  BEGIN
    input_reg_en      <= '0';
    compile_reg_en    <= '0';
    counter_en        <= '0';
    input_temp_reg_in <= input_temp_reg;
    state_next        <= state;
    compile_reg_in    <= compile_reg;
    counter_next      <= counter;
    tmp_data     := signed(data_in);
    tmp_out_data := (OTHERS => '0');
    FOR i IN 0 TO slice_0 - 1 LOOP
      in_0_slice(i) := signed(data_in((OUT_SLICE_BIT_2 * (i + 1) - 1) DOWNTO OUT_SLICE_BIT_2 * i));
    END LOOP;

    FOR i IN 0 TO slice_00 - 1 LOOP
      in_00_slice(i) := signed(data_in(OUT_SLICE_BIT_4 * (i + 1) - 1 DOWNTO OUT_SLICE_BIT_4 * i));
    END LOOP;

    out_0_slice  := (OTHERS => '0');
    out_00_slice := (OTHERS => (OTHERS => '0'));

    CASE state IS
      WHEN IDLE =>
        IF enable = '1' THEN
          -- 16-bit
          IF op_conf = "00" OR op_conf = "10" THEN
            -- Do nothing
            counter_en     <= '1';
            counter_next   <= (OTHERS => '0');
            compile_reg_en <= '1';
            compile_reg_in <= data_in;
            NULL;
          ELSIF op_conf = "01" THEN -- 8-bit
            counter_en   <= '1';
            counter_next <= counter + 1;
            IF scale_up_dw = '1' THEN
              -- Scale up from 8-bit to 16.
              state_next <= SCALE_UP_8;
              tmp_8 := in_0_slice(to_integer(counter)) * signed(scale_factor);
              -- TODO select the appropriate bit slice (in this case is 8+8=16 bits)
              compile_reg_en <= '1';
              compile_reg_in <= STD_LOGIC_VECTOR(tmp_8(DPU_OUT_WIDTH - 1 DOWNTO 0));
              counter_next   <= counter + 1;
            ELSE
              -- Scale down from 16 to 8
              tmp_16      := tmp_data * signed(scale_factor);
              -- TODO this needs to change according to the fix-point format
              out_0_slice := tmp_16(OUT_SLICE_BIT_2 + DPU_CONS_WIDTH - 1 DOWNTO DPU_CONS_WIDTH);
              compile_reg_en                               <= '1';
              compile_reg_in                               <= compile_reg;
              compile_reg_in(OUT_SLICE_BIT_2 - 1 DOWNTO 0) <= STD_LOGIC_VECTOR(out_0_slice);
              counter_next                                 <= counter + 1;
              state_next                                   <= SCALE_DW_8;
            END IF;
          ELSE -- 4-bit
            counter_en   <= '1';
            counter_next <= counter + 1;
            IF scale_up_dw = '1' THEN
              -- Scale up from 4-bit to 16.
              state_next <= SCALE_UP_4;
              tmp_4 := in_00_slice(to_integer(counter)) * signed(scale_factor);
              -- TODO select the appropriate bit slice (in this case we size up since (4+8=12 bits))
              compile_reg_en <= '1';
              compile_reg_in <= STD_LOGIC_VECTOR(resize(tmp_4, tmp_out_data'length));
            ELSE
              -- Scale down from 16-bit to 4
              tmp_16 := tmp_data * signed(scale_factor);
              -- TODO this needs to change according to the fix-point format

              -- LOOP to implement the mux logic and assign the input to the register
              -- The loop calculates each of the 4 parts of the compilation register depending on the value of the counter
              FOR I IN 0 TO slice_00 - 1 LOOP
                IF I = to_integer(counter) THEN
                  out_00_slice(I) := tmp_16(OUT_SLICE_BIT_4 + DPU_CONS_WIDTH - 1 DOWNTO DPU_CONS_WIDTH);
                ELSE
                  out_00_slice(I) := signed(compile_reg((OUT_SLICE_BIT_4 * (I + 1) - 1) DOWNTO (OUT_SLICE_BIT_4 * I)));
                END IF;
                compile_reg_in((OUT_SLICE_BIT_4 * (I + 1) - 1) DOWNTO OUT_SLICE_BIT_4 * I) <= STD_LOGIC_VECTOR(out_00_slice(I));
              END LOOP;

              compile_reg_en <= '1';
              state_next     <= SCALE_DW_4;
            END IF;
          END IF;
        ELSE
          state_next   <= IDLE;
          counter_next <= (OTHERS => '0');
        END IF;

      WHEN SCALE_UP_8 =>
        state_next <= SCALE_UP_8;
        tmp_8 := in_0_slice(to_integer(counter)) * signed(scale_factor);
        -- TODO select the appropriate bit slice (in this case is 8+8=16 bits)
        compile_reg_en <= '1';
        compile_reg_in <= STD_LOGIC_VECTOR(tmp_8(DPU_OUT_WIDTH - 1 DOWNTO 0));
        counter_en     <= '1';
        counter_next   <= (OTHERS => '0');
        state_next     <= IDLE;

      WHEN SCALE_UP_4 =>
        counter_en <= '1';
        tmp_4 := in_00_slice(to_integer(counter)) * signed(scale_factor);
        -- TODO select the appropriate bit slice (in this case we size up since (4+8=12 bits))
        compile_reg_en <= '1';
        compile_reg_in <= STD_LOGIC_VECTOR(resize(tmp_4, tmp_out_data'length));

        IF counter /= "11" THEN
          counter_next <= counter + 1;
          state_next   <= SCALE_UP_4;
        ELSE
          counter_next <= (OTHERS => '0');
          state_next   <= IDLE;
        END IF;

      WHEN SCALE_DW_8 =>
        -- Scale down from 16 to 8
        tmp_16      := tmp_data * signed(scale_factor);
        -- TODO this needs to change according to the fix-point format
        out_0_slice := tmp_16(OUT_SLICE_BIT_2 + DPU_CONS_WIDTH - 1 DOWNTO DPU_CONS_WIDTH);
        compile_reg_en                                                   <= '1';
        compile_reg_in                                                   <= compile_reg;
        compile_reg_in((OUT_SLICE_BIT_2 * 2 - 1) DOWNTO OUT_SLICE_BIT_2) <= STD_LOGIC_VECTOR(out_0_slice);
        counter_en                                                       <= '1';
        counter_next                                                     <= (OTHERS => '0');
        state_next                                                       <= IDLE;

      WHEN SCALE_DW_4 =>
        -- Scale down from 16-bit to 4
        tmp_16 := tmp_data * signed(scale_factor);
        -- TODO this needs to change according to the fix-point format
        -- LOOP to implement the mux logic and assign the input to the register
        -- The loop calculates each of the 4 parts of the compilation register depending on the value of the counter
        FOR I IN 0 TO slice_00 - 1 LOOP
          IF I = to_integer(counter) THEN
            out_00_slice(I) := tmp_16(OUT_SLICE_BIT_4 + DPU_CONS_WIDTH - 1 DOWNTO DPU_CONS_WIDTH);
          ELSE
            out_00_slice(I) := signed(compile_reg((OUT_SLICE_BIT_4 * (I + 1) - 1) DOWNTO (OUT_SLICE_BIT_4 * I)));
          END IF;
          compile_reg_in((OUT_SLICE_BIT_4 * (I + 1) - 1) DOWNTO OUT_SLICE_BIT_4 * I) <= STD_LOGIC_VECTOR(out_00_slice(I));
        END LOOP;
        compile_reg_en <= '1';
        counter_en     <= '1';
        IF counter /= "11" THEN
          counter_next <= counter + 1;
          state_next   <= SCALE_UP_4;
        ELSE
          counter_next <= (OTHERS => '0');
          state_next   <= IDLE;
        END IF;

      WHEN OTHERS =>
        NULL;
    END CASE;

  END PROCESS;

  data_out <= compile_reg;

END RTL;