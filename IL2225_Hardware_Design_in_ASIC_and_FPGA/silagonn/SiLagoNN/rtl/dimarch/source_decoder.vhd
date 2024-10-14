-------------------------------------------------------
--! @file source_decoder.vhd
--! @brief 
--! @details 
--! @author Muhammad Adeel Tajammul
--! @version 2.0
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
-- File       : source_decoder.vhd
-- Author     : Muhammad Adeel Tajammul
-- Company    : KTH
-- Created    : 
-- Last update: 2022-05-19
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
-- 15.06.2016  2.0      Arun Jayabalan               Rewritten the code to remove redundant logic
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

--------------------------------------------------------------------------------
-- This is a SRAM Tile which will be used to extend DRRA Fabric for memory communication
-- be changed by changing the generics
---------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
USE work.crossbar_types_n_constants.ALL;
USE ieee.numeric_std.ALL;
use ieee.std_logic_misc.all; -- needed for or_reduce
--use work.drra_types_n_constants.all;
USE work.noc_types_n_constants.ALL;

ENTITY source_decoder IS
    GENERIC (
        POSITION : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00" --! see noc_types_n_constants NORTH SOUTH EAST WEST
    );
    PORT (
        -- 		rst_n             : in	std_logic;
        -- 		clk               : in	std_logic;
        This_ROW : IN STD_LOGIC_VECTOR(ROW_WIDTH - 1 DOWNTO 0);
        This_COL : IN STD_LOGIC_VECTOR(COL_WIDTH - 1 DOWNTO 0);
        NOC_BUS_IN : IN NOC_BUS_TYPE;
        DIRECTION_OUT : OUT CORSSBAR_INSTRUCTION_RECORD_TYPE;
        RETRANSMIT : OUT STD_LOGIC;
        SEGMENT_SRC : OUT STD_LOGIC;
        SEGMENT_DST : OUT STD_LOGIC;
        flip_transmit : OUT STD_LOGIC;
        --		rw                : OUT STD_LOGIC;
        NORTH_instruction : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        SOUTH_instruction : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        EAST_instruction : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        WEST_instruction : OUT PARTITION_INSTRUCTION_RECORD_TYPE;
        NOC_BUS_OUT : OUT NOC_BUS_TYPE
    );
END ENTITY source_decoder;

ARCHITECTURE RTL OF source_decoder IS
    SIGNAL RETRANSMIT_FLAG : STD_LOGIC;
    SIGNAL SEGMENT_SRC_FLAG : STD_LOGIC;
    SIGNAL SEGMENT_DST_FLAG : STD_LOGIC;
    --SIGNAL		flip_transmit_FLAG : 	STD_LOGIC;		

    ALIAS i_BUS_ENABLE : STD_LOGIC IS NOC_BUS_IN.bus_enable;
    ALIAS i_instr_code : STD_LOGIC_VECTOR(INS_WIDTH - 1 DOWNTO 0) IS NOC_BUS_IN.instr_code;

    -- PATH SETUP FLAGS

    --
    ALIAS i_intermediate_node_flag : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(INTERMEDIATE_NODE_FLAG_l); -- IF 1 THEN INTERMEDIATE node instruction 
    ALIAS i_intermediate_segment_flag : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(INTERMEDIATE_SEGMENT_FLAG_l); -- IF 1 THEN INTERMEDIATE segment source to intermediate 
    -- ADDRESSES 
    ALIAS i_SRH_dir : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(SRH_dir_l); -- SOURCE ROW DIR
    ALIAS i_SRH : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS NOC_BUS_IN.INSTRUCTION(SRH_e DOWNTO SRH_s); -- SOURCE ROW
    ALIAS i_SCH_dir : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(SCH_dir_l); -- SOURCE COLUMN DIR
    ALIAS i_SCH : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS NOC_BUS_IN.INSTRUCTION(SCH_e DOWNTO SCH_s); -- SOURCE COLUMN
    ALIAS i_DRH_dir : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(DRH_dir_l); -- DESTINATION ROW DIR
    ALIAS i_DRH : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS NOC_BUS_IN.INSTRUCTION(DRH_e DOWNTO DRH_s); -- DESTINATION ROW
    ALIAS i_DCH_dir : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(DCH_dir_l); -- DESTINATION COLUMN DIR
    ALIAS i_DCH : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS NOC_BUS_IN.INSTRUCTION(DCH_e DOWNTO DCH_s); -- DESTINATION COLUMN
    ALIAS i_IRH_dir : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(IRH_dir_l); -- INTERMEDIATE ROW DIR
    ALIAS i_IRH : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS NOC_BUS_IN.INSTRUCTION(IRH_e DOWNTO IRH_s); -- INTERMEDIATE ROW
    ALIAS i_ICH_dir : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(ICH_dir_l); -- INTERMEDIATE COLUMN DIR
    ALIAS i_ICH : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS NOC_BUS_IN.INSTRUCTION(ICH_e DOWNTO ICH_s); -- INTERMEDIATE COLUMN 
    ----
    ALIAS i_SRH_dir_out : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(SRH_dir_l); -- SOURCE ROW DIR
    ALIAS i_SRH_out : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS NOC_BUS_OUT.INSTRUCTION(SRH_e DOWNTO SRH_s); -- SOURCE ROW
    ALIAS i_SCH_dir_out : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(SCH_dir_l); -- SOURCE COLUMN DIR
    ALIAS i_SCH_out : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS NOC_BUS_OUT.INSTRUCTION(SCH_e DOWNTO SCH_s); -- SOURCE COLUMN
    ALIAS i_DRH_dir_out : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(DRH_dir_l); -- DESTINATION ROW DIR
    ALIAS i_DRH_out : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS NOC_BUS_OUT.INSTRUCTION(DRH_e DOWNTO DRH_s); -- DESTINATION ROW
    ALIAS i_DCH_dir_out : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(DCH_dir_l); -- DESTINATION COLUMN DIR
    ALIAS i_DCH_out : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS NOC_BUS_OUT.INSTRUCTION(DCH_e DOWNTO DCH_s); -- DESTINATION COLUMN
    --alias   i_PR    : STD_LOGIC 						IS NOC_BUS_IN.INSTRUCTION(PR_l);				-- PRIORITY
    ALIAS I_ON : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(ON_l); -- ORIGIN NODE -> 1=DESTINATION () 0 if source is origin 1 if destination is origin  )
    ALIAS i_union : STD_LOGIC IS NOC_BUS_IN.INSTRUCTION(UNION_FLAG_l);
    SIGNAL DIRECTION : CORSSBAR_INSTRUCTION_RECORD_TYPE;

    SIGNAL --sr_dr,		sc_dc,
    mr_sr, mc_sc, mr_dr, mc_dc, mr_sr_eq, mc_sc_eq, mr_dr_eq, mc_dc_eq : STD_LOGIC;

    SIGNAL my_src_row_diff, my_des_row_diff : SIGNED(ROW_WIDTH DOWNTO 0);
    SIGNAL my_src_col_diff, my_des_col_diff : SIGNED(COL_WIDTH DOWNTO 0);

    SIGNAL src_locate : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL dst_locate : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL this_position : STD_LOGIC_VECTOR(crossbar_select_width - 1 DOWNTO 0);

BEGIN

    mr_sr_eq <= '1' WHEN or_reduce(i_SRH) = '0' ELSE
        '0';
    mr_dr_eq <= '1' WHEN or_reduce(i_DRH) = '0' ELSE
        '0';
    mc_sc_eq <= '1' WHEN or_reduce(i_SCH) = '0' ELSE
        '0';
    mc_dc_eq <= '1' WHEN or_reduce(i_DCH) = '0' ELSE
        '0';

    RETRANSMIT <= 'X';
    flip_transmit <= 'X';

    mr_sr <= i_SRH_dir; -- if 1 then this mr < sr
    mr_dr <= i_DRH_dir; -- if 1 then this mr < dr

    mc_sc <= i_SCH_dir; -- if 1 then this mc < sc
    mc_dc <= i_DCH_dir; -- if 1 then this mc < dr

    this_position(1 DOWNTO 0) <= POSITION; -- Resize this position (N/S/E/W) to be a crossbar direction
    this_position(crossbar_select_width - 1 DOWNTO 2) <= (OTHERS => '0');

    PROCESS (mr_dr_eq, mc_dc_eq, mr_sr, mc_sc, NOC_BUS_IN, this_position) IS -- Instruction routing, source->destination for write (ON=0) , destination->source for read (ON=1)
    BEGIN
        SEGMENT_SRC <= '0';
        SEGMENT_DST <= '0';
        NORTH_instruction <= IDLE_PAR_INST;
        SOUTH_instruction <= IDLE_PAR_INST;
        EAST_instruction <= IDLE_PAR_INST;
        WEST_instruction <= IDLE_PAR_INST;
        DIRECTION_OUT <= IGNORE;
        NOC_BUS_OUT <= NOC_BUS_IN;

        IF NOC_BUS_IN.bus_enable = '1' AND NOC_BUS_IN.instr_code = both_instruction THEN
            IF or_reduce(i_DRH) /= '0' THEN -- YX routing so we start with rows
                IF i_DRH_dir = '1' THEN
                    NORTH_instruction <= LOW_UP_PAR_INST;
                    IF i_ON = '0' THEN
						DIRECTION_OUT <= ('1', this_position, to_north);
					ELSE
                        DIRECTION_OUT <= ('1', from_north, this_position);
					END IF;
                ELSE
                    SOUTH_instruction <= LOW_DOWN_PAR_INST;
                    IF i_ON = '0' THEN
						DIRECTION_OUT <= ('1', this_position, to_south);
					ELSE
                        DIRECTION_OUT <= ('1', from_south, this_position);
					END IF;
                END IF;

                i_DRH_out <= STD_LOGIC_VECTOR(unsigned(i_DRH) - 1);

            ELSIF or_reduce(i_DCH) /= '0' THEN -- Now do cols
                IF i_DCH_DIR = '1' THEN
                    EAST_instruction <= LOW_RITE_PAR_INST;
                    IF i_ON = '0' THEN
						DIRECTION_OUT <= ('1', this_position, to_east);
					ELSE
                        DIRECTION_OUT <= ('1', from_east, this_position);
					END IF;
                ELSE
                    WEST_instruction <= LOW_LEFT_PAR_INST;
                    IF i_ON = '0' THEN
						DIRECTION_OUT <= ('1', this_position, to_west);
					ELSE
                        DIRECTION_OUT <= ('1', from_west, this_position);
					END IF;
                END IF;

                i_DCH_out <= STD_LOGIC_VECTOR(unsigned(i_DCH) - 1);

            ELSE
                SEGMENT_SRC <= i_ON;
                SEGMENT_DST <= NOT i_ON;

            	IF i_ON = '0' THEN
					DIRECTION_OUT <= ('1', this_position, to_memory);
				ELSE
                	DIRECTION_OUT <= ('1', from_memory, this_position);
				END IF;
            END IF;

        END IF;

    END PROCESS;

END ARCHITECTURE RTL;
