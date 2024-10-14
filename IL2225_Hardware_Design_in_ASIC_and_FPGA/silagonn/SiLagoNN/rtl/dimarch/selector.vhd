-------------------------------------------------------
--! @file selector.vhd
--! @brief 
--! @details 
--! @author Muhammad Adeel Tajammul
--! @version 1.0
--! @date 
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
-- Title      : 
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : selector.vhd
-- Author     : Muhammad Adeel Tajammul
-- Company    : KTH
-- Created    : 
-- Last update: 
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2014
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
--             1.0      Muhammad Adeel Tajammul      Created
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
USE ieee.NUMERIC_STD.ALL;
USE work.noc_types_n_constants.ALL;

-----------------------------------------------------------
-- this code should be split based on outputs so that during layout relevant outputs 
-- can be placed closed the their edges . -- Adeel 

ENTITY selector IS
    PORT
    (
        top_agu_en_r, top_agu_en_w       : IN std_logic;
        top_SRAM_AGU_instruction_r       : IN sram_agu_instruction_type;
        top_SRAM_AGU_instruction_w       : IN sram_agu_instruction_type;
        bottom_agu_en_r, bottom_agu_en_w : IN std_logic;
        bottom_SRAM_AGU_instruction_r    : IN sram_agu_instruction_type;
        bottom_SRAM_AGU_instruction_w    : IN sram_agu_instruction_type;
        left_agu_en_r, left_agu_en_w     : IN std_logic;
        left_SRAM_AGU_instruction_r      : IN sram_agu_instruction_type;
        left_SRAM_AGU_instruction_w      : IN sram_agu_instruction_type;
        right_agu_en_r, right_agu_en_w   : IN std_logic;
        right_SRAM_AGU_instruction_r     : IN sram_agu_instruction_type;
        right_SRAM_AGU_instruction_w     : IN sram_agu_instruction_type;

        top_north_instruction_out, top_south_instruction_out, top_east_instruction_out, top_west_instruction_out             : IN PARTITION_INSTRUCTION_RECORD_TYPE;
        bottom_north_instruction_out, bottom_south_instruction_out, bottom_east_instruction_out, bottom_west_instruction_out : IN PARTITION_INSTRUCTION_RECORD_TYPE;
        left_north_instruction_out, left_south_instruction_out, left_east_instruction_out, left_west_instruction_out         : IN PARTITION_INSTRUCTION_RECORD_TYPE;
        right_north_instruction_out, right_south_instruction_out, right_east_instruction_out, right_west_instruction_out     : IN PARTITION_INSTRUCTION_RECORD_TYPE;
        --------------------------------------------------------
        --	source decoder n fsm suggested bus out values
        --------------------------------------------------------
        top_bus_out    : IN NOC_BUS_TYPE;
        bottom_bus_out : IN NOC_BUS_TYPE;
        left_bus_out   : IN NOC_BUS_TYPE;
        right_bus_out  : IN NOC_BUS_TYPE;
        ----
        --
        ----
        top_horizontal_sel    : IN STD_LOGIC;
        top_vertical_sel      : IN STD_LOGIC;
        bottom_horizontal_sel : IN STD_LOGIC;
        bottom_vertical_sel   : IN STD_LOGIC;
        left_horizontal_sel   : IN STD_LOGIC;
        left_vertical_sel     : IN STD_LOGIC;
        right_horizontal_sel  : IN STD_LOGIC;
        right_vertical_sel    : IN STD_LOGIC;
        ----------------------------
        --	iNoC segmented bus output  
        ----------------------------
        north_bus_out : OUT NOC_BUS_TYPE;
        south_bus_out : OUT NOC_BUS_TYPE;
        east_bus_out  : OUT NOC_BUS_TYPE;
        west_bus_out  : OUT NOC_BUS_TYPE;
        ----------------------------
        --	Partition setup I/0  
        ----------------------------
        top_instruction    : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        bottom_instruction : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        left_instruction   : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        right_instruction  : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        top_reset_fsm          : OUT STD_LOGIC;
        bottom_reset_fsm       : OUT STD_LOGIC;
        left_reset_fsm         : OUT STD_LOGIC;
        right_reset_fsm        : OUT STD_LOGIC;
        ----------------------------
        --	AGUs and handles input  
        ----------------------------
        SRAM_AGU_instruction_r : OUT sram_agu_instruction_type;
        SRAM_AGU_instruction_w : OUT sram_agu_instruction_type;
        agu_en_r               : OUT std_logic;
        agu_en_w               : OUT std_logic
    );
END ENTITY selector;

ARCHITECTURE RTL OF selector IS
    SIGNAL top_receive : STD_LOGIC;
    SIGNAL bottom_receive : STD_LOGIC;
    SIGNAL left_receive : STD_LOGIC;
    SIGNAL right_receive : STD_LOGIC;
    SIGNAL receive : STD_LOGIC;
    SIGNAL top_instruction_tmp    : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL bottom_instruction_tmp : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL left_instruction_tmp   : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL right_instruction_tmp  : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL top_reset_fsm_tmp          : STD_LOGIC;
    SIGNAL bottom_reset_fsm_tmp       : STD_LOGIC;
    SIGNAL left_reset_fsm_tmp         : STD_LOGIC;
    SIGNAL right_reset_fsm_tmp        : STD_LOGIC;
BEGIN
    p_help_signals : PROCESS(top_north_instruction_out, top_south_instruction_out, top_east_instruction_out, top_west_instruction_out, bottom_north_instruction_out, bottom_south_instruction_out, bottom_east_instruction_out, bottom_west_instruction_out,left_north_instruction_out, left_south_instruction_out, left_east_instruction_out, left_west_instruction_out,right_north_instruction_out, right_south_instruction_out, right_east_instruction_out, right_west_instruction_out)
    BEGIN
        top_receive <= top_north_instruction_out.ENABLE OR top_south_instruction_out.ENABLE OR top_east_instruction_out.ENABLE OR top_west_instruction_out.ENABLE;
        bottom_receive <= bottom_north_instruction_out.ENABLE OR bottom_south_instruction_out.ENABLE OR bottom_east_instruction_out.ENABLE OR bottom_west_instruction_out.ENABLE;
        left_receive <= left_north_instruction_out.ENABLE OR left_south_instruction_out.ENABLE OR left_east_instruction_out.ENABLE OR left_west_instruction_out.ENABLE;
        right_receive <= right_north_instruction_out.ENABLE OR right_south_instruction_out.ENABLE OR right_east_instruction_out.ENABLE OR right_west_instruction_out.ENABLE;
    END PROCESS p_help_signals;

    receive <= top_receive OR bottom_receive OR left_receive OR right_receive;

    p_reset_fsm_logic : PROCESS(top_instruction_tmp, bottom_instruction_tmp, left_instruction_tmp, right_instruction_tmp, top_receive, bottom_receive, left_receive, right_receive, receive)
    BEGIN
        top_reset_fsm_tmp <= (receive) AND (NOT top_receive);
        bottom_reset_fsm_tmp <= (receive) AND (NOT bottom_receive);
        left_reset_fsm_tmp <= (receive) AND (NOT left_receive);
        right_reset_fsm_tmp <= (receive) AND (NOT right_receive);
    END PROCESS P_reset_fsm_logic;

    top_reset_fsm <= top_reset_fsm_tmp;
    bottom_reset_fsm <= bottom_reset_fsm_tmp;
    left_reset_fsm <= left_reset_fsm_tmp;
    right_reset_fsm <= right_reset_fsm_tmp;

    p_output_instruction_top : PROCESS(top_instruction_tmp, top_reset_fsm_tmp)
    BEGIN
	IF ((top_reset_fsm_tmp = '1') AND (top_instruction_tmp.ENABLE = '0')) THEN
        	top_instruction <= LOW_RESET_PAR_INST;
	ELSE 
		top_instruction <= top_instruction_tmp;
	END IF;
    END PROCESS p_output_instruction_top;

    p_output_instruction_bottom : PROCESS(bottom_instruction_tmp, bottom_reset_fsm_tmp)
    BEGIN
	IF ((bottom_reset_fsm_tmp = '1') AND (bottom_instruction_tmp.ENABLE = '0')) THEN
        	bottom_instruction <= LOW_RESET_PAR_INST;
	ELSE 
		bottom_instruction <= bottom_instruction_tmp;
	END IF;
    END PROCESS p_output_instruction_bottom;

    p_output_instruction_left : PROCESS(left_instruction_tmp, left_reset_fsm_tmp)
    BEGIN
	IF ((left_reset_fsm_tmp = '1') AND (left_instruction_tmp.ENABLE = '0')) THEN
        	left_instruction <= LOW_RESET_PAR_INST;
	ELSE 
		left_instruction <= left_instruction_tmp;
	END IF;
    END PROCESS p_output_instruction_left;
    
    p_output_instruction_right : PROCESS(right_instruction_tmp, right_reset_fsm_tmp)
    BEGIN
	IF ((right_reset_fsm_tmp = '1') AND (right_instruction_tmp.ENABLE = '0')) THEN
        	right_instruction <= LOW_RESET_PAR_INST;
	ELSE 
		right_instruction <= right_instruction_tmp;
	END IF;
    END PROCESS p_output_instruction_right;
    -- why does this process produce multiple drivers i.e. X when all output is changed to 1
    p_top_instruction : PROCESS (top_north_instruction_out, bottom_north_instruction_out, left_north_instruction_out, right_north_instruction_out) IS
    BEGIN
        IF top_north_instruction_out.ENABLE = '1' THEN
            top_instruction_tmp <= top_north_instruction_out;
        ELSIF left_north_instruction_out.ENABLE = '1' THEN
            top_instruction_tmp <= left_north_instruction_out;
        ELSIF right_north_instruction_out.ENABLE = '1' THEN
            top_instruction_tmp <= right_north_instruction_out;
        ELSIF bottom_north_instruction_out.ENABLE = '1' THEN
            top_instruction_tmp <= bottom_north_instruction_out;
        ELSE
            top_instruction_tmp <= IDLE_PAR_INST;
        END IF;
    END PROCESS p_top_instruction;

    p_bottom_instruction : PROCESS (top_south_instruction_out, bottom_south_instruction_out, left_south_instruction_out, right_south_instruction_out) IS
    BEGIN
        IF top_south_instruction_out.ENABLE = '1' THEN
            bottom_instruction_tmp <= top_south_instruction_out;
        ELSIF left_south_instruction_out.ENABLE = '1' THEN
            bottom_instruction_tmp <= left_south_instruction_out;
        ELSIF right_south_instruction_out.ENABLE = '1' THEN
            bottom_instruction_tmp <= right_south_instruction_out;
        ELSIF bottom_south_instruction_out.ENABLE = '1' THEN
            bottom_instruction_tmp <= bottom_south_instruction_out;
        ELSE
            bottom_instruction_tmp <= IDLE_PAR_INST;
        END IF;
    END PROCESS p_bottom_instruction;

    p_left_instruction : PROCESS (top_west_instruction_out, bottom_west_instruction_out, left_west_instruction_out, right_west_instruction_out) IS
    BEGIN
        IF top_west_instruction_out.ENABLE = '1' THEN
            left_instruction_tmp <= top_west_instruction_out;
        ELSIF left_west_instruction_out.ENABLE = '1' THEN
            left_instruction_tmp <= left_west_instruction_out;
        ELSIF right_west_instruction_out.ENABLE = '1' THEN
            left_instruction_tmp <= right_west_instruction_out;
        ELSIF bottom_west_instruction_out.ENABLE = '1' THEN
            left_instruction_tmp <= bottom_west_instruction_out;
        ELSE
            left_instruction_tmp <= IDLE_PAR_INST;
        END IF;
    END PROCESS p_left_instruction;

    p_right_instruction : PROCESS (top_east_instruction_out, bottom_east_instruction_out, left_east_instruction_out, right_east_instruction_out) IS
    BEGIN
        IF top_east_instruction_out.ENABLE = '1' THEN
            right_instruction_tmp <= top_east_instruction_out;
        ELSIF left_east_instruction_out.ENABLE = '1' THEN
            right_instruction_tmp <= left_east_instruction_out;
        ELSIF right_east_instruction_out.ENABLE = '1' THEN
            right_instruction_tmp <= right_east_instruction_out;
        ELSIF bottom_east_instruction_out.ENABLE = '1' THEN
            right_instruction_tmp <= bottom_east_instruction_out;
        ELSE
            right_instruction_tmp <= IDLE_PAR_INST;
        END IF;
    END PROCESS p_right_instruction;

    p_agu_r : PROCESS (top_agu_en_r, bottom_agu_en_r, left_agu_en_r, right_agu_en_r, top_SRAM_AGU_instruction_r, bottom_SRAM_AGU_instruction_r, left_SRAM_AGU_instruction_r, right_SRAM_AGU_instruction_r) IS
    BEGIN
        IF bottom_agu_en_r = '1' THEN
            SRAM_AGU_instruction_r <= bottom_SRAM_AGU_instruction_r;
            agu_en_r               <= bottom_agu_en_r;
        ELSIF left_agu_en_r = '1' THEN
            SRAM_AGU_instruction_r <= left_SRAM_AGU_instruction_r;
            agu_en_r               <= left_agu_en_r;
        ELSIF right_agu_en_r = '1' THEN
            SRAM_AGU_instruction_r <= right_SRAM_AGU_instruction_r;
            agu_en_r               <= right_agu_en_r;
        ELSIF top_agu_en_r = '1' THEN
            SRAM_AGU_instruction_r <= top_SRAM_AGU_instruction_r;
            agu_en_r               <= top_agu_en_r;
        ELSE
            SRAM_AGU_instruction_r <= sram_instr_zero;--(others => '0');
            agu_en_r               <= '0';
        END IF;

    END PROCESS p_agu_r;
    p_agu_w : PROCESS (top_agu_en_w, bottom_agu_en_w, left_agu_en_w, right_agu_en_w, top_SRAM_AGU_instruction_w, bottom_SRAM_AGU_instruction_w, left_SRAM_AGU_instruction_w, right_SRAM_AGU_instruction_w) IS
    BEGIN
        IF bottom_agu_en_w = '1' THEN
            SRAM_AGU_instruction_w <= bottom_SRAM_AGU_instruction_w;
            agu_en_w               <= bottom_agu_en_w;
        ELSIF left_agu_en_w = '1' THEN
            SRAM_AGU_instruction_w <= left_SRAM_AGU_instruction_w;
            agu_en_w               <= left_agu_en_w;
        ELSIF right_agu_en_w = '1' THEN
            SRAM_AGU_instruction_w <= right_SRAM_AGU_instruction_w;
            agu_en_w               <= right_agu_en_w;
        ELSIF top_agu_en_w = '1' THEN
            SRAM_AGU_instruction_w <= top_SRAM_AGU_instruction_w;
            agu_en_w               <= top_agu_en_w;
        ELSE
            SRAM_AGU_instruction_w <= sram_instr_zero;--(others => '0');
            agu_en_w               <= '0';
        END IF;

    END PROCESS p_agu_w;

    p_north_bus_out : PROCESS (top_bus_out, bottom_bus_out, left_bus_out, right_bus_out, top_vertical_sel, bottom_vertical_sel, left_vertical_sel, right_vertical_sel) IS
    BEGIN
        IF left_vertical_sel = '1' THEN
            north_bus_out <= left_bus_out;
        ELSIF right_vertical_sel = '1' THEN
            north_bus_out <= right_bus_out;
        ELSIF bottom_vertical_sel = '1' THEN
            north_bus_out <= bottom_bus_out;
        ELSIF top_vertical_sel = '1' THEN
            north_bus_out <= top_bus_out;
        ELSE
            north_bus_out <= IDLE_BUS;
        END IF;
    END PROCESS p_north_bus_out;

    p_south_bus_out : PROCESS (top_bus_out, bottom_bus_out, left_bus_out, right_bus_out, top_vertical_sel, bottom_vertical_sel, left_vertical_sel, right_vertical_sel) IS
    BEGIN
        IF left_vertical_sel = '1' THEN
            south_bus_out <= left_bus_out;
        ELSIF right_vertical_sel = '1' THEN
            south_bus_out <= right_bus_out;
        ELSIF bottom_vertical_sel = '1' THEN
            south_bus_out <= bottom_bus_out;
        ELSIF top_vertical_sel = '1' THEN
            south_bus_out <= top_bus_out;
        ELSE
            south_bus_out <= IDLE_BUS;
        END IF;
    END PROCESS p_south_bus_out;

    p_east_bus_out : PROCESS (top_bus_out, bottom_bus_out, left_bus_out, right_bus_out, top_horizontal_sel, bottom_horizontal_sel, left_horizontal_sel, right_horizontal_sel) IS
    BEGIN
        IF left_horizontal_sel = '1' THEN
            east_bus_out <= left_bus_out;
        ELSIF right_horizontal_sel = '1' THEN
            east_bus_out <= right_bus_out;
        ELSIF bottom_horizontal_sel = '1' THEN 
            east_bus_out <= bottom_bus_out;
        ELSIF top_horizontal_sel = '1' THEN
            east_bus_out <= top_bus_out;
        ELSE
            east_bus_out <= IDLE_BUS;
        END IF;
    END PROCESS p_east_bus_out;

    p_west_bus_out : PROCESS (top_bus_out, bottom_bus_out, left_bus_out, right_bus_out, top_horizontal_sel, bottom_horizontal_sel, left_horizontal_sel, right_horizontal_sel) IS
    BEGIN
        IF left_horizontal_sel = '1' THEN
            west_bus_out <= left_bus_out;
        ELSIF right_horizontal_sel = '1' THEN
            west_bus_out <= right_bus_out;
        ELSIF bottom_horizontal_sel = '1' THEN
            west_bus_out <= bottom_bus_out;
        ELSIF top_horizontal_sel = '1' THEN
            west_bus_out <= top_bus_out;
        ELSE
            west_bus_out <= IDLE_BUS;
        END IF;
    END PROCESS p_west_bus_out;

END ARCHITECTURE RTL;
