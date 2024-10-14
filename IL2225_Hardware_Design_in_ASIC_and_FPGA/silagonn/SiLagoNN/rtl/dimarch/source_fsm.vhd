-------------------------------------------------------
--! @file source_fsm.vhd
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
-- File       : source_fsm.vhd
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

-- This is a SRAM Tile which will be used to extend DRRA Fabric for memory communication
-- be changed by changing the generics
--
--- Authors: Muhammad Adeel Tajammul: PhD student, ES, School of ICT, KTH, Kista.
-- Contact: tajammul@kth.se
---------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
--use work.drra_types_n_constants.all;
--use work.top_consts_types_package.SRAM_AGU_INSTR_WIDTH;
--USE work.top_consts_types_package.ALL;
USE work.top_consts_types_package.ALL;
USE work.noc_types_n_constants.ALL;
--use work.SINGLEPORT_SRAM_AGU_types_n_constants.AGU_INSTR_WIDTH;
--use work.SINGLEPORT_SRAM_AGU_types_n_constants.outputcontrol_s;
--use work.SINGLEPORT_SRAM_AGU_types_n_constants.outputcontrol_WIDTH;
--use work.SINGLEPORT_SRAM_AGU_types_n_constants.outputcontrol_e;

--DECLARE PKGS
ENTITY source_fsm IS
  GENERIC (
    POSITION : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00"  --! see noc_types_n_constants NORTH SOUTH EAST WEST
    );

  PORT (
    rst_n                    : IN  STD_LOGIC;
    clk                      : IN  STD_LOGIC;
    bus_in                   : IN  NOC_BUS_TYPE;
    ----------------------------
    --  Source Decoder Flags
    ----------------------------
    RETRANSMIT               : IN  STD_LOGIC;  -- is the data turning or not
    SEGMENT_SRC              : IN  STD_LOGIC;  -- is this the source data    (for routing)
    SEGMENT_DST              : IN  STD_LOGIC;  -- is this the destination data (for routing)
    flip_transmit            : IN  STD_LOGIC;  -- is this an intermediate down and we need to flip the segment bit (for routing)
    --------------------------------------------------------
    --  Source Decoder PROPOSED PARTITION VALUES
    --------------------------------------------------------
    NORTH_instruction        : IN  PARTITION_INSTRUCTION_RECORD_TYPE;
    SOUTH_instruction        : IN  PARTITION_INSTRUCTION_RECORD_TYPE;
    EAST_instruction         : IN  PARTITION_INSTRUCTION_RECORD_TYPE;
    WEST_instruction         : IN  PARTITION_INSTRUCTION_RECORD_TYPE;
    ----------------------------
    --  partition_status  from partition handler
    ----------------------------
    east_splitter_direction  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    west_splitter_direction  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    north_splitter_direction : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    south_splitter_direction : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
    reset_fsm                : IN  STD_LOGIC;
    ----------------------------
    --  Segmented bus output
    ----------------------------
    bus_out                  : OUT NOC_BUS_TYPE;
    horizontal_sel           : OUT STD_LOGIC;
    vertical_sel             : OUT STD_LOGIC;
    ----------------------------
    --  AGUs and handles input
    ----------------------------
    agu_en_r                 : OUT STD_LOGIC;
    agu_en_w                 : OUT STD_LOGIC;
    SRAM_AGU_instruction_r   : OUT sram_agu_instruction_type;
    SRAM_AGU_instruction_w   : OUT sram_agu_instruction_type
    );
END ENTITY source_fsm;

ARCHITECTURE RTL OF source_fsm IS

  ALIAS i_ON            : STD_LOGIC IS bus_in.INSTRUCTION(ON_l);  -- ORIGIN NODE 1=DESTINATION
  ALIAS i_outputcontrol : STD_LOGIC IS bus_in.INSTRUCTION(NoC_Bus_instr_width - sr_rw);

  ALIAS i_hops_in  : STD_LOGIC_VECTOR IS bus_in.INSTRUCTION(NoC_Bus_instr_width - sr_hops_s DOWNTO NoC_Bus_instr_width - sr_hops_e);
  ALIAS i_hops_out : STD_LOGIC_VECTOR IS bus_out.INSTRUCTION(NoC_Bus_instr_width - sr_hops_s DOWNTO NoC_Bus_instr_width - sr_hops_e);

    ALIAS i_SRH_dir : STD_LOGIC IS bus_in.INSTRUCTION(SRH_dir_l); -- SOURCE ROW DIR
    ALIAS i_SRH : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS bus_in.INSTRUCTION(SRH_e DOWNTO SRH_s); -- SOURCE ROW
    ALIAS i_SCH_dir : STD_LOGIC IS bus_in.INSTRUCTION(SCH_dir_l); -- SOURCE COLUMN DIR
    ALIAS i_SCH : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS bus_in.INSTRUCTION(SCH_e DOWNTO SCH_s); -- SOURCE COLUMN
    ALIAS i_DRH_dir : STD_LOGIC IS bus_in.INSTRUCTION(DRH_dir_l); -- DESTINATION ROW DIR
    ALIAS i_DRH : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS bus_in.INSTRUCTION(DRH_e DOWNTO DRH_s); -- DESTINATION ROW
    ALIAS i_SRH_dir_out : STD_LOGIC IS bus_out.INSTRUCTION(SRH_dir_l); -- SOURCE ROW DIR
    ALIAS i_SRH_out : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS bus_out.INSTRUCTION(SRH_e DOWNTO SRH_s); -- SOURCE ROW
    ALIAS i_SCH_dir_out : STD_LOGIC IS bus_out.INSTRUCTION(SCH_dir_l); -- SOURCE COLUMN DIR
    ALIAS i_SCH_out : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS bus_out.INSTRUCTION(SCH_e DOWNTO SCH_s); -- SOURCE COLUMN
    ALIAS i_DRH_dir_out : STD_LOGIC IS bus_out.INSTRUCTION(DRH_dir_l); -- DESTINATION ROW DIR
    ALIAS i_DRH_out : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0) IS bus_out.INSTRUCTION(DRH_e DOWNTO DRH_s); -- DESTINATION ROW

  SIGNAL nb_hops : UNSIGNED(sr_hops_width - 1 DOWNTO 0);

  TYPE switch_state_type IS (IDLE, PARTITIONED);
  SIGNAL current_state : switch_state_type;

  SIGNAL src_agu_flag : STD_LOGIC;
  SIGNAL dst_agu_flag : STD_LOGIC;

BEGIN
  p_extract_hops_agu : PROCESS (bus_in) IS
  BEGIN
    IF bus_in.instr_code = AGU_instruction THEN
      nb_hops <= unsigned(i_hops_in);
    ELSE
      nb_hops <= to_unsigned(0, nb_hops'length);
    END IF;
  END PROCESS p_extract_hops_agu;

  p_source_fsm : PROCESS (clk, rst_n) IS
  BEGIN
    IF rst_n = '0' THEN
      SRAM_AGU_instruction_r <= sram_instr_zero;
      SRAM_AGU_instruction_w <= sram_instr_zero;
      current_state          <= IDLE;
      agu_en_r               <= '0';
      agu_en_w               <= '0';
      src_agu_flag           <= '0';
      dst_agu_flag           <= '0';
      horizontal_sel         <= '0';
      vertical_sel           <= '0';
      bus_out                <= IDLE_BUS;

    ELSIF rising_edge(clk) THEN
      SRAM_AGU_instruction_r <= sram_instr_zero;
      SRAM_AGU_instruction_w <= sram_instr_zero;
      -- current_state is not always changed
      agu_en_r               <= '0';
      agu_en_w               <= '0';
      -- src_agu_flag is not always changed
      -- dst_agu_flag is not always changed
      -- horizontal_sel is not always changed
      -- vertical_sel is not always changed
      bus_out                <= IDLE_BUS;

      CASE current_state IS

        ---------------------------------------------------------------------------------------------------------------------------
        -- IDLE
        ---------------------------------------------------------------------------------------------------------------------------
        WHEN IDLE =>

          IF bus_in.bus_enable = '1' THEN
            IF bus_in.instr_code = both_instruction OR bus_in.instr_code = partitioning_instruction THEN
              -------- PARTITIONNING -------------------------------------
              -- Open north path --------------------
              IF NORTH_instruction.ENABLE = '1' THEN  --
                horizontal_sel <= '0';
                vertical_sel   <= '1';
              -- Open south path --------------------
              ELSIF SOUTH_instruction.ENABLE = '1' THEN
                horizontal_sel <= '0';
                vertical_sel   <= '1';
              -- Open east path --------------------
              ELSIF EAST_instruction.ENABLE = '1' THEN
                horizontal_sel <= '1';
                vertical_sel   <= '0';
              -- Open west path --------------------
              ELSIF WEST_instruction.ENABLE = '1' THEN
                horizontal_sel <= '1';
                vertical_sel   <= '0';
              -- Final node
              ELSE
                ASSERT (SEGMENT_DST OR SEGMENT_SRC) = '1' REPORT "Non terminal node doesn't open a new partition" SEVERITY failure;
              END IF;

              current_state <= PARTITIONED;
              bus_out       <= bus_in;
            END IF;  -- both or partition

            IF bus_in.instr_code = route_instruction OR bus_in.instr_code = both_instruction THEN
              -------- ROUTING -------------------------------------
              IF SEGMENT_DST = '1' THEN
                ASSERT I_ON = '0' REPORT "Destination node is also origin node" SEVERITY failure;
                dst_agu_flag  <= '1';
                current_state <= PARTITIONED;
              ELSIF SEGMENT_SRC = '1' THEN
                bus_out       <= IDLE_BUS;
                ASSERT I_ON = '1' REPORT "Source node is not origin node" SEVERITY failure;
                src_agu_flag  <= '1';
                current_state <= PARTITIONED;
                bus_out       <= IDLE_BUS;
              ELSE
                bus_out <= bus_in;
              END IF;
            END IF;  -- routing

            IF bus_in.instr_code = AGU_instruction THEN
              ASSERT false REPORT "Not supposed to receive AGU instruction in idle state" SEVERITY failure;
            END IF;  -- IDLE state + AGU_instruction

            IF bus_in.instr_code = route_instruction THEN
              ASSERT false REPORT "Not supposed to receive route instruction in idle state" SEVERITY failure;
            END IF;  -- IDLE state + route_instruction

          END IF;  --bus_in.bus_enable

          ---------------------------------------------------------------------------------------------------------------------------
          -- PARTITIONED (ready to transmit incoming route/agu instructions, buses has been selected)
          ---------------------------------------------------------------------------------------------------------------------------

        WHEN PARTITIONED =>

          IF reset_fsm = '1' THEN
            src_agu_flag   <= '0';
            dst_agu_flag   <= '0';
            horizontal_sel <= '0';
            vertical_sel   <= '0';
            current_state  <= IDLE;
          END IF;  -- kill partition

          IF bus_in.bus_enable = '1' THEN
            IF bus_in.instr_code = both_instruction OR bus_in.instr_code = partitioning_instruction THEN
              horizontal_sel <= '0';
              vertical_sel   <= '0';
              -------- PARTITIONNING -------------------------------------
              -- Open north path --------------------
              IF NORTH_instruction.ENABLE = '1' THEN  --
                horizontal_sel <= '0';
                vertical_sel   <= '1';
              -- Open south path --------------------
              ELSIF SOUTH_instruction.ENABLE = '1' THEN
                horizontal_sel <= '0';
                vertical_sel   <= '1';
              -- Open east path --------------------
              ELSIF EAST_instruction.ENABLE = '1' THEN
                horizontal_sel <= '1';
                vertical_sel   <= '0';
              -- Open west path --------------------
              ELSIF WEST_instruction.ENABLE = '1' THEN
                horizontal_sel <= '1';
                vertical_sel   <= '0';
              -- Final node
              ELSE
                ASSERT (SEGMENT_DST OR SEGMENT_SRC) = '1' REPORT "Non terminal node doesn't open a new partition" SEVERITY failure;
              END IF;

              bus_out <= bus_in;
            END IF;  -- both or partition

            IF bus_in.instr_code = route_instruction OR bus_in.instr_code = both_instruction THEN
              src_agu_flag <= '0';
              dst_agu_flag <= '0';
              -------- ROUTING -------------------------------------
              IF SEGMENT_DST = '1' THEN
                ASSERT I_ON = '0' REPORT "Destination node is also origin node" SEVERITY failure;
                dst_agu_flag  <= '1';
                current_state <= PARTITIONED;
                bus_out       <= IDLE_BUS;
              ELSIF SEGMENT_SRC = '1' THEN
                ASSERT I_ON = '1' REPORT "Source node is not origin node" SEVERITY failure;
                src_agu_flag  <= '1';
                current_state <= PARTITIONED;
                bus_out       <= IDLE_BUS;
              ELSE
                bus_out <= bus_in;
              END IF;
            END IF;  -- routing

            IF bus_in.instr_code = AGU_instruction THEN
              IF nb_hops > 0 THEN
                bus_out    <= bus_in;
                i_hops_out <= STD_LOGIC_VECTOR(nb_hops - 1);
              ELSE
                bus_out <= IDLE_BUS;
                -- receive the AGU instruction
                IF i_outputcontrol = '0' THEN
                  SRAM_AGU_instruction_r <= unpack_sram_noc_agu(bus_in.INSTRUCTION);
                  agu_en_r               <= '1';
                ELSE
                  SRAM_AGU_instruction_w <= unpack_sram_noc_agu(bus_in.INSTRUCTION);
                  agu_en_w               <= '1';
                END IF;
              END IF;  -- nb_hops > 0
            END IF;  -- agu instruction

          END IF;  --bus_in.bus_enable

      END CASE;  -- current_state

    END IF;  --rising_edge (clk)
  END PROCESS p_source_fsm;

END ARCHITECTURE RTL;
