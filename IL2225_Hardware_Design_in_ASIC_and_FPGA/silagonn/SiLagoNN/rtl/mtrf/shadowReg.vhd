-------------------------------------------------------
--! @file shadowReg.vhd
--! @brief Shadow register for DPU, switchbox, agus, sram etc
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2020-02-10
--! @bug NONE
--! @todo Change the 0 to a constant, for this the DPU modes need to be declared in ta package (where we check the dpu configuration)
--! @todo Check that the correct bit is taken, bit 10 is used for now by checking the cell_config_swb.vhd
--! @todo It is possible to create 2 different registers between the DiMArch route and read/write but two busses to the DiMArch will be needed. A better solution to be able to store 1 route, 1 read and 1 write instruction and issue them one after the other. 
--! @todo The shadow register can be made either generic (so different type of instructions can be stored) or can be splitted in different architectures for each instruction.
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
-- Title      : Shadow register for DPU, switchbox, agus, sram etc
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : shadowReg.vhd
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
--! DiMArch noc types and constants package
USE work.noc_types_n_constants.ALL;

--! Shadow register for dpu, switchbox and DiMArch instructions

--! This shadow register is used to pre-fetch instructions for delayed execution. It can hold 
--! 1 instruction for each DPU, switch-box and DiMArch.
ENTITY shadowReg IS
    PORT (
        rst_n : IN STD_LOGIC; --! Reset (active-low)
        clk   : IN STD_LOGIC; --! Clock
        -- Launching signal
        immediate : IN std_logic; --! Signal coming from the sequencer for the immediate launch of the instructions stored in the register
        --<Instruction Inputs>--
        -- DPU
        dpu_cfg           : IN std_logic_vector(DPU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
        dpu_ctrl_out_2    : IN std_logic_vector(DPU_OUTP_A_VECTOR_SIZE - 1 DOWNTO 0);
        dpu_ctrl_out_3    : IN std_logic_vector(DPU_OUTP_B_VECTOR_SIZE - 1 DOWNTO 0);
        dpu_acc_clear_rst : IN std_logic;
        dpu_acc_clear     : IN std_logic_vector(DPU_ACC_CLEAR_WIDTH - 1 DOWNTO 0);
        dpu_sat_ctrl      : IN std_logic_vector(DPU_SAT_CTRL_WIDTH - 1 DOWNTO 0);
        dpu_process_inout : IN std_logic_vector (DPU_PROCESS_INOUT_WIDTH - 1 DOWNTO 0);
        -- Dimarch related
        NOC_BUS_OUT : IN NOC_BUS_TYPE; -- Instruction to the DiMArch
        -- Switchbox
        s_bus_out : IN std_logic_vector(SWB_INSTR_PORT_SIZE - 1 DOWNTO 0);
        --<Instruction Outputs>--
        -- DPU
        dpu_cfg_out           : OUT std_logic_vector(DPU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
        dpu_ctrl_out_2_out    : OUT std_logic_vector(DPU_OUTP_A_VECTOR_SIZE - 1 DOWNTO 0);
        dpu_ctrl_out_3_out    : OUT std_logic_vector(DPU_OUTP_B_VECTOR_SIZE - 1 DOWNTO 0);
        dpu_acc_clear_rst_out : OUT std_logic;
        dpu_acc_clear_out     : OUT std_logic_vector(DPU_ACC_CLEAR_WIDTH - 1 DOWNTO 0);
        dpu_sat_ctrl_out      : OUT std_logic_vector(DPU_SAT_CTRL_WIDTH - 1 DOWNTO 0);
        dpu_process_inout_out : OUT std_logic_vector (DPU_PROCESS_INOUT_WIDTH - 1 DOWNTO 0);
        -- Dimarch related
        NOC_BUS_OUT_out : OUT NOC_BUS_TYPE; -- Instruction to the DiMArch
        -- Switchbox
        s_bus_out_out : OUT std_logic_vector(SWB_INSTR_PORT_SIZE - 1 DOWNTO 0)
    );
END shadowReg;

--! @brief Shadow register architectural design.
--! @details The shadow register is splitted in 2 process. 1) Register the instruction in 
--! the shadow register when a new instruction is generated by the sequencer and also reset the
--! register to 0 when the delayed instruction is issued from inside the register. 2) Selects the
--! instruction output, when the immediate signal is triggered either the instruction stored
--! inside the register or (in the case that the instruction itself triggered the immediate
--! signal) the input instruction itself. 
ARCHITECTURE RTL OF shadowReg IS
    -- DPU
    SIGNAL dpu_cfg_sig           : std_logic_vector(DPU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);
    SIGNAL dpu_ctrl_out_2_sig    : std_logic_vector(DPU_OUTP_A_VECTOR_SIZE - 1 DOWNTO 0);
    SIGNAL dpu_ctrl_out_3_sig    : std_logic_vector(DPU_OUTP_B_VECTOR_SIZE - 1 DOWNTO 0);
    SIGNAL dpu_acc_clear_rst_sig : std_logic;
    SIGNAL dpu_acc_clear_sig     : std_logic_vector(DPU_ACC_CLEAR_WIDTH - 1 DOWNTO 0);
    SIGNAL dpu_sat_ctrl_sig      : std_logic_vector(DPU_SAT_CTRL_WIDTH - 1 DOWNTO 0);
    SIGNAL dpu_process_inout_sig : std_logic_vector (DPU_PROCESS_INOUT_WIDTH - 1 DOWNTO 0);
    -- Dimarch related
    SIGNAL NOC_BUS_OUT_sig : NOC_BUS_TYPE; -- Instruction to the DiMArch
    -- Switchbox
    SIGNAL s_bus_out_sig : std_logic_vector(SWB_INSTR_PORT_SIZE - 1 DOWNTO 0);
BEGIN
    -- Shadow register
    shadow : PROCESS (clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            dpu_cfg_sig           <= (OTHERS => '0');
            dpu_ctrl_out_2_sig    <= (OTHERS => '0');
            dpu_ctrl_out_3_sig    <= (OTHERS => '0');
            dpu_acc_clear_rst_sig <= '0';
            dpu_acc_clear_sig     <= (OTHERS => '0');
            dpu_sat_ctrl_sig      <= (OTHERS => '0');
            dpu_process_inout_sig <= (OTHERS => '0');
            NOC_BUS_OUT_sig       <= IDLE_BUS;
            s_bus_out_sig         <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF immediate = '1' THEN -- If you get an immediate signal 
                dpu_cfg_sig           <= (OTHERS => '0');
                dpu_ctrl_out_2_sig    <= (OTHERS => '0');
                dpu_ctrl_out_3_sig    <= (OTHERS => '0');
                dpu_acc_clear_rst_sig <= '0';
                dpu_acc_clear_sig     <= (OTHERS => '0');
                dpu_sat_ctrl_sig      <= (OTHERS => '0');
                dpu_process_inout_sig <= (OTHERS => '0');
                NOC_BUS_OUT_sig       <= IDLE_BUS;
                s_bus_out_sig         <= (OTHERS => '0');
            ELSE
                IF to_integer(unsigned(dpu_cfg)) /= 0 THEN -- Only register new values to the dpu register if a new instruction in generate
                    dpu_cfg_sig           <= dpu_cfg;
                    dpu_ctrl_out_2_sig    <= dpu_ctrl_out_2;
                    dpu_ctrl_out_3_sig    <= dpu_ctrl_out_3;
                    dpu_acc_clear_rst_sig <= dpu_acc_clear_rst;
                    dpu_acc_clear_sig     <= dpu_acc_clear;
                    dpu_sat_ctrl_sig      <= dpu_sat_ctrl;
                    dpu_process_inout_sig <= dpu_process_inout;
                END IF;
                IF noc_bus_out.bus_enable = '1' THEN -- Only register new values to the DiMARCH register if a new instruction in generate
                    NOC_BUS_OUT_sig <= NOC_BUS_OUT;
                END IF;
                IF s_bus_out(10) = '1' THEN -- Only register new values to the swbox register if a new instruction in generate
                    s_bus_out_sig <= s_bus_out;
                END IF;
            END IF;
        END IF;
    END PROCESS shadow;

    -- Output selection for each of the instructions
    output_select : PROCESS (ALL)
    BEGIN
        dpu_cfg_out           <= (OTHERS => '0');
        dpu_ctrl_out_2_out    <= (OTHERS => '0');
        dpu_ctrl_out_3_out    <= (OTHERS => '0');
        dpu_acc_clear_rst_out <= '0';
        dpu_acc_clear_out     <= (OTHERS => '0');
        dpu_sat_ctrl_out      <= (OTHERS => '0');
        dpu_process_inout_out <= (OTHERS => '0');
        NOC_BUS_OUT_out       <= IDLE_BUS;
        s_bus_out_out         <= (OTHERS => '0');
        IF immediate = '1' THEN                    -- If an immediate instruction output the appropriate instruction
            IF to_integer(unsigned(dpu_cfg)) /= 0 THEN -- If The instruction triggering the immediate is a DPU, by-pass the register
                dpu_cfg_out           <= dpu_cfg;
                dpu_ctrl_out_2_out    <= dpu_ctrl_out_2;
                dpu_ctrl_out_3_out    <= dpu_ctrl_out_3;
                dpu_acc_clear_rst_out <= dpu_acc_clear_rst;
                dpu_acc_clear_out     <= dpu_acc_clear;
                dpu_sat_ctrl_out      <= dpu_sat_ctrl;
                dpu_process_inout_out <= dpu_process_inout;
            ELSE -- Otherwise, send out the registered values
                dpu_cfg_out           <= dpu_cfg_sig;
                dpu_ctrl_out_2_out    <= dpu_ctrl_out_2_sig;
                dpu_ctrl_out_3_out    <= dpu_ctrl_out_3_sig;
                dpu_acc_clear_rst_out <= dpu_acc_clear_rst_sig;
                dpu_acc_clear_out     <= dpu_acc_clear_sig;
                dpu_sat_ctrl_out      <= dpu_sat_ctrl_sig;
                dpu_process_inout_out <= dpu_process_inout_sig;
            END IF;
            IF noc_bus_out.bus_enable = '1' THEN -- If The instruction triggering the immediate is a DiMArch, by-pass the register
                NOC_BUS_OUT_out <= NOC_BUS_OUT;
            ELSE -- Otherwise, send out the registered value
                NOC_BUS_OUT_out <= NOC_BUS_OUT_sig;
            END IF;
            IF s_bus_out(10) = '1' THEN -- If The instruction triggering the immediate is a SW, by-pass the register
                s_bus_out_out <= s_bus_out;
            ELSE -- Otherwise, send out the registered value
                s_bus_out_out <= s_bus_out_sig;
            END IF;
        END IF;
    END PROCESS output_select;
END RTL;