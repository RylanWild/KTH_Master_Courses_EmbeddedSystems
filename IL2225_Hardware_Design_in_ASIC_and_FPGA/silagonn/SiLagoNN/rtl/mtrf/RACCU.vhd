-------------------------------------------------------
--! @file RACCU.vhd
--! @brief RACCU
--! @details This an integer DPU with modes written in top_consts_types_package.vhd file
--! @author Nasim Farahini
--! @version 1.0
--! @date 2020-02-07
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
-- Title      : RACCU
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : RACCU.vhd
-- Author     : Nasim Farahini
-- Company    : KTH
-- Created    : 2014-04-15
-- Last update: 2022-02-03
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2014
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2014-04-15  1.0      Nasim Farahini
-- 2020-04-30  2.0      Dimitrios stathis       Modified to fit with the shared
--                                              register file and the loop accelerator.
--                                              Also changed from arith to numeric_std
--                                              and from SLL/SLR to shift_left/right functions.
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

LIBRARY IEEE, work;
USE IEEE.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.top_consts_types_package.ALL;

ENTITY RACCU IS
  PORT (
    clk               : IN STD_LOGIC;                                                      --! Clock 
    rst_n             : IN STD_LOGIC;                                                      --! Reset
    raccu_in1         : IN STD_LOGIC_VECTOR (RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0);     --! Value of operand 1 or address of RACCU RF when dynamic
    raccu_in2         : IN STD_LOGIC_VECTOR (RACCU_OPERAND2_VECTOR_SIZE - 1 DOWNTO 0);     --! Value of operand 2 or address of RACCU RF when dynamic
    raccu_cfg_mode    : IN STD_LOGIC_VECTOR (RACCU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);     --! RACCU mode
    raccu_res_address : IN STD_LOGIC_VECTOR (RACCU_RESULT_ADDR_VECTOR_SIZE - 1 DOWNTO 0);  --! RF address where to store the result of the operation
    data_RF           : IN raccu_reg_out_ty;                                               --! Data from the RACCU RF
    wr_addr           : OUT STD_LOGIC_VECTOR (RACCU_RESULT_ADDR_VECTOR_SIZE - 1 DOWNTO 0); --! RF write address from the RACCU
    wr_en             : OUT STD_LOGIC;                                                     --! RF write enable
    data_to_RF        : OUT STD_LOGIC_VECTOR(RACCU_REG_BITWIDTH - 1 DOWNTO 0)              --! Data output to the RF

  );
END RACCU;

ARCHITECTURE beh OF RACCU IS
  ----------------------------------------------------
  -- REV 2.0 2020-05-05 ------------------------------
  ----------------------------------------------------
  -- Move the add/subtract to an if statement to ensure resource sharing 
  --SIGNAL add_res, add_in1, add_in2 : std_logic_vector (RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0); --! Adder
  --SIGNAL sub_in1, sub_in2, sub_res : std_logic_vector (RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0); --! Subtractor
  SIGNAL res, sigOp1, sigOp2 : signed (RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0);   --! Adder
  SIGNAL addSub              : STD_LOGIC;                                          --! Signaling addition or subtraction
  ----------------------------------------------------
  -- End of modification REV 2.0 ---------------------
  ----------------------------------------------------
  SIGNAL wr_enb              : STD_LOGIC;                                          --! Write enable for the RF
  SIGNAL result              : STD_LOGIC_VECTOR (RACCU_REG_BITWIDTH - 1 DOWNTO 0); --! Result of the RACCU operation
  SIGNAL iterators           : loop_iterators_ty;                                  --! Iterators from the RACCU RF
BEGIN
  ----------------------------------------------------
  -- REV 2.0 2020-04-30 ------------------------------
  ----------------------------------------------------
  -- raccu_regout   <= data_reg;
  -- raccu_loop_reg <= loop_reg;
  -- add_res <= std_logic_vector(signed(add_in1) + signed(add_in2));
  -- sub_res <= std_logic_vector(signed(sub_in1) - signed(sub_in2));
  add_sub_p : PROCESS (addSub, sigOp1, sigOp2)
  BEGIN
    IF addSub = '1' THEN
      res <= sigOp1 + sigOp2;
    ELSE
      res <= sigOp1 - sigOp2;
    END IF;
  END PROCESS add_sub_p;
  ----------------------------------------------------
  -- End of modification REV 2.0 ---------------------
  ----------------------------------------------------
  ----------------------------------------------------
  -- REV 2.0 2020-04-30 ------------------------------
  ----------------------------------------------------
  -- ORIGINAL CODE:
  -- 
  -- raccu_regout_process : PROCESS (rst_n, clk)
  -- BEGIN
  --     IF rst_n = '0' THEN
  --         data_reg <= (OTHERS => (OTHERS => '0'));
  --     ELSIF rising_edge(clk) THEN
  --         IF wr_enb = '1' THEN
  --             data_reg(unsigned(raccu_res_address)) <= result;
  --         END IF;
  --     END IF;
  -- END PROCESS raccu_regout_process;

  -- Modifications: 
  -- Removed the register and send to the RF

  data_to_RF <= result;
  wr_addr    <= raccu_res_address;
  wr_en      <= wr_enb;
  ----------------------------------------------------
  -- End of modification REV 2.0 ---------------------
  ----------------------------------------------------

  ----------------------------------------------------
  -- REV 2.0 2020-04-30 ------------------------------
  ----------------------------------------------------
  --loop_reg_process : PROCESS (rst_n, clk)
  --BEGIN
  --    IF rst_n = '0' THEN
  --        loop_reg <= (OTHERS => (loop_index_value => (OTHERS => '0'), loop_counter => (OTHERS => '0'), loop_end_flag => '0'));
  --    ELSIF clk'event AND clk = '1' THEN
  --        IF l_index_val_wr_enb = '1' THEN
  --            loop_reg(CONV_INTEGER(raccu_res_address)).loop_index_value <= loop_reg_tmp(CONV_INTEGER(raccu_res_address)).loop_index_value;
  --        END IF;
  --        IF l_counter_wr_enb = '1' THEN
  --            loop_reg(CONV_INTEGER(raccu_res_address)).loop_counter <= loop_reg_tmp(CONV_INTEGER(raccu_res_address)).loop_counter;
  --        END IF;
  --        IF l_end_flag_wr_enb = '1' THEN
  --            loop_reg(CONV_INTEGER(raccu_res_address)).loop_end_flag <= loop_reg_tmp(CONV_INTEGER(raccu_res_address)).loop_end_flag;
  --        END IF;
  --    END IF;
  --END PROCESS loop_reg_process;
  ----------------------------------------------------
  -- End of modification REV 2.0 ---------------------
  ----------------------------------------------------

  --! Combinatorial process that selects the RACCU operation and assigns the results
  raccu_mode_process : PROCESS (raccu_cfg_mode, raccu_res_address, data_RF, raccu_in1, raccu_in2, res)
    VARIABLE raccu_in1_tmp : STD_LOGIC_VECTOR (RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0) := (OTHERS => '0');
    VARIABLE raccu_in2_tmp : STD_LOGIC_VECTOR (RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0) := (OTHERS => '0');
  BEGIN -- process raccu_mode_process

    ----------------------------------------------------
    -- REV 2.0 2020-04-30 ------------------------------
    ----------------------------------------------------
    -- FOR i IN 0 TO MAX_NO_OF_RACCU_LOOPS - 1 LOOP
    -- loop_reg_tmp(i) <= (loop_index_value => loop_reg(i).loop_index_value, loop_counter => loop_reg(i).loop_counter, loop_end_flag => loop_reg(i).loop_end_flag);
    -- END LOOP;
    -- l_index_val_wr_enb <= '0';
    -- l_end_flag_wr_enb  <= '0';
    -- l_counter_wr_enb   <= '0';3
    -- no_of_iterations <= (OTHERS => '0');

    -- Default values
    sigOp1 <= (OTHERS => '0');
    sigOp2 <= (OTHERS => '0');
    addSub <= '1';
    wr_enb <= '0';
    result <= (OTHERS => '0');
    CASE to_integer(unsigned(raccu_cfg_mode)) IS
        -- WHEN RAC_MODE_LOOP_HEADER =>
        -- 
        --     add_in1 <= loop_reg(CONV_INTEGER(raccu_res_address)).loop_counter;
        --     add_in2 <= "0000001";
        -- 
        --     IF loop_reg(CONV_INTEGER(raccu_res_address)).loop_counter = 0 THEN
        --         loop_reg_tmp(CONV_INTEGER(raccu_res_address)).loop_index_value <= raccu_in1;--loading start index value
        --         l_index_val_wr_enb                                             <= '1';
        --     END IF;
        -- 
        --     IF raccu_in2_sd = '0' THEN
        --         no_of_iterations <= raccu_in2;
        --     ELSE
        --         no_of_iterations <= data_reg(CONV_INTEGER(raccu_in2(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0)));
        --     END IF;
        -- 
        --     IF raccu_in2 = add_res THEN --if no_of_iterations= add_res then , bug of delta delay
        --         l_end_flag_wr_enb                                           <= '1';
        --         loop_reg_tmp(CONV_INTEGER(raccu_res_address)).loop_end_flag <= '1';
        --     ELSE
        --         l_counter_wr_enb                                           <= '1';
        --         loop_reg_tmp(CONV_INTEGER(raccu_res_address)).loop_counter <= add_res;
        --     END IF;
        -- 
        -- WHEN RAC_MODE_LOOP_TAIL =>
        -- 
        --     IF loop_reg(CONV_INTEGER(raccu_res_address)).loop_end_flag = '0' THEN
        --         add_in1                                                        <= loop_reg(CONV_INTEGER(raccu_res_address)).loop_index_value;
        --         add_in2                                                        <= raccu_in1;
        --         loop_reg_tmp(CONV_INTEGER(raccu_res_address)).loop_index_value <= add_res;
        --         l_index_val_wr_enb                                             <= '1';
        --     ELSE
        --         l_end_flag_wr_enb  <= '1';
        --         l_index_val_wr_enb <= '1';
        --         l_counter_wr_enb   <= '1';
        --         loop_reg_tmp       <= (OTHERS => (loop_index_value => (OTHERS => '0'), loop_counter => (OTHERS => '0'), loop_end_flag => '0'));
        --     END IF;

      WHEN RAC_MODE_ADD | RAC_MODE_SUB =>

        IF RAC_MODE_ADD = to_integer(unsigned(raccu_cfg_mode)) THEN
          addSub <= '1';
        ELSE
          addSub <= '0';
        END IF;

        -- TODO check if need to change to raccu_in1(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0), if more than what needed is used for addressing
        --sigOp1 <= signed(data_RF(to_integer(unsigned(raccu_in1))));

        --sigOp2 <= signed(data_RF(to_integer(unsigned(raccu_in2))));
        sigOp1 <= signed(raccu_in1);
      	sigOp2 <= signed(raccu_in2);
        result <= STD_LOGIC_VECTOR(res);
        wr_enb <= '1';

      WHEN RAC_MODE_SHFT_R =>

        raccu_in1_tmp := raccu_in1;

        raccu_in2_tmp := raccu_in2;

        result <= STD_LOGIC_VECTOR(shift_right(signed(raccu_in1_tmp), to_integer(unsigned(raccu_in2_tmp))));
        wr_enb <= '1';

      WHEN RAC_MODE_SHFT_L =>

        raccu_in1_tmp := raccu_in1;

        raccu_in2_tmp := raccu_in2;

        result <= STD_LOGIC_VECTOR(shift_left(signed(raccu_in1_tmp), to_integer(unsigned(raccu_in2_tmp))));
        wr_enb <= '1';

      WHEN RAC_MODE_ADD_SH_L | RAC_MODE_SUB_SH_L => -- Arithmetic shift left and add/subtract value of the register

        IF RAC_MODE_ADD_SH_L = to_integer(unsigned(raccu_cfg_mode)) THEN
          addSub <= '1';
        ELSE
          addSub <= '0';
        END IF;

        raccu_in1_tmp := raccu_in1;

        raccu_in2_tmp := raccu_in2;

        sigOp1 <= shift_left(signed(raccu_in1_tmp), to_integer(unsigned(raccu_in2_tmp))); -- Input shifted left 
        sigOp2 <= signed(data_RF(to_integer(unsigned(raccu_res_address))));               -- Add or subtract the value of the register
        wr_enb <= '1';
        --------------------------------------------------------------------------------
        -- OLD CODE --
        --------------------------------------------------------------------------------
        -- In this mode, op1 determines the loop address and RACCU should add op2 value (whether static or dynamic)
        -- to the current index value (loop counter) of the specified loop and write the result to the res_address
        -- 
        -- WHEN RAC_MODE_ADD_WITH_LOOP_INDEX =>
        --    ------------------------------------------------------------------------
        --    -- MODIFICATION: CHANGE THE RANGE FOR raccu_in_1 TO LOOP_REG_WIDTH TO
        --    --               AVOID RANGE MISMATCH IN TRANSITION OF STATES.
        --    ------------------------------------------------------------------------
        --    -- ORIGINAL CODE:
        --    -- add_in1 <= loop_reg(to_integer(unsigned(raccu_in1(RACCU_REG_ADDRS_WIDTH-1 DOWNTO 0)))).loop_index_value;
        --    ------------------------------------------------------------------------
        --    -- MODIFIED CODE:
        --    add_in1 <= loop_reg(to_integer(unsigned(raccu_in1(LOOP_REG_WIDTH - 1 DOWNTO 0)))).loop_index_value;
        --    ------------------------------------------------------------------------
        --    -- MODIFICATION END
        --    ------------------------------------------------------------------------
        --    IF raccu_in2_sd = '0' THEN
        --        add_in2 <= raccu_in2;
        --    ELSE
        --        add_in2 <= data_RF(unsigned(raccu_in2(RACCU_REG_ADDRS_WIDTH - 1 DOWNTO 0)));
        --    END IF;
        --
        --    result <= add_res;
        --    wr_enb <= '1';
      WHEN OTHERS =>

    END CASE;
    ----------------------------------------------------
    -- End of modification REV 2.0 ---------------------
    ----------------------------------------------------
  END PROCESS raccu_mode_process;

END beh;
