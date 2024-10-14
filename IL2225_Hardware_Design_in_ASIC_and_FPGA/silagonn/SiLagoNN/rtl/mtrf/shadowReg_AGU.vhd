-------------------------------------------------------
--! @file shadowReg_AGU.vhd
--! @brief Shadow register for AGU instructions, to be instantiated before the AGU
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2020-02-10
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
-- Title      : Shadow register for AGU instructions, to be instantiated before the AGU
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : shadowReg_AGU.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2020-02-10
-- Last update: 2020-02-10
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2020
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2020-02-10  1.0      Dimitrios Stathis      Created
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
LIBRARY IEEE;
--! Use standard library
USE IEEE.std_logic_1164.ALL;
--! Use numeric standard library for arithmetic operations
USE ieee.numeric_std.ALL;
--! Top types and constants package
USE work.top_consts_types_package.ALL;

--! Shadow register for pre-fetching the AGU instruction

--! This shadow register is dedicated to store one AGU instruction. It releases the instruction when
--! an immediate signal is triggered. If the immediate signal is triggered by the same instruction as
--! the one that is supposed to be store in this register, then the shadow register is by-passed and the
--! instruction is moved directly to the AGU.
ENTITY shadowReg_AGU IS
    PORT (
        rst_n     : IN STD_LOGIC; --! Reset (active-low)
        clk       : IN STD_LOGIC; --! Clock
        immediate : IN std_logic;
        -- Instruction input --
        instr_start          : IN std_logic;
        instr_initial_delay  : IN std_logic_vector(INITIAL_DELAY_WIDTH - 1 DOWNTO 0);
        instr_start_addrs    : IN std_logic_vector(START_ADDR_WIDTH - 1 DOWNTO 0);
        instr_step_val       : IN std_logic_vector(ADDR_OFFSET_WIDTH - 1 DOWNTO 0);
        instr_step_val_sign  : IN std_logic_vector(ADDR_OFFSET_SIGN_WIDTH - 1 DOWNTO 0);
        instr_no_of_addrs    : IN std_logic_vector(ADDR_COUNTER_WIDTH - 1 DOWNTO 0);
        instr_middle_delay   : IN std_logic_vector(REG_FILE_MIDDLE_DELAY_PORT_SIZE - 1 DOWNTO 0);
        instr_no_of_rpts     : IN std_logic_vector(NUM_OF_REPT_PORT_SIZE - 1 DOWNTO 0);
        instr_rpt_step_value : IN std_logic_vector(REP_STEP_VALUE_PORT_SIZE - 1 DOWNTO 0);
        instr_rpt_delay      : IN std_logic_vector(REPT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
        -- Instruction output --
        instr_start_out          : OUT std_logic;
        instr_initial_delay_out  : OUT std_logic_vector(INITIAL_DELAY_WIDTH - 1 DOWNTO 0);
        instr_start_addrs_out    : OUT std_logic_vector(START_ADDR_WIDTH - 1 DOWNTO 0);
        instr_step_val_out       : OUT std_logic_vector(ADDR_OFFSET_WIDTH - 1 DOWNTO 0);
        instr_step_val_sign_out  : OUT std_logic_vector(ADDR_OFFSET_SIGN_WIDTH - 1 DOWNTO 0);
        instr_no_of_addrs_out    : OUT std_logic_vector(ADDR_COUNTER_WIDTH - 1 DOWNTO 0);
        instr_middle_delay_out   : OUT std_logic_vector(REG_FILE_MIDDLE_DELAY_PORT_SIZE - 1 DOWNTO 0);
        instr_no_of_rpts_out     : OUT std_logic_vector(NUM_OF_REPT_PORT_SIZE - 1 DOWNTO 0);
        instr_rpt_step_value_out : OUT std_logic_vector(REP_STEP_VALUE_PORT_SIZE - 1 DOWNTO 0);
        instr_rpt_delay_out      : OUT std_logic_vector(REPT_DELAY_VECTOR_SIZE - 1 DOWNTO 0)
    );
END shadowReg_AGU;

--! @brief Architecture of the AGU instruction shadow register.
--! @details The shadow register has the same structure as the the normal shadow register for the DPU, switchbox and DiMArch instructions.
ARCHITECTURE RTL OF shadowReg_AGU IS
    SIGNAL instr_start_sig          : std_logic;
    SIGNAL instr_initial_delay_sig  : std_logic_vector(INITIAL_DELAY_WIDTH - 1 DOWNTO 0);
    SIGNAL instr_start_addrs_sig    : std_logic_vector(START_ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL instr_step_val_sig       : std_logic_vector(ADDR_OFFSET_WIDTH - 1 DOWNTO 0);
    SIGNAL instr_step_val_sign_sig  : std_logic_vector(ADDR_OFFSET_SIGN_WIDTH - 1 DOWNTO 0);
    SIGNAL instr_no_of_addrs_sig    : std_logic_vector(ADDR_COUNTER_WIDTH - 1 DOWNTO 0);
    SIGNAL instr_middle_delay_sig   : std_logic_vector(REG_FILE_MIDDLE_DELAY_PORT_SIZE - 1 DOWNTO 0);
    SIGNAL instr_no_of_rpts_sig     : std_logic_vector(NUM_OF_REPT_PORT_SIZE - 1 DOWNTO 0);
    SIGNAL instr_rpt_step_value_sig : std_logic_vector(REP_STEP_VALUE_PORT_SIZE - 1 DOWNTO 0);
    SIGNAL instr_rpt_delay_sig      : std_logic_vector(REPT_DELAY_VECTOR_SIZE - 1 DOWNTO 0);
BEGIN
    shadow : PROCESS (clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            instr_start_sig          <= '0';
            instr_initial_delay_sig  <= (OTHERS => '0');
            instr_start_addrs_sig    <= (OTHERS => '0');
            instr_step_val_sig       <= (OTHERS => '0');
            instr_step_val_sign_sig  <= (OTHERS => '0');
            instr_no_of_addrs_sig    <= (OTHERS => '0');
            instr_middle_delay_sig   <= (OTHERS => '0');
            instr_no_of_rpts_sig     <= (OTHERS => '0');
            instr_rpt_step_value_sig <= (OTHERS => '0');
            instr_rpt_delay_sig      <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF immediate = '1' THEN
                instr_start_sig          <= '0';
                instr_initial_delay_sig  <= (OTHERS => '0');
                instr_start_addrs_sig    <= (OTHERS => '0');
                instr_step_val_sig       <= (OTHERS => '0');
                instr_step_val_sign_sig  <= (OTHERS => '0');
                instr_no_of_addrs_sig    <= (OTHERS => '0');
                instr_middle_delay_sig   <= (OTHERS => '0');
                instr_no_of_rpts_sig     <= (OTHERS => '0');
                instr_rpt_step_value_sig <= (OTHERS => '0');
                instr_rpt_delay_sig      <= (OTHERS => '0');
            ELSE
                IF instr_start = '1' THEN
                    instr_start_sig          <= instr_start;
                    instr_initial_delay_sig  <= instr_initial_delay;
                    instr_start_addrs_sig    <= instr_start_addrs;
                    instr_step_val_sig       <= instr_step_val;
                    instr_step_val_sign_sig  <= instr_step_val_sign;
                    instr_no_of_addrs_sig    <= instr_no_of_addrs;
                    instr_middle_delay_sig   <= instr_middle_delay;
                    instr_no_of_rpts_sig     <= instr_no_of_rpts;
                    instr_rpt_step_value_sig <= instr_rpt_step_value;
                    instr_rpt_delay_sig      <= instr_rpt_delay;
                END IF;
            END IF;
        END IF;
    END PROCESS shadow;

    outputSelect : PROCESS (ALL)
    BEGIN
        instr_start_out          <= '0';
        instr_initial_delay_out  <= (OTHERS => '0');
        instr_start_addrs_out    <= (OTHERS => '0');
        instr_step_val_out       <= (OTHERS => '0');
        instr_step_val_sign_out  <= (OTHERS => '0');
        instr_no_of_addrs_out    <= (OTHERS => '0');
        instr_middle_delay_out   <= (OTHERS => '0');
        instr_no_of_rpts_out     <= (OTHERS => '0');
        instr_rpt_step_value_out <= (OTHERS => '0');
        instr_rpt_delay_out      <= (OTHERS => '0');
        IF immediate = '1' THEN   -- If an immediate instruction output the appropriate instruction
            IF instr_start = '1' THEN -- If The instruction triggering the immediate is a AGU, by-pass the register
                instr_start_out          <= instr_start;
                instr_initial_delay_out  <= instr_initial_delay;
                instr_start_addrs_out    <= instr_start_addrs;
                instr_step_val_out       <= instr_step_val;
                instr_step_val_sign_out  <= instr_step_val_sign;
                instr_no_of_addrs_out    <= instr_no_of_addrs;
                instr_middle_delay_out   <= instr_middle_delay;
                instr_no_of_rpts_out     <= instr_no_of_rpts;
                instr_rpt_step_value_out <= instr_rpt_step_value;
                instr_rpt_delay_out      <= instr_rpt_delay;
            ELSE -- Otherwise, send out the registered values
                instr_start_out          <= instr_start_sig;
                instr_initial_delay_out  <= instr_initial_delay_sig;
                instr_start_addrs_out    <= instr_start_addrs_sig;
                instr_step_val_out       <= instr_step_val_sig;
                instr_step_val_sign_out  <= instr_step_val_sign_sig;
                instr_no_of_addrs_out    <= instr_no_of_addrs_sig;
                instr_middle_delay_out   <= instr_middle_delay_sig;
                instr_no_of_rpts_out     <= instr_no_of_rpts_sig;
                instr_rpt_step_value_out <= instr_rpt_step_value_sig;
                instr_rpt_delay_out      <= instr_rpt_delay_sig;
            END IF;
        END IF;
    END PROCESS outputSelect;
END RTL;