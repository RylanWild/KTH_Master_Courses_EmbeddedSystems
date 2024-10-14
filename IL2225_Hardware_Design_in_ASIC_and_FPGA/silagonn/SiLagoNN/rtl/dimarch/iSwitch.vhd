-------------------------------------------------------
--! @file iSwitch.vhd
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
-- Title      : UnitX
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : iSwitch.vhd
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
-- 
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

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
USE work.crossbar_types_n_constants.ALL;
USE work.noc_types_n_constants.ALL;

ENTITY iSwitch IS
    PORT (
        rst_n : IN STD_LOGIC;
        clk : IN STD_LOGIC;

        This_ROW : IN UNSIGNED(ROW_WIDTH - 1 DOWNTO 0);
        This_COL : IN UNSIGNED(COL_WIDTH - 1 DOWNTO 0);

        ----------------------------
        --	partition_status 
        ----------------------------
        east_splitter_direction : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        west_splitter_direction : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        north_splitter_direction : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        south_splitter_direction : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        ----------------------------
        --	SEMENTED BUS I/0  
        ----------------------------

        NORTH_BUS_OUT : OUT NOC_BUS_TYPE;
        SOUTH_BUS_OUT : OUT NOC_BUS_TYPE;

        EAST_BUS_OUT : OUT NOC_BUS_TYPE;
        WEST_BUS_OUT : OUT NOC_BUS_TYPE;
        HOR_BUS_LEFT_IN : IN NOC_BUS_TYPE;
        HOR_BUS_RIGHT_IN : IN NOC_BUS_TYPE;

        VER_BUS_TOP_IN : IN NOC_BUS_TYPE;
        VER_BUS_BOTTOM_IN : IN NOC_BUS_TYPE;
        ----------------------------
        --	Partition setup I/0  
        ----------------------------
        top_instruction : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        bottom_instruction : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        left_instruction : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        right_instruction : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        ----------------------------
        --	AGUs and handles input  
        ----------------------------
        SRAM_AGU_instruction_r : OUT sram_agu_instruction_type;
        SRAM_AGU_instruction_w : OUT sram_agu_instruction_type;

        agu_en_r : OUT STD_LOGIC;
        agu_en_w : OUT STD_LOGIC;
        ----------------------------
        --	CROSSBAR DIRECTION  
        ----------------------------
        DIRECTION : OUT CORSSBAR_INSTRUCTION_RECORD_TYPE
    );
END ENTITY iSwitch;

ARCHITECTURE RTL OF iSwitch IS

    ----- Left FSM signals -----------------------
    -- To segmented buses (through selector)
    SIGNAL left_bus_out : NOC_BUS_TYPE;
    SIGNAL left_horizontal_sel : STD_LOGIC;
    SIGNAL left_vertical_sel : STD_LOGIC;
    SIGNAL left_north_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL left_south_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL left_east_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL left_west_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    -- To AGU (through selector)
    SIGNAL left_agu_en_r : STD_LOGIC;
    SIGNAL left_agu_en_w : STD_LOGIC;
    SIGNAL left_SRAM_AGU_instruction_r : sram_agu_instruction_type;
    SIGNAL left_SRAM_AGU_instruction_w : sram_agu_instruction_type;
    -- To crossbar (through selector)
    SIGNAL left_data_direction : CORSSBAR_INSTRUCTION_RECORD_TYPE;

    ----- Right FSM signals -----------------------
    -- To segmented buses (through selector)
    SIGNAL right_bus_out : NOC_BUS_TYPE;
    SIGNAL right_horizontal_sel : STD_LOGIC;
    SIGNAL right_vertical_sel : STD_LOGIC;
    SIGNAL right_north_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL right_south_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL right_east_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL right_west_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    -- To AGU (through selector)
    SIGNAL right_agu_en_r : STD_LOGIC;
    SIGNAL right_agu_en_w : STD_LOGIC;
    SIGNAL right_SRAM_AGU_instruction_r : sram_agu_instruction_type;
    SIGNAL right_SRAM_AGU_instruction_w : sram_agu_instruction_type;
    -- To crossbar (through selector)
    SIGNAL right_data_direction : CORSSBAR_INSTRUCTION_RECORD_TYPE;

    ----- Bottom FSM signals -----------------------
    -- To segmented buses (through selector)
    SIGNAL bottom_bus_out : NOC_BUS_TYPE;
    SIGNAL bottom_horizontal_sel : STD_LOGIC;
    SIGNAL bottom_vertical_sel : STD_LOGIC;
    SIGNAL bottom_north_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL bottom_south_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL bottom_east_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL bottom_west_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    -- To AGU (through selector)
    SIGNAL bottom_agu_en_r : STD_LOGIC;
    SIGNAL bottom_agu_en_w : STD_LOGIC;
    SIGNAL bottom_SRAM_AGU_instruction_r : sram_agu_instruction_type;
    SIGNAL bottom_SRAM_AGU_instruction_w : sram_agu_instruction_type;
    -- To crossbar (through selector)
    SIGNAL bottom_data_direction : CORSSBAR_INSTRUCTION_RECORD_TYPE;

    ----- Top FSM signals -----------------------
    -- To segmented buses (through selector)
    SIGNAL top_bus_out : NOC_BUS_TYPE;
    SIGNAL top_horizontal_sel : STD_LOGIC;
    SIGNAL top_vertical_sel : STD_LOGIC;
    SIGNAL top_north_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL top_south_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL top_east_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL top_west_instruction_out : PARTITION_INSTRUCTION_RECORD_TYPE;
    -- To AGU (through selector)
    SIGNAL top_agu_en_r : STD_LOGIC;
    SIGNAL top_agu_en_w : STD_LOGIC;
    SIGNAL top_SRAM_AGU_instruction_r : sram_agu_instruction_type;
    SIGNAL top_SRAM_AGU_instruction_w : sram_agu_instruction_type;
    -- To crossbar (through selector)
    SIGNAL top_data_direction : CORSSBAR_INSTRUCTION_RECORD_TYPE;
    -- From selector to FSM
    SIGNAL top_reset_fsm     :  STD_LOGIC;
    SIGNAL bottom_reset_fsm  :  STD_LOGIC;
    SIGNAL left_reset_fsm    :  STD_LOGIC;
    SIGNAL right_reset_fsm   :  STD_LOGIC;

BEGIN

    p_direction : PROCESS (bottom_data_direction, top_data_direction, right_data_direction, left_data_direction) IS
    BEGIN
        IF bottom_data_direction.ENABLE = '1' THEN
            DIRECTION <= bottom_data_direction;
        ELSIF top_data_direction.ENABLE = '1' THEN
            DIRECTION <= top_data_direction;
        ELSIF right_data_direction.ENABLE = '1' THEN
            DIRECTION <= right_data_direction;
        ELSIF left_data_direction.ENABLE = '1' THEN
            DIRECTION <= left_data_direction;
        ELSE
            DIRECTION <= IGNORE;
        END IF;
    END PROCESS p_direction;

    ----- Left FSM -----------------------
    u_left_source_decoder_n_fsm : ENTITY work.source_decoder_n_fsm
        GENERIC MAP(
            POSITION => WEST
        )
        PORT MAP
        (
            clk => clk,
            rst_n => rst_n,
            This_ROW => This_ROW,
            This_COL => This_COL,
            -- Bus in
            bus_in => HOR_BUS_LEFT_IN,
            -- From segmented buses
            east_splitter_direction => east_splitter_direction,
            west_splitter_direction => west_splitter_direction,
            north_splitter_direction => north_splitter_direction,
            south_splitter_direction => south_splitter_direction,
            reset_fsm => left_reset_fsm,
            -- To segmented buses (through selector)
            bus_out => left_bus_out,
            horizontal_sel => left_horizontal_sel,
            vertical_sel => left_vertical_sel,
            north_instruction_out => left_north_instruction_out,
            south_instruction_out => left_south_instruction_out,
            east_instruction_out => left_east_instruction_out,
            west_instruction_out => left_west_instruction_out,
            -- To AGU (through selector)
            agu_en_r => left_agu_en_r,
            agu_en_w => left_agu_en_w,
            SRAM_AGU_instruction_r => left_SRAM_AGU_instruction_r,
            SRAM_AGU_instruction_w => left_SRAM_AGU_instruction_w,
            -- To crossbar (through selector)
            data_direction => left_data_direction
        );

    ----- Right FSM -----------------------
    u_right_source_decoder_n_fsm : ENTITY work.source_decoder_n_fsm
        GENERIC MAP(
            POSITION => EAST
        )
        PORT MAP
        (
            clk => clk,
            rst_n => rst_n,
            This_ROW => This_ROW,
            This_COL => This_COL,
            -- Bus in
            bus_in => HOR_BUS_RIGHT_IN,
            -- From segmented buses
            east_splitter_direction => east_splitter_direction,
            west_splitter_direction => west_splitter_direction,
            north_splitter_direction => north_splitter_direction,
            south_splitter_direction => south_splitter_direction,
            reset_fsm => right_reset_fsm,
            -- To segmented buses (through selector)
            bus_out => right_bus_out,
            horizontal_sel => right_horizontal_sel,
            vertical_sel => right_vertical_sel,
            north_instruction_out => right_north_instruction_out,
            south_instruction_out => right_south_instruction_out,
            east_instruction_out => right_east_instruction_out,
            west_instruction_out => right_west_instruction_out,
            -- To AGU (through selector)
            agu_en_r => right_agu_en_r,
            agu_en_w => right_agu_en_w,
            SRAM_AGU_instruction_r => right_SRAM_AGU_instruction_r,
            SRAM_AGU_instruction_w => right_SRAM_AGU_instruction_w,
            -- To crossbar (through selector)
            data_direction => right_data_direction
        );

    ----- Top FSM -----------------------
    u_top_source_decoder_n_fsm : ENTITY work.source_decoder_n_fsm
        GENERIC MAP(
            POSITION => NORTH
        )
        PORT MAP
        (
            clk => clk,
            rst_n => rst_n,
            This_ROW => This_ROW,
            This_COL => This_COL,
            -- Bus in
            bus_in => VER_BUS_TOP_IN,
            -- From segmented buses
            east_splitter_direction => east_splitter_direction,
            west_splitter_direction => west_splitter_direction,
            north_splitter_direction => north_splitter_direction,
            south_splitter_direction => south_splitter_direction,
            reset_fsm => top_reset_fsm,
            -- To segmented buses (through selector)
            bus_out => top_bus_out,
            horizontal_sel => top_horizontal_sel,
            vertical_sel => top_vertical_sel,
            north_instruction_out => top_north_instruction_out,
            south_instruction_out => top_south_instruction_out,
            east_instruction_out => top_east_instruction_out,
            west_instruction_out => top_west_instruction_out,
            -- To AGU (through selector)
            agu_en_r => top_agu_en_r,
            agu_en_w => top_agu_en_w,
            SRAM_AGU_instruction_r => top_SRAM_AGU_instruction_r,
            SRAM_AGU_instruction_w => top_SRAM_AGU_instruction_w,
            -- To crossbar (through selector)
            data_direction => top_data_direction
        );

    ----- Bottom FSM -----------------------
    u_bottom_source_decoder_n_fsm : ENTITY work.source_decoder_n_fsm
        GENERIC MAP(
            POSITION => SOUTH
        )
        PORT MAP
        (
            clk => clk,
            rst_n => rst_n,
            This_ROW => This_ROW,
            This_COL => This_COL,
            -- Bus in
            bus_in => VER_BUS_BOTTOM_IN,
            -- From segmented buses
            east_splitter_direction => east_splitter_direction,
            west_splitter_direction => west_splitter_direction,
            north_splitter_direction => north_splitter_direction,
            south_splitter_direction => south_splitter_direction,
            reset_fsm => bottom_reset_fsm,
            -- To segmented buses (through selector)
            bus_out => bottom_bus_out,
            horizontal_sel => bottom_horizontal_sel,
            vertical_sel => bottom_vertical_sel,
            north_instruction_out => bottom_north_instruction_out,
            south_instruction_out => bottom_south_instruction_out,
            east_instruction_out => bottom_east_instruction_out,
            west_instruction_out => bottom_west_instruction_out,
            -- To AGU (through selector)
            agu_en_r => bottom_agu_en_r,
            agu_en_w => bottom_agu_en_w,
            SRAM_AGU_instruction_r => bottom_SRAM_AGU_instruction_r,
            SRAM_AGU_instruction_w => bottom_SRAM_AGU_instruction_w,
            -- To crossbar (through selector)
            data_direction => bottom_data_direction
        );

    ----- Selector -----------------------
    u_selector : ENTITY work.selector
        PORT MAP(
            top_agu_en_r => top_agu_en_r,
            top_agu_en_w => top_agu_en_w,
            top_SRAM_AGU_instruction_r => top_SRAM_AGU_instruction_r,
            top_SRAM_AGU_instruction_w => top_SRAM_AGU_instruction_w,
            bottom_agu_en_r => bottom_agu_en_r,
            bottom_agu_en_w => bottom_agu_en_w,
            bottom_SRAM_AGU_instruction_r => bottom_SRAM_AGU_instruction_r,
            bottom_SRAM_AGU_instruction_w => bottom_SRAM_AGU_instruction_w,
            left_agu_en_r => left_agu_en_r,
            left_agu_en_w => left_agu_en_w,
            left_SRAM_AGU_instruction_r => left_SRAM_AGU_instruction_r,
            left_SRAM_AGU_instruction_w => left_SRAM_AGU_instruction_w,
            right_agu_en_r => right_agu_en_r,
            right_agu_en_w => right_agu_en_w,
            right_SRAM_AGU_instruction_r => right_SRAM_AGU_instruction_r,
            right_SRAM_AGU_instruction_w => right_SRAM_AGU_instruction_w,

            top_horizontal_sel => top_horizontal_sel,
            top_vertical_sel => top_vertical_sel,
            bottom_horizontal_sel => bottom_horizontal_sel,
            bottom_vertical_sel => bottom_vertical_sel,
            left_horizontal_sel => left_horizontal_sel,
            left_vertical_sel => left_vertical_sel,
            right_horizontal_sel => right_horizontal_sel,
            right_vertical_sel => right_vertical_sel,

            top_north_instruction_out => top_north_instruction_out,
            top_south_instruction_out => top_south_instruction_out,
            top_east_instruction_out => top_east_instruction_out,
            top_west_instruction_out => top_west_instruction_out,

            bottom_north_instruction_out => bottom_north_instruction_out,
            bottom_south_instruction_out => bottom_south_instruction_out,
            bottom_east_instruction_out => bottom_east_instruction_out,
            bottom_west_instruction_out => bottom_west_instruction_out,
            left_north_instruction_out => left_north_instruction_out,
            left_south_instruction_out => left_south_instruction_out,
            left_east_instruction_out => left_east_instruction_out,
            left_west_instruction_out => left_west_instruction_out,
            right_north_instruction_out => right_north_instruction_out,
            right_south_instruction_out => right_south_instruction_out,
            right_east_instruction_out => right_east_instruction_out,
            right_west_instruction_out => right_west_instruction_out,

            top_bus_out => top_bus_out,
            bottom_bus_out => bottom_bus_out,
            left_bus_out => left_bus_out,
            right_bus_out => right_bus_out,

            north_bus_out => NORTH_BUS_OUT,
            south_bus_out => SOUTH_BUS_OUT,
            east_bus_out => EAST_BUS_OUT,
            west_bus_out => WEST_BUS_OUT,

            top_instruction => top_instruction,
            bottom_instruction => bottom_instruction,
            left_instruction => left_instruction,
            right_instruction => right_instruction,

            top_reset_fsm => top_reset_fsm,
            bottom_reset_fsm => bottom_reset_fsm,
            left_reset_fsm => left_reset_fsm,
            right_reset_fsm => right_reset_fsm,

            SRAM_AGU_instruction_r => SRAM_AGU_instruction_r,
            SRAM_AGU_instruction_w => SRAM_AGU_instruction_w,
            agu_en_r => agu_en_r,
            agu_en_w => agu_en_w
        );

END ARCHITECTURE RTL;