-------------------------------------------------------
--! @file fabric.vhd
--! @brief 
--! @details 
--! @author Sadiq Hemani
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
-- File       : fabric.vhd
-- Author     : Sadiq Hemani <sadiq@kth.se>
-- Company    : KTH
-- Created    : 2013-09-05
-- Last update: 2013-11-21
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2013
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2013-09-05  1.0      Sadiq Hemani <sadiq@kth.se>
-- 2013-09-30  1.0      Nasim Farahini <farahini@kth.se>
-- 2013-11-21 1.0       Sadiq Hemani <sadiq@kth.se>
-- 2014-02-10  1.0      Nasim Farahini <farahini@kth.se>
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
USE work.seq_functions_package.ALL;
USE work.util_package.ALL;
--USE ieee.std_logic_unsigned.ALL;
USE work.top_consts_types_package.ALL;
USE work.noc_types_n_constants.ALL;
USE work.crossbar_types_n_constants.ALL;

ENTITY fabric_dimarch IS
    PORT (
        clk       : IN std_logic;
        rst_n     : IN std_logic;
        --------------------------------------------------------
        --Dimarch connections
        --------------------------------------------------------
        NOC_FROM_TB  : IN INST_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO ROWS - 1);
        DATA_FROM_TB : IN DATA_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO ROWS - 1);
        DATA_TO_TB   : OUT DATA_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO ROWS - 1);
        --------------------------------------------------------
        --SRAM initialization from testbench
        --------------------------------------------------------
        first_ROW   : IN UNSIGNED(ROW_WIDTH - 1 DOWNTO 0);
        first_COL   : IN UNSIGNED(COL_WIDTH - 1 DOWNTO 0);
        tb_en    : IN STD_LOGIC;                                         -- Write Enable from test bench
        tb_addrs : IN STD_LOGIC_VECTOR(SRAM_ADDRESS_WIDTH - 1 DOWNTO 0); -- Write Address from test bench
        tb_inp   : IN STD_LOGIC_VECTOR(SRAM_WIDTH - 1 DOWNTO 0);
        tb_ROW   : IN UNSIGNED(ROW_WIDTH - 1 DOWNTO 0);
        tb_COL   : IN UNSIGNED(COL_WIDTH - 1 DOWNTO 0)
    );
END ENTITY fabric_dimarch;

ARCHITECTURE rtl OF fabric_dimarch IS

    ---------------------------------------------
    -- Dimarch interconnect signals
    ---------------------------------------------
    SIGNAL DATA_SOUTH : DATA_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL DATA_NORTH : DATA_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL DATA_WEST  : DATA_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL DATA_EAST  : DATA_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    
    SIGNAL NOC_SOUTH : INST_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL NOC_NORTH : INST_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL NOC_WEST  : INST_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL NOC_EAST  : INST_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);

    SIGNAL PARTITION_NORTH : PARTITION_INSTRUCTION_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL PARTITION_EAST  : PARTITION_INSTRUCTION_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);

    SIGNAL SPLITTER_SOUTH  : DIRECTION_TYPE(0 TO COLUMNS, 0 TO MAX_ROW);
    SIGNAL SPLITTER_WEST   : DIRECTION_TYPE(0 TO COLUMNS, 0 TO MAX_ROW);

    -------------------------
    -- Address signals
    -------------------------	
    SIGNAL row_dimarch_right        : ROW_ADDR_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL col_dimarch_right        : COL_ADDR_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL addr_valid_dimarch_right : ADDR_VALID_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);

    -------------------------
    -- SRAM testbench signals
    -------------------------
    SIGNAL tb_en_out_array    : DATA_RD_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL tb_addrs_out_array : SRAM_ADDR_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL tb_inp_out_array   : DATA_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL tb_ROW_out_array   : SRAM_ROW_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    SIGNAL tb_COL_out_array   : SRAM_COL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);

BEGIN -- ARCHITECTURE rtl

    --------------------------------------------------------------------------------------------------
    -- DiMArch
    --------------------------------------------------------------------------------------------------	

    --DiMArch_COLS
    DiMArch_COLS : FOR i IN 0 TO COLUMNS - 1 GENERATE
    BEGIN

        NOC_NORTH(i, 0)  <= NOC_FROM_TB(i, 0);
        DATA_NORTH(i, 0) <= DATA_FROM_TB(i, 0);
        DATA_TO_TB(i, 0) <= DATA_SOUTH(i, 1);

        --DiMArch_ROWS
        DiMArch_ROWS : FOR j IN 1 TO MAX_ROW GENERATE
        BEGIN
            if_dimarch_bot_l : IF j = 1 AND i = 0 GENERATE
                DiMArchTile_bot_l : ENTITY work.DiMArchTile
                    PORT MAP
                    (
                        rst_n => rst_n,
                        clk   => clk,
                        -------------------------
                        -- Address signals
                        -------------------------
                        start_row => '0',                            --! Start signal (connected to the valid signal of the previous block in the same row)
                        start_col => '1',                            --! Start signal (connected to the valid signal of the previous block in the same col)
                        prevRow   => first_ROW,                      --! Row address assigned to the previous cell
                        prevCol   => first_COL,                      --! Col address assigned to the previous cell
                        valid     => addr_valid_dimarch_right(i, j), --! Valid signals, used to signal that the assignment of the address is complete
                        thisRow   => row_dimarch_right(i, j),        --! The row address assigned to the cell
                        thisCol   => col_dimarch_right(i, j),        --! The column address assigned to the cell
                        -------------------------
                        -- Crossbar data signals
                        -------------------------
                        data_north_out => DATA_NORTH(i, j),      --! Going to cell above
                        data_south_out => DATA_SOUTH(i, j),      --! Going to cell under
                        data_east_out  => DATA_EAST(i, j),       --! Going to cell on the right
                        data_west_out  => OPEN,                  --! Going to cell on the left

                        data_north_in  => DATA_SOUTH(i, j + 1),  --! Coming from cell above
                        data_south_in  => DATA_NORTH(i, j-1),    --! Coming from cell under
                        data_east_in   => DATA_WEST(i+1, j),     --! Coming from cell on the right
                        data_west_in   => (OTHERS => '0'),       --! Coming from cell on the left
                        --------------------------------------------------
                        -- Directions of neighboring buses
                        --------------------------------------------------
                        top_splitter_direction    => SPLITTER_SOUTH(i, j+1),  --! Coming from the cell above
                        bottom_splitter_direction => OPEN,                    --! Going to the cell under
                        right_splitter_direction  => SPLITTER_WEST(i+1, j),   --! Coming from the cell on the right
                        left_splitter_direction   => OPEN,                    --! Going to the cell on the left
                        --------------------------------------------------
                        -- Partition instructions to neighboring buses
                        --------------------------------------------------
                        top_partition_out      => PARTITION_NORTH(i, j),	 --! Going to the cell above
                        bottom_partition_in    => HIGH_UP_PAR_INST,          --! Coming from the cell under
                        right_partition_out    => PARTITION_EAST(i, j),      --! Going to the cell on the right
                        left_partition_in      => IDLE_PAR_INST,             --! Coming from the cell on the left
                        ----------------------------
                        -- SEMENTED BUS I/0  
                        ----------------------------
                        noc_north_out => NOC_NORTH(i,j),      --! Going to the cell above
                        noc_south_out => OPEN,                --! Going to the cell under
                        noc_east_out  => NOC_EAST(i,j),       --! Going to the cell on the right
                        noc_west_out  => OPEN,                --! Going to the cell on the left

                        noc_north_in  => NOC_SOUTH(i, j+1),   --! Coming from the cell above
                        noc_south_in  => NOC_NORTH(i, j-1),   --! Coming from the cell under
                        noc_east_in   => NOC_WEST(i+1, j),    --! Coming from the cell on the right
                        noc_west_in   => IDLE_BUS,            --! Coming from the cell on the left
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- input signals from the left hand side
                        --------------------------------------------------------
                        tb_en    => tb_en,
                        tb_addrs => tb_addrs,
                        tb_inp   => tb_inp,
                        tb_ROW   => tb_ROW,
                        tb_COL   => tb_COL,
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- output signals from the right hand side
                        --------------------------------------------------------
                        tb_en_out    => tb_en_out_array(i, j),
                        tb_addrs_out => tb_addrs_out_array(i, j),  --! Write Address from test bench
                        tb_inp_out   => tb_inp_out_array(i, j),
                        tb_ROW_out   => tb_ROW_out_array(i, j),
                        tb_COL_out   => tb_COL_out_array(i, j)
                    );
            END GENERATE;

            if_dimarch_bot : IF j = 1 AND i > 0 and i < COLUMNS-1 GENERATE
                DiMArchTile_bot : ENTITY work.DiMArchTile
                    PORT MAP
                    (
                        rst_n => rst_n,
                        clk   => clk,
                        -------------------------
                        -- Address signals
                        -------------------------
                        start_row => addr_valid_dimarch_right(i-1, j), --! Start signal (connected to the valid signal of the previous block in the same row)
                        start_col => '0',                              --! Start signal (connected to the valid signal of the previous block in the same col)
                        prevRow   => row_dimarch_right(i-1, j),        --! Row address assigned to the previous cell
                        prevCol   => col_dimarch_right(i-1, j),        --! Col address assigned to the previous cell
                        valid     => addr_valid_dimarch_right(i, j),   --! Valid signals, used to signal that the assignment of the address is complete
                        thisRow   => row_dimarch_right(i, j),          --! The row address assigned to the cell
                        thisCol   => col_dimarch_right(i, j),          --! The column address assigned to the cell
                        -------------------------
                        -- Crossbar data signals
                        -------------------------
                        data_north_out => DATA_NORTH(i, j),      --! Going to cell above
                        data_south_out => DATA_SOUTH(i, j),      --! Going to cell under
                        data_east_out  => DATA_EAST(i, j),       --! Going to cell on the right
                        data_west_out  => DATA_WEST(i, j),       --! Going to cell on the left

                        data_north_in  => DATA_SOUTH(i, j + 1),  --! Coming from cell above
                        data_south_in  => DATA_NORTH(i, j-1),    --! Coming from cell under
                        data_east_in   => DATA_WEST(i+1, j),     --! Coming from cell on the right
                        data_west_in   => DATA_EAST(i-1,j),      --! Coming from cell on the left
                        --------------------------------------------------
                        -- Directions of neighboring buses
                        --------------------------------------------------
                        top_splitter_direction   => SPLITTER_SOUTH(i, j+1),  --! Coming from the cell above
                        bottom_splitter_direction => OPEN,                   --! Going to the cell under
                        right_splitter_direction => SPLITTER_WEST(i+1, j),   --! Coming from the cell on the right
                        left_splitter_direction  => SPLITTER_WEST(i,j),      --! Going to the cell on the left
                        --------------------------------------------------
                        -- Partition instructions to neighboring buses
                        --------------------------------------------------
                        top_partition_out      => PARTITION_NORTH(i, j),	 --! Going to the cell above
                        bottom_partition_in    => HIGH_UP_PAR_INST,          --! Coming from the cell under
                        right_partition_out    => PARTITION_EAST(i, j),      --! Going to the cell on the right
                        left_partition_in      => PARTITION_EAST(i-1, j),	 --! Coming from the cell on the left
                        ----------------------------
                        -- SEMENTED BUS I/0  
                        ----------------------------
                        noc_north_out => NOC_NORTH(i,j),      --! Going to the cell above
                        noc_south_out => OPEN,                --! Going to the cell under
                        noc_east_out  => NOC_EAST(i,j),       --! Going to the cell on the right
                        noc_west_out  => NOC_WEST(i,j),       --! Going to the cell on the left

                        noc_north_in  => NOC_SOUTH(i, j+1),   --! Coming from the cell above
                        noc_south_in  => NOC_NORTH(i, j-1),   --! Coming from the cell under
                        noc_east_in   => NOC_WEST(i+1, j),    --! Coming from the cell on the right
                        noc_west_in   => NOC_EAST(i-1, j),    --! Coming from the cell on the left
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- input signals from the left hand side
                        --------------------------------------------------------
                        tb_en    => tb_en_out_array(i-1, j),
                        tb_addrs => tb_addrs_out_array(i-1, j),
                        tb_inp   => tb_inp_out_array(i-1, j),
                        tb_ROW   => tb_ROW_out_array(i-1, j),
                        tb_COL   => tb_COL_out_array(i-1, j),
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- output signals from the right hand side
                        --------------------------------------------------------
                        tb_en_out    => tb_en_out_array(i, j),
                        tb_addrs_out => tb_addrs_out_array(i, j),
                        tb_inp_out   => tb_inp_out_array(i, j),
                        tb_ROW_out   => tb_ROW_out_array(i, j),
                        tb_COL_out   => tb_COL_out_array(i, j)
                    );
            END GENERATE;

            if_dimarch_bot_r : IF j = 1 AND i = COLUMNS-1 GENERATE
                DiMArchTile_bot_r : ENTITY work.DiMArchTile
                    PORT MAP
                    (
                        rst_n => rst_n,
                        clk   => clk,
                        -------------------------
                        -- Address signals
                        -------------------------
                        start_row => addr_valid_dimarch_right(i-1, j), --! Start signal (connected to the valid signal of the previous block in the same row)
                        start_col => '0',                              --! Start signal (connected to the valid signal of the previous block in the same col)
                        prevRow   => row_dimarch_right(i-1, j),        --! Row address assigned to the previous cell
                        prevCol   => col_dimarch_right(i-1, j),         --! Col address assigned to the previous cell
                        valid     => addr_valid_dimarch_right(i, j),   --! Valid signals, used to signal that the assignment of the address is complete
                        thisRow   => row_dimarch_right(i, j),          --! The row address assigned to the cell
                        thisCol   => col_dimarch_right(i, j),          --! The column address assigned to the cell
                        -------------------------
                        -- Crossbar data signals
                        -------------------------
                        data_north_out => DATA_NORTH(i, j),      --! Going to cell above
                        data_south_out => DATA_SOUTH(i, j),      --! Going to cell under
                        data_east_out  => OPEN,                  --! Going to cell on the right
                        data_west_out  => DATA_WEST(i, j),       --! Going to cell on the left

                        data_north_in  => DATA_SOUTH(i, j + 1),  --! Coming from cell above
                        data_south_in  => DATA_NORTH(i, j-1),    --! Coming from cell under
                        data_east_in   => (OTHERS => '0'),       --! Coming from cell on the right
                        data_west_in   => DATA_EAST(i-1,j),      --! Coming from cell on the left
                        --------------------------------------------------
                        -- Directions of neighboring buses
                        --------------------------------------------------
                        top_splitter_direction   => SPLITTER_SOUTH(i, j+1),  --! Coming from the cell above
                        bottom_splitter_direction => OPEN,                   --! Going to the cell under
                        right_splitter_direction => (OTHERS => '0'),         --! Coming from the cell on the right
                        left_splitter_direction  => SPLITTER_WEST(i,j),      --! Going to the cell on the left
                        --------------------------------------------------
                        -- Partition instructions to neighboring buses
                        --------------------------------------------------
                        top_partition_out      => PARTITION_NORTH(i, j),	 --! Going to the cell above
                        bottom_partition_in    => HIGH_UP_PAR_INST,          --! Coming from the cell under
                        right_partition_out    => OPEN,                      --! Going to the cell on the right
                        left_partition_in      => PARTITION_EAST(i-1, j),	 --! Coming from the cell on the left
                        ----------------------------
                        -- SEMENTED BUS I/0  
                        ----------------------------
                        noc_north_out => NOC_NORTH(i,j),      --! Going to the cell above
                        noc_south_out => OPEN,                --! Going to the cell under
                        noc_east_out  => OPEN,                --! Going to the cell on the right
                        noc_west_out  => NOC_WEST(i,j),       --! Going to the cell on the left

                        noc_north_in  => NOC_SOUTH(i, j+1),   --! Coming from the cell above
                        noc_south_in  => NOC_NORTH(i, j-1),   --! Coming from the cell under
                        noc_east_in   => IDLE_BUS,            --! Coming from the cell on the right
                        noc_west_in   => NOC_EAST(i-1, j),    --! Coming from the cell on the left
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- input signals from the left hand side
                        --------------------------------------------------------
                        tb_en    => tb_en_out_array(i-1, j),
                        tb_addrs => tb_addrs_out_array(i-1, j),
                        tb_inp   => tb_inp_out_array(i-1, j),
                        tb_ROW   => tb_ROW_out_array(i-1, j),
                        tb_COL   => tb_COL_out_array(i-1, j),
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- output signals from the right hand side
                        --------------------------------------------------------
                        tb_en_out    => tb_en_out_array(i, j),
                        tb_addrs_out => tb_addrs_out_array(i, j),  --! Write Address from test bench
                        tb_inp_out   => tb_inp_out_array(i, j),
                        tb_ROW_out   => tb_ROW_out_array(i, j),
                        tb_COL_out   => tb_COL_out_array(i, j)
                    );
            END GENERATE;

            if_dimarch_top_l : IF j /= 1 AND j = MAX_ROW AND i = 0 GENERATE
                DiMArchTile_top_l : ENTITY work.DiMArchTile
                    PORT MAP
                    (
                        rst_n => rst_n,
                        clk   => clk,
                        -------------------------
                        -- Address signals
                        -------------------------
                        start_row => '0',                              --! Start signal (connected to the valid signal of the previous block in the same row)
                        start_col => addr_valid_dimarch_right(i, j-1), --! Start signal (connected to the valid signal of the previous block in the same col)
                        prevRow   => row_dimarch_right(i, j-1),        --! Row address assigned to the previous cell
                        prevCol   => col_dimarch_right(i, j-1),        --! Col address assigned to the previous cell
                        valid     => addr_valid_dimarch_right(i, j),   --! Valid signals, used to signal that the assignment of the address is complete
                        thisRow   => row_dimarch_right(i, j),          --! The row address assigned to the cell
                        thisCol   => col_dimarch_right(i, j),          --! The column address assigned to the cell
                        -------------------------
                        -- Crossbar data signals
                        -------------------------
                        data_north_out => OPEN,                  --! Going to cell above
                        data_south_out => DATA_SOUTH(i, j),      --! Going to cell under
                        data_east_out  => DATA_EAST(i, j),       --! Going to cell on the right
                        data_west_out  => OPEN,                  --! Going to cell on the left

                        data_north_in  => (OTHERS => '0'),       --! Coming from cell above
                        data_south_in  => DATA_NORTH(i, j-1),    --! Coming from cell under
                        data_east_in   => DATA_WEST(i+1, j),     --! Coming from cell on the right
                        data_west_in   => (OTHERS => '0'),       --! Coming from cell on the left
                        --------------------------------------------------
                        -- Directions of neighboring buses
                        --------------------------------------------------
                        top_splitter_direction    => (OTHERS => '0'),          --! Coming from the cell above
                        bottom_splitter_direction => SPLITTER_SOUTH(i, j),     --! Going to the cell under
                        right_splitter_direction  => SPLITTER_WEST(i+1, j),    --! Coming from the cell on the right
                        left_splitter_direction   => OPEN,                     --! Going to the cell on the left
                        --------------------------------------------------
                        -- Partition instructions to neighboring buses
                        --------------------------------------------------
                        top_partition_out      => OPEN,	                     --! Going to the cell above
                        bottom_partition_in    => PARTITION_NORTH(i, j-1),   --! Coming from the cell under
                        right_partition_out    => PARTITION_EAST(i, j),      --! Going to the cell on the right
                        left_partition_in      => IDLE_PAR_INST,         	 --! Coming from the cell on the left
                        ----------------------------
                        -- SEMENTED BUS I/0  
                        ----------------------------
                        noc_north_out => OPEN,                --! Going to the cell above
                        noc_south_out => NOC_SOUTH(i,j),      --! Going to the cell under
                        noc_east_out  => NOC_EAST(i,j),       --! Going to the cell on the right
                        noc_west_out  => OPEN,                --! Going to the cell on the left

                        noc_north_in  => IDLE_BUS,            --! Coming from the cell above
                        noc_south_in  => NOC_NORTH(i, j-1),   --! Coming from the cell under
                        noc_east_in   => NOC_WEST(i+1, j),    --! Coming from the cell on the right
                        noc_west_in   => IDLE_BUS,            --! Coming from the cell on the left
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- input signals from the left hand side
                        --------------------------------------------------------
                        tb_en    => tb_en_out_array(i, j-1),
                        tb_addrs => tb_addrs_out_array(i, j-1),
                        tb_inp   => tb_inp_out_array(i, j-1),
                        tb_ROW   => tb_ROW_out_array(i, j-1),
                        tb_COL   => tb_COL_out_array(i, j-1),
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- output signals from the right hand side
                        --------------------------------------------------------
                        tb_en_out    => tb_en_out_array(i, j),
                        tb_addrs_out => tb_addrs_out_array(i, j),  --! Write Address from test bench
                        tb_inp_out   => tb_inp_out_array(i, j),
                        tb_ROW_out   => tb_ROW_out_array(i, j),
                        tb_COL_out   => tb_COL_out_array(i, j)
                    );
            END GENERATE;

            if_dimarch_top : IF j /= 1 AND j = MAX_ROW AND i > 0 AND i < COLUMNS-1 GENERATE
                DiMArchTile_top : ENTITY work.DiMArchTile
                    PORT MAP
                    (
                        rst_n => rst_n,
                        clk   => clk,
                        -------------------------
                        -- Address signals
                        -------------------------
                        start_row => '0',                              --! Start signal (connected to the valid signal of the previous block in the same row)
                        start_col => addr_valid_dimarch_right(i, j-1), --! Start signal (connected to the valid signal of the previous block in the same col)
                        prevRow   => row_dimarch_right(i, j-1),        --! Row address assigned to the previous cell
                        prevCol   => col_dimarch_right(i, j-1),        --! Col address assigned to the previous cell
                        valid     => addr_valid_dimarch_right(i, j),   --! Valid signals, used to signal that the assignment of the address is complete
                        thisRow   => row_dimarch_right(i, j),          --! The row address assigned to the cell
                        thisCol   => col_dimarch_right(i, j),          --! The column address assigned to the cell
                        -------------------------
                        -- Crossbar data signals
                        -------------------------
                        data_north_out => OPEN,                  --! Going to cell above
                        data_south_out => DATA_SOUTH(i, j),      --! Going to cell under
                        data_east_out  => DATA_EAST(i, j),       --! Going to cell on the right
                        data_west_out  => DATA_WEST(i, j),       --! Going to cell on the left

                        data_north_in  => (OTHERS => '0'),       --! Coming from cell above
                        data_south_in  => DATA_NORTH(i, j-1),    --! Coming from cell under
                        data_east_in   => DATA_WEST(i+1, j),     --! Coming from cell on the right
                        data_west_in   => DATA_EAST(i-1, j),     --! Coming from cell on the left
                        --------------------------------------------------
                        -- Directions of neighboring buses
                        --------------------------------------------------
                        top_splitter_direction    => (OTHERS => '0'),          --! Coming from the cell above
                        bottom_splitter_direction => SPLITTER_SOUTH(i, j),     --! Going to the cell under
                        right_splitter_direction  => SPLITTER_WEST(i+1, j),    --! Coming from the cell on the right
                        left_splitter_direction   => SPLITTER_WEST(i,j),       --! Going to the cell on the left
                        --------------------------------------------------
                        -- Partition instructions to neighboring buses
                        --------------------------------------------------
                        top_partition_out      => OPEN,	                     --! Going to the cell above
                        bottom_partition_in    => PARTITION_NORTH(i, j-1),   --! Coming from the cell under
                        right_partition_out    => PARTITION_EAST(i, j),      --! Going to the cell on the right
                        left_partition_in      => PARTITION_EAST(i-1, j),	 --! Coming from the cell on the left
                        ----------------------------
                        -- SEMENTED BUS I/0  
                        ----------------------------
                        noc_north_out => OPEN,                --! Going to the cell above
                        noc_south_out => NOC_SOUTH(i,j),      --! Going to the cell under
                        noc_east_out  => NOC_EAST(i,j),       --! Going to the cell on the right
                        noc_west_out  => NOC_WEST(i,j),       --! Going to the cell on the left

                        noc_north_in  => IDLE_BUS,            --! Coming from the cell above
                        noc_south_in  => NOC_NORTH(i, j-1),   --! Coming from the cell under
                        noc_east_in   => NOC_WEST(i+1, j),    --! Coming from the cell on the right
                        noc_west_in   => NOC_EAST(i-1, j),    --! Coming from the cell on the left
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- input signals from the left hand side
                        --------------------------------------------------------
                        tb_en    => tb_en_out_array(i, j-1),
                        tb_addrs => tb_addrs_out_array(i, j-1),
                        tb_inp   => tb_inp_out_array(i, j-1),
                        tb_ROW   => tb_ROW_out_array(i, j-1),
                        tb_COL   => tb_COL_out_array(i, j-1),
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- output signals from the right hand side
                        --------------------------------------------------------
                        tb_en_out    => tb_en_out_array(i, j),
                        tb_addrs_out => tb_addrs_out_array(i, j),  --! Write Address from test bench
                        tb_inp_out   => tb_inp_out_array(i, j),
                        tb_ROW_out   => tb_ROW_out_array(i, j),
                        tb_COL_out   => tb_COL_out_array(i, j)
                    );
            END GENERATE;

            if_dimarch_top_r : IF j /= 1 AND j = MAX_ROW AND i = COLUMNS-1 GENERATE
                DiMArchTile_top_r : ENTITY work.DiMArchTile
                    PORT MAP
                    (
                        rst_n => rst_n,
                        clk   => clk,
                        -------------------------
                        -- Address signals
                        -------------------------
                        start_row => '0',                              --! Start signal (connected to the valid signal of the previous block in the same row)
                        start_col => addr_valid_dimarch_right(i, j-1), --! Start signal (connected to the valid signal of the previous block in the same col)
                        prevRow   => row_dimarch_right(i, j-1),        --! Row address assigned to the previous cell
                        prevCol   => col_dimarch_right(i, j-1),        --! Col address assigned to the previous cell
                        valid     => addr_valid_dimarch_right(i, j),   --! Valid signals, used to signal that the assignment of the address is complete
                        thisRow   => row_dimarch_right(i, j),          --! The row address assigned to the cell
                        thisCol   => col_dimarch_right(i, j),          --! The column address assigned to the cell
                        -------------------------
                        -- Crossbar data signals
                        -------------------------
                        data_north_out => OPEN,                  --! Going to cell above
                        data_south_out => DATA_SOUTH(i, j),      --! Going to cell under
                        data_east_out  => OPEN,                  --! Going to cell on the right
                        data_west_out  => DATA_WEST(i, j),       --! Going to cell on the left

                        data_north_in  => (OTHERS => '0'),       --! Coming from cell above
                        data_south_in  => DATA_NORTH(i, j-1),    --! Coming from cell under
                        data_east_in   => (OTHERS => '0'),       --! Coming from cell on the right
                        data_west_in   => DATA_EAST(i-1, j),     --! Coming from cell on the left
                        --------------------------------------------------
                        -- Directions of neighboring buses
                        --------------------------------------------------
                        top_splitter_direction    => (OTHERS => '0'),          --! Coming from the cell above
                        bottom_splitter_direction => SPLITTER_SOUTH(i, j),     --! Going to the cell under
                        right_splitter_direction  => (OTHERS => '0'),          --! Coming from the cell on the right
                        left_splitter_direction   => SPLITTER_WEST(i,j),       --! Going to the cell on the left
                        --------------------------------------------------
                        -- Partition instructions to neighboring buses
                        --------------------------------------------------
                        top_partition_out      => OPEN,	                     --! Going to the cell above
                        bottom_partition_in    => PARTITION_NORTH(i, j-1),   --! Coming from the cell under
                        right_partition_out    => OPEN,                      --! Going to the cell on the right
                        left_partition_in      => PARTITION_EAST(i-1, j),	 --! Coming from the cell on the left
                        ----------------------------
                        -- SEMENTED BUS I/0  
                        ----------------------------
                        noc_north_out => OPEN,                --! Going to the cell above
                        noc_south_out => NOC_SOUTH(i,j),      --! Going to the cell under
                        noc_east_out  => OPEN,                --! Going to the cell on the right
                        noc_west_out  => NOC_WEST(i,j),       --! Going to the cell on the left

                        noc_north_in  => IDLE_BUS,            --! Coming from the cell above
                        noc_south_in  => NOC_NORTH(i, j-1),   --! Coming from the cell under
                        noc_east_in   => IDLE_BUS,            --! Coming from the cell on the right
                        noc_west_in   => NOC_EAST(i-1, j),    --! Coming from the cell on the left
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- input signals from the left hand side
                        --------------------------------------------------------
                        tb_en    => tb_en_out_array(i, j-1),
                        tb_addrs => tb_addrs_out_array(i, j-1),
                        tb_inp   => tb_inp_out_array(i, j-1),
                        tb_ROW   => tb_ROW_out_array(i, j-1),
                        tb_COL   => tb_COL_out_array(i, j-1),
                        --------------------------------------------------------
                        -- SRAM initialization from testbench -- output signals from the right hand side
                        --------------------------------------------------------
                        tb_en_out    => tb_en_out_array(i, j),
                        tb_addrs_out => tb_addrs_out_array(i, j),  --! Write Address from test bench
                        tb_inp_out   => tb_inp_out_array(i, j),
                        tb_ROW_out   => tb_ROW_out_array(i, j),
                        tb_COL_out   => tb_COL_out_array(i, j)
                    );
            END GENERATE;

        END GENERATE DiMArch_ROWS;
    END GENERATE DiMArch_COLS;


END ARCHITECTURE rtl;
