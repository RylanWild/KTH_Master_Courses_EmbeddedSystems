-------------------------------------------------------
--! @file source_decoder_n_fsm.vhd
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
-- File       : source_decoder_n_fsm.vhd
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
USE ieee.numeric_std.ALL;
--use work.top_consts_types_package.SRAM_AGU_INSTR_WIDTH;
USE work.crossbar_types_n_constants.CORSSBAR_INSTRUCTION_RECORD_TYPE;
USE work.crossbar_types_n_constants.IGNORE;

USE work.noc_types_n_constants.ALL;

ENTITY source_decoder_n_fsm IS
    GENERIC (
        POSITION : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00" --! see noc_types_n_constants NORTH SOUTH EAST WEST
    );

    PORT (
        clk : IN STD_LOGIC;
        rst_n : IN STD_LOGIC;
        bus_in : IN NOC_BUS_TYPE;

        This_ROW : IN UNSIGNED (ROW_WIDTH - 1 DOWNTO 0);
        This_COL : IN UNSIGNED (COL_WIDTH - 1 DOWNTO 0);

        -- Input from buses
        north_splitter_direction : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
        east_splitter_direction : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
        south_splitter_direction : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
        west_splitter_direction : IN STD_LOGIC_VECTOR (1 DOWNTO 0);

        reset_fsm : IN STD_LOGIC;

        -- Output to buses
        bus_out : OUT NOC_BUS_TYPE;
        horizontal_sel : OUT STD_LOGIC;
        vertical_sel : OUT STD_LOGIC;
        north_instruction_out : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        south_instruction_out : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        east_instruction_out : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        west_instruction_out : OUT PARTITION_INSTRUCTION_RECORD_TYPE;

        -- AGU
        agu_en_r, agu_en_w : OUT STD_LOGIC;
        SRAM_AGU_instruction_r : OUT sram_agu_instruction_type;
        SRAM_AGU_instruction_w : OUT sram_agu_instruction_type;

        -- Crossbar
        data_direction : OUT CORSSBAR_INSTRUCTION_RECORD_TYPE
    );
END ENTITY source_decoder_n_fsm;

ARCHITECTURE RTL OF source_decoder_n_fsm IS

    SIGNAL RETRANSMIT_FLAG : STD_LOGIC;
    SIGNAL SEGMENT_SRC_FLAG : STD_LOGIC;
    SIGNAL SEGMENT_DST_FLAG : STD_LOGIC;
    SIGNAL flip_transmit : STD_LOGIC;

    SIGNAL bus_int : NOC_BUS_TYPE;

    SIGNAL north_instruction : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL south_instruction : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL east_instruction : PARTITION_INSTRUCTION_RECORD_TYPE;
    SIGNAL west_instruction : PARTITION_INSTRUCTION_RECORD_TYPE;

    SIGNAL saved_data_direction, data_direction_tmp : CORSSBAR_INSTRUCTION_RECORD_TYPE;

BEGIN
    --! Output data direction
    data_direction <= data_direction_tmp;

    --! Trick : trigger the decoder partition reset when we arrive at the end of the partition
    p_partitions_out : PROCESS (SEGMENT_SRC_FLAG, SEGMENT_DST_FLAG, north_instruction, south_instruction, east_instruction, west_instruction, north_splitter_direction, south_splitter_direction, east_splitter_direction, west_splitter_direction)
    BEGIN
        north_instruction_out <= north_instruction;
        south_instruction_out <= south_instruction;
        east_instruction_out <= east_instruction;
        west_instruction_out <= west_instruction;
        IF (SEGMENT_SRC_FLAG OR SEGMENT_DST_FLAG) = '1' THEN
            IF POSITION = "00" THEN
                north_instruction_out <= ('1', north_splitter_direction, '0', '0');
            ELSIF POSITION = "01" THEN
                south_instruction_out <= ('1', south_splitter_direction, '0', '0');
            ELSIF POSITION = "10" THEN
                east_instruction_out <= ('1', east_splitter_direction, '0', '0');
            ELSIF POSITION = "11" THEN
                west_instruction_out <= ('1', west_splitter_direction, '0', '0');
            END IF;
        END IF;
    END PROCESS p_partitions_out;

    u_location_decoder : ENTITY work.source_decoder(RTL)
        GENERIC MAP(
            POSITION => POSITION
        )
        PORT MAP
        (
            This_ROW => STD_LOGIC_VECTOR(This_ROW),
            This_COL => STD_LOGIC_VECTOR(This_COL),
            NOC_BUS_IN => bus_in,
            DIRECTION_OUT => data_direction_tmp,
            RETRANSMIT => RETRANSMIT_FLAG,
            SEGMENT_SRC => SEGMENT_SRC_FLAG,
            SEGMENT_DST => SEGMENT_DST_FLAG,
            flip_transmit => flip_transmit,
            NORTH_instruction => north_instruction,
            SOUTH_instruction => south_instruction,
            EAST_instruction => east_instruction,
            WEST_instruction => west_instruction,
            NOC_BUS_OUT => bus_int
        );

    u_source_fsm : ENTITY work.source_fsm(RTL)
        GENERIC MAP(
            POSITION => POSITION
        )
        PORT MAP(
            rst_n => rst_n,
            clk => clk,
            bus_in => bus_int,
            -- Decoder flags
            RETRANSMIT => RETRANSMIT_FLAG,
            SEGMENT_SRC => SEGMENT_SRC_FLAG,
            SEGMENT_DST => SEGMENT_DST_FLAG,
            flip_transmit => flip_transmit,
            -- Decoded partition instruction
            NORTH_instruction => north_instruction,
            SOUTH_instruction => south_instruction,
            EAST_instruction => east_instruction,
            WEST_instruction => west_instruction,
            -- Input bus splitter directions
            east_splitter_direction => east_splitter_direction,
            west_splitter_direction => west_splitter_direction,
            north_splitter_direction => north_splitter_direction,
            south_splitter_direction => south_splitter_direction,
            -- Close and reset
            reset_fsm => reset_fsm,
            -- Bus outputs
            bus_out => bus_out,
            horizontal_sel => horizontal_sel,
            vertical_sel => vertical_sel,
            -- AGU outputs
            agu_en_r => agu_en_r,
            agu_en_w => agu_en_w,
            SRAM_AGU_instruction_r => SRAM_AGU_instruction_r,
            SRAM_AGU_instruction_w => SRAM_AGU_instruction_w
        );

END ARCHITECTURE RTL;