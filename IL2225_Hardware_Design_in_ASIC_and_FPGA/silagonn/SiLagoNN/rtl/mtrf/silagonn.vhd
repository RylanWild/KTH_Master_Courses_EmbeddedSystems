-------------------------------------------------------
--! @file silagonn.vhd
--! @brief SiLago DRRA & DiMArch fabric
--! @details Computational and memory fabric used as the base of the SiLago design.
--! @author Sadiq Hemani
--! @version 2.0
--! @date 2020-02-11
--! @bug NONE
--! @todo Immediate line should be part of the instruction in the future.
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
-- Title      : SiLago DRRA & DiMArch fabric
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : silagonn.vhd
-- Author     : Sadiq Hemani
-- Company    : KTH
-- Created    : 2013-09-05
-- Last update: 2021-09-02
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2013
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2013-09-05  1.0      Sadiq Hemani            Created
-- 2013-09-30  1.0      Nasim Farahini 
-- 2013-11-21  1.0      Sadiq Hemani 
-- 2014-02-10  1.0      Nasim Farahini 
-- 2020-02-11  2.0      Dimitrios Stathis       Added shadow registers
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.seq_functions_package.all;
use work.util_package.all;
use work.top_consts_types_package.all;
use work.noc_types_n_constants.all;
use work.crossbar_types_n_constants.all;

entity silagonn is
  port (
    clk            								: in  std_logic;
    rst_n          								: in  std_logic;
    clk_input      : in  std_logic_vector(COLUMNS - 1 downto 0);
    rst_input      : in  std_logic_vector(COLUMNS - 1 downto 0);
    clk_output     : out std_logic_vector(COLUMNS - 1 downto 0);
    rst_output     : out std_logic_vector(COLUMNS - 1 downto 0);
    instr_ld       								: in  std_logic;
    instr_inp      								: in  std_logic_vector(INSTR_WIDTH - 1 downto 0);
    Immediate      								: in  std_logic;
    seq_address_rb 								: in  std_logic_vector(ROWS - 1 downto 0);
    seq_address_cb 								: in  std_logic_vector(COLUMNS - 1 downto 0);
    --------------------------------------------------------
    --SRAM initialization from testbench
    --------------------------------------------------------
    tb_en                 						: in  std_logic;                                          -- Write Enable from test bench
    tb_addrs              						: in  std_logic_vector(SRAM_ADDRESS_WIDTH - 1 downto 0);  -- Write Address from test bench
    tb_inp                						: in  std_logic_vector(SRAM_WIDTH - 1 downto 0);
    tb_ROW                						: in  unsigned(ROW_WIDTH - 1 downto 0);
    tb_COL                						: in  unsigned(COL_WIDTH - 1 downto 0)
    );
end entity silagonn;

architecture rtl of silagonn is

  ---------------------------------------------
  -- NOC SIGNALS
  ---------------------------------------------

	signal DATA_SOUTH 							: DATA_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW);
	signal DATA_NORTH 							: DATA_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW);
	signal DATA_WEST  							: DATA_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW);
	signal DATA_EAST  							: DATA_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW);
	
    signal NOC_SOUTH 							: INST_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
    signal NOC_NORTH 							: INST_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
	signal NOC_WEST  							: INST_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
	signal NOC_EAST  							: INST_SIGNAL_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
	
  	signal PARTITION_NORTH 						: PARTITION_INSTRUCTION_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);
  	signal PARTITION_EAST  						: PARTITION_INSTRUCTION_TYPE(0 TO COLUMNS - 1, 0 TO MAX_ROW);

  	signal SPLITTER_SOUTH  						: DIRECTION_TYPE(0 TO COLUMNS, 0 TO MAX_ROW);
  	signal SPLITTER_WEST   						: DIRECTION_TYPE(0 TO COLUMNS, 0 TO MAX_ROW);
	
	-- lcc signals 
	
	signal MLFC_CONFIG 							: LOADER_ARRAY_TYPE(COLUMNS - 1 downto 0);
	signal row_sel     							: row_sel_ty;
	
	signal h_bus_reg_seg_0         				: h_bus_seg_ty(0 to 2 * COLUMNS + 1, 0 to 2 * MAX_NR_OF_OUTP_N_HOPS);  --horizontal bus register file output 0
	signal h_bus_reg_seg_1         				: h_bus_seg_ty(0 to 2 * COLUMNS + 1, 0 to 2 * MAX_NR_OF_OUTP_N_HOPS);  --horizontal bus register file output 1
	signal h_bus_dpu_seg_0         				: h_bus_seg_ty(0 to 2 * COLUMNS + 1, 0 to 2 * MAX_NR_OF_OUTP_N_HOPS);  --horizontal bus dpu output 0
	signal h_bus_dpu_seg_1         				: h_bus_seg_ty(0 to 2 * COLUMNS + 1, 0 to 2 * MAX_NR_OF_OUTP_N_HOPS);  --horizontal bus dpu output 1
	signal sel_r_seg               				: s_bus_switchbox_2d_ty(0 to COLUMNS - 1, 0 to ROWS - 1);
	signal v_bus                   				: v_bus_ty_2d(0 to COLUMNS - 1, 0 to ROWS - 1);
	signal noc_bus_out             				: INST_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to ROWS - 1);  -- previous was only 0 to COLUMNS
	signal dimarch_silego_data_in  				: DATA_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to ROWS - 1);
	signal dimarch_silego_data_out 				: DATA_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to ROWS - 1);  -- previous was 0 to ROWS-1
	signal dimarch_silego_rd_out   				: DATA_RD_TYPE(0 to COLUMNS - 1, 0 to 0);  -- previous second argument was 0 to ROWS-1
	
	-------------------------
	-- Address signals
	------------------------- 
	-- DiMArch 
	signal row_dimarch_top						: ROW_ADDR_TYPE(0 to 0, 0 to MAX_ROW - 1);
	signal col_dimarch_top						: COL_ADDR_TYPE(0 to 0, 0 to MAX_ROW - 1);
	signal addr_valid_dimarch_top             	: ADDR_VALID_TYPE(0 to 0, 0 to MAX_ROW - 1);
	signal row_dimarch_right                   	: ROW_ADDR_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW);
	signal col_dimarch_right                    : COL_ADDR_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW );
	signal addr_valid_dimarch_right             : ADDR_VALID_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW );
	signal start_row, start_col					: std_logic; 
	
	 --DRRA
	signal addr_valid_bot   					: ADDR_VALID_TYPE(0 to 0, 0 to ROWS - 2);
	signal addr_valid_right 					: ADDR_VALID_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
	signal addr_valid_top   					: ADDR_VALID_TYPE(0 to 0, 0 to MAX_ROW - 1);
	signal row_bot          					: ROW_ADDR_TYPE(0 to 0, 0 to ROWS - 2);
	signal row_right        					: ROW_ADDR_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
	signal row_top          					: ROW_ADDR_TYPE(0 to 0, 0 to MAX_ROW - 1);
	signal col_bot          					: COL_ADDR_TYPE(0 to 0, 0 to ROWS - 2);
	signal col_right        					: COL_ADDR_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
	signal col_top          					: COL_ADDR_TYPE(0 to 0, 0 to MAX_ROW - 1);
	
	-------------------------
	-- Instruction signals
	-------------------------
	signal instr_ld_right       				: DATA_RD_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
	signal instr_ld_bot         				: DATA_RD_TYPE(0 to 0, 0 to ROWS - 2);
	signal instr_inp_right      				: INSTR_ARRAY_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
	signal instr_inp_bot        				: INSTR_ARRAY_TYPE(0 to 0, 0 to ROWS - 2);
	signal seq_address_rb_right 				: SEQ_ADDR_RB_ARRAY_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
	signal seq_address_rb_bot   				: SEQ_ADDR_RB_ARRAY_TYPE(0 to 0, 0 to ROWS - 2);
	signal seq_address_cb_right 				: SEQ_ADDR_CB_ARRAY_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
	signal seq_address_cb_bot   				: SEQ_ADDR_CB_ARRAY_TYPE(0 to 0, 0 to ROWS - 2);
	
	-------------------------
	-- SRAM testbench signals
	-------------------------
	signal tb_en_out_array         				: DATA_RD_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW );
	signal tb_addrs_out_array      				: SRAM_ADDR_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW );
	signal tb_inp_out_array        				: DATA_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW );
	signal tb_ROW_out_array        				: SRAM_ROW_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW );
	signal tb_COL_out_array        				: SRAM_COL_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW );


begin  -- ARCHITECTURE rtl

  --------------------------------------------------------------------------------------------------
  -- DiMArch
  --------------------------------------------------------------------------------------------------

	inp_assignloop : for i in 0 to COLUMNS -1 generate
        NOC_NORTH(i, 0) <= noc_bus_out(i,0);
        DATA_NORTH(i, 0) <= dimarch_silego_data_out(i, 0);
		dimarch_silego_data_in(i,0) <= DATA_SOUTH(i,1);
	end generate;

    --DiMArch_COLS
	DiMArch_COLS : FOR i IN 0 TO COLUMNS - 1 GENERATE
    	BEGIN

        	--DiMArch_ROWS
        	DiMArch_ROWS : FOR j IN 1 TO MAX_ROW GENERATE
        		BEGIN
            		if_dimarch_bot_l_corner : IF j = 1 AND i = 0 GENERATE
                		DiMArchTile_bot_l_inst : ENTITY work.DiMArchTile_Bot_left_corner
	                    port map
	                    (
	                        rst_n => rst_n,
	                        clk   => clk,
	                        -------------------------
	                        -- Address signals
	                        -------------------------
	                        start_col => addr_valid_top(i, 0) ,                            --! Start signal (connected to the valid signal of the previous block in the same col)
	                        prevRow   => row_top(i, 0),                      --! Row address assigned to the previous cell
	                        prevCol   => col_top(i, 0),                      --! Col address assigned to the previous cell
	                        valid_right     => addr_valid_dimarch_right(i, j), --! Valid signals, used to signal that the assignment of the address is complete
	                        thisRow_right   => row_dimarch_right(i, j),        --! The row address assigned to the cell
	                        thisCol_right   => col_dimarch_right(i, j),        --! The column address assigned to the cell
	                        valid_top     => addr_valid_dimarch_top(i, j), --! Valid signals, used to signal that the assignment of the address is complete
	                        thisRow_top   => row_dimarch_top(i, j),        --! The row address assigned to the cell
	                        thisCol_top   => col_dimarch_top(i, j),        --! The column address assigned to the cell
	                        -------------------------
	                        -- Crossbar data signals
	                        -------------------------
	                        data_north_out => DATA_NORTH(i, j),      --! Going to cell above
	                        data_south_out => DATA_SOUTH(i, j),      --! Going to cell under
	                        data_east_out  => DATA_EAST(i, j),       --! Going to cell on the right
	
	                        data_north_in  => DATA_SOUTH(i, j + 1),  --! Coming from cell above
	                        data_south_in  => DATA_NORTH(i, j-1),    --! Coming from cell under
	                        data_east_in   => DATA_WEST(i+1, j),     --! Coming from cell on the right
	                        --------------------------------------------------
	                        -- Directions of neighboring buses
	                        --------------------------------------------------
	                        top_splitter_direction    => SPLITTER_SOUTH(i, j+1),  --! Coming from the cell above
	                        right_splitter_direction  => SPLITTER_WEST(i+1, j),   --! Coming from the cell on the right
	                        --------------------------------------------------
	                        -- Partition instructions to neighboring buses
	                        --------------------------------------------------
	                        top_partition_out      => PARTITION_NORTH(i, j),	 --! Going to the cell above
	                        right_partition_out    => PARTITION_EAST(i, j),      --! Going to the cell on the right
	                        ----------------------------
	                        -- SEMENTED BUS I/0  
	                        ----------------------------
	                        noc_north_out => NOC_NORTH(i,j),      --! Going to the cell above
	                        noc_east_out  => NOC_EAST(i,j),       --! Going to the cell on the right
	
	                        noc_north_in  => NOC_SOUTH(i, j+1),   --! Coming from the cell above
	                        noc_south_in  => NOC_NORTH(i, j-1),   --! Coming from the cell under
	                        noc_east_in   => NOC_WEST(i+1, j),    --! Coming from the cell on the right
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
					end generate;

					if_dimarch_bot : if j = 1 and i > 0 and i < (COLUMNS-1) generate
        				DiMArchTile_bot_inst : entity work.DiMArchTile_Bot
                    port map
                    (
                        rst_n => rst_n,
                        clk   => clk,
                        -------------------------
                        -- Address signals
                        -------------------------
                        start_row => addr_valid_dimarch_right(i-1, j), --! Start signal (connected to the valid signal of the previous block in the same row)
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
                        right_splitter_direction => SPLITTER_WEST(i+1, j),   --! Coming from the cell on the right
                        left_splitter_direction  => SPLITTER_WEST(i,j),      --! Going to the cell on the left
                        --------------------------------------------------
                        -- Partition instructions to neighboring buses
                        --------------------------------------------------
                        top_partition_out      => PARTITION_NORTH(i, j),	 --! Going to the cell above
                        right_partition_out    => PARTITION_EAST(i, j),      --! Going to the cell on the right
                        left_partition_in      => PARTITION_EAST(i-1, j),	 --! Coming from the cell on the left
                        ----------------------------
                        -- SEMENTED BUS I/0  
                        ----------------------------
                        noc_north_out => NOC_NORTH(i,j),      --! Going to the cell above
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
					end generate;

					if_dimarch_bot_r_corner : if j = 1 and (i = COLUMNS-1) generate
        				DiMArchTile_bot_r_inst : entity work.DiMArchTile_Bot_right_corner
                    port map
                    (
                        rst_n => rst_n,
                        clk   => clk,
                        -------------------------
                        -- Address signals
                        -------------------------
                        start_row => addr_valid_dimarch_right(i-1, j), --! Start signal (connected to the valid signal of the previous block in the same row)
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
                        data_west_out  => DATA_WEST(i, j),       --! Going to cell on the left

                        data_north_in  => DATA_SOUTH(i, j + 1),  --! Coming from cell above
                        data_south_in  => DATA_NORTH(i, j-1),    --! Coming from cell under
                        data_west_in   => DATA_EAST(i-1,j),      --! Coming from cell on the left
                        --------------------------------------------------
                        -- Directions of neighboring buses
                        --------------------------------------------------
                        top_splitter_direction   => SPLITTER_SOUTH(i, j+1),  --! Coming from the cell above
                        left_splitter_direction  => SPLITTER_WEST(i,j),      --! Going to the cell on the left
                        --------------------------------------------------
                        -- Partition instructions to neighboring buses
                        --------------------------------------------------
                        top_partition_out      => PARTITION_NORTH(i, j),	 --! Going to the cell above
                        left_partition_in      => PARTITION_EAST(i-1, j),	 --! Coming from the cell on the left
                        ----------------------------
                        -- SEMENTED BUS I/0  
                        ----------------------------
                        noc_north_out => NOC_NORTH(i,j),      --! Going to the cell above
                        noc_west_out  => NOC_WEST(i,j),       --! Going to the cell on the left

                        noc_north_in  => NOC_SOUTH(i, j+1),   --! Coming from the cell above
                        noc_south_in  => NOC_NORTH(i, j-1),   --! Coming from the cell under
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
					end generate;	

					if_dimarch_top_l_corner : IF j /= 1 AND j = MAX_ROW AND i = 0 GENERATE
        				DiMArchTile_top_l_inst : ENTITY work.DiMArchTile_Top_left_corner
                    port map
                    (
                        rst_n => rst_n,
                        clk   => clk,
                        -------------------------
                        -- Address signals
                        -------------------------
                        start_col => addr_valid_dimarch_top(i, j-1), --! Start signal (connected to the valid signal of the previous block in the same col)
                        prevRow   => row_dimarch_top(i, j-1),        --! Row address assigned to the previous cell
                        prevCol   => col_dimarch_top(i, j-1),        --! Col address assigned to the previous cell
                        valid     => addr_valid_dimarch_right(i, j),   --! Valid signals, used to signal that the assignment of the address is complete
                        thisRow   => row_dimarch_right(i, j),          --! The row address assigned to the cell
                        thisCol   => col_dimarch_right(i, j),          --! The column address assigned to the cell
                        -------------------------
                        -- Crossbar data signals
                        -------------------------
                        data_south_out => DATA_SOUTH(i, j),      --! Going to cell under
                        data_east_out  => DATA_EAST(i, j),       --! Going to cell on the right

                        data_south_in  => DATA_NORTH(i, j-1),    --! Coming from cell under
                        data_east_in   => DATA_WEST(i+1, j),     --! Coming from cell on the right
                        --------------------------------------------------
                        -- Directions of neighboring buses
                        --------------------------------------------------
                        bottom_splitter_direction => SPLITTER_SOUTH(i, j),     --! Going to the cell under
                        right_splitter_direction  => SPLITTER_WEST(i+1, j),    --! Coming from the cell on the right
                        --------------------------------------------------
                        -- Partition instructions to neighboring buses
                        --------------------------------------------------
                        bottom_partition_in    => PARTITION_NORTH(i, j-1),   --! Coming from the cell under
                        right_partition_out    => PARTITION_EAST(i, j),      --! Going to the cell on the right
                        ----------------------------
                        -- SEMENTED BUS I/0  
                        ----------------------------
                        noc_south_out => NOC_SOUTH(i,j),      --! Going to the cell under
                        noc_east_out  => NOC_EAST(i,j),       --! Going to the cell on the right

                        noc_south_in  => NOC_NORTH(i, j-1),   --! Coming from the cell under
                        noc_east_in   => NOC_WEST(i+1, j),    --! Coming from the cell on the right
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
					end generate;
           
					if_dimarch_top : if j /= 1 and j = MAX_ROW and i > 0 and i < (COLUMNS-1) generate
        				DiMArchTile_top_inst : entity work.DiMArchTile_Top
                    port map
                    (
                        rst_n => rst_n,
                        clk   => clk,
                        -------------------------
                        -- Address signals
                        -------------------------
                        start_col => addr_valid_dimarch_right(i, j-1), --! Start signal (connected to the valid signal of the previous block in the same col)
                        prevRow   => row_dimarch_right(i, j-1),        --! Row address assigned to the previous cell
                        prevCol   => col_dimarch_right(i, j-1),        --! Col address assigned to the previous cell
                        valid     => addr_valid_dimarch_right(i, j),   --! Valid signals, used to signal that the assignment of the address is complete
                        thisRow   => row_dimarch_right(i, j),          --! The row address assigned to the cell
                        thisCol   => col_dimarch_right(i, j),          --! The column address assigned to the cell
                        -------------------------
                        -- Crossbar data signals
                        -------------------------
                        data_south_out => DATA_SOUTH(i, j),      --! Going to cell under
                        data_east_out  => DATA_EAST(i, j),       --! Going to cell on the right
                        data_west_out  => DATA_WEST(i, j),       --! Going to cell on the left

                        data_south_in  => DATA_NORTH(i, j-1),    --! Coming from cell under
                        data_east_in   => DATA_WEST(i+1, j),     --! Coming from cell on the right
                        data_west_in   => DATA_EAST(i-1, j),     --! Coming from cell on the left
                        --------------------------------------------------
                        -- Directions of neighboring buses
                        --------------------------------------------------
                        bottom_splitter_direction => SPLITTER_SOUTH(i, j),     --! Going to the cell under
                        right_splitter_direction  => SPLITTER_WEST(i+1, j),    --! Coming from the cell on the right
                        left_splitter_direction   => SPLITTER_WEST(i,j),       --! Going to the cell on the left
                        --------------------------------------------------
                        -- Partition instructions to neighboring buses
                        bottom_partition_in    => PARTITION_NORTH(i, j-1),   --! Coming from the cell under
                        right_partition_out    => PARTITION_EAST(i, j),      --! Going to the cell on the right
                        left_partition_in      => PARTITION_EAST(i-1, j),	 --! Coming from the cell on the left
                        ----------------------------
                        -- SEMENTED BUS I/0  
                        ----------------------------
                        noc_south_out => NOC_SOUTH(i,j),      --! Going to the cell under
                        noc_east_out  => NOC_EAST(i,j),       --! Going to the cell on the right
                        noc_west_out  => NOC_WEST(i,j),       --! Going to the cell on the left

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

					if_dimarch_top_r_corner : if j /= 1 and j=MAX_ROW and i = COLUMNS-1  generate
        				DiMArchTile_top_r_inst : entity work.DiMArchTile_Top_right_corner
                    port map
                    (
                        rst_n => rst_n,
                        clk   => clk,
                        -------------------------
                        -- Address signals
                        -------------------------
                        start_col => addr_valid_dimarch_right(i, j-1), --! Start signal (connected to the valid signal of the previous block in the same col)
                        prevRow   => row_dimarch_right(i, j-1),        --! Row address assigned to the previous cell
                        prevCol   => col_dimarch_right(i, j-1),        --! Col address assigned to the previous cell
                        valid     => addr_valid_dimarch_right(i, j),   --! Valid signals, used to signal that the assignment of the address is complete
                        thisRow   => row_dimarch_right(i, j),          --! The row address assigned to the cell
                        thisCol   => col_dimarch_right(i, j),          --! The column address assigned to the cell
                        -------------------------
                        -- Crossbar data signals
                        -------------------------
                        data_south_out => DATA_SOUTH(i, j),      --! Going to cell under
                        data_west_out  => DATA_WEST(i, j),       --! Going to cell on the left

                        data_south_in  => DATA_NORTH(i, j-1),    --! Coming from cell under
                        data_west_in   => DATA_EAST(i-1, j),     --! Coming from cell on the left
                        --------------------------------------------------
                        -- Directions of neighboring buses
                        --------------------------------------------------
                        bottom_splitter_direction => SPLITTER_SOUTH(i, j),     --! Going to the cell under
                        left_splitter_direction   => SPLITTER_WEST(i,j),       --! Going to the cell on the left
                        --------------------------------------------------
                        -- Partition instructions to neighboring buses
                        --------------------------------------------------
                        bottom_partition_in    => PARTITION_NORTH(i, j-1),   --! Coming from the cell under
                        left_partition_in      => PARTITION_EAST(i-1, j),	 --! Coming from the cell on the left
                        ----------------------------
                        -- SEMENTED BUS I/0  
                        ----------------------------
                        noc_south_out => NOC_SOUTH(i,j),      --! Going to the cell under
                        noc_west_out  => NOC_WEST(i,j),       --! Going to the cell on the left

                        noc_south_in  => NOC_NORTH(i, j-1),   --! Coming from the cell under
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
					end generate;
	
    			end generate DiMArch_ROWS;
  		end generate DiMArch_COLS;

  MTRF_COLS : for i in 0 to COLUMNS - 1 generate
  begin
    MTRF_ROWS : for j in 0 to ROWS - 1 generate

    begin

      if_drra_top_l_corner : if j = 0 and i = 0 generate  -- top row, corners
        Silago_top_l_corner_inst : entity work.Silago_top_left_corner
          port map(
            clk       => clk,
            rst_n     => rst_n,
            ----------------------------------------------------
            -- REV 2 2020-02-11 --------------------------------
            ----------------------------------------------------
            -------------------------
            -- Pass-through clock and reset signals
            -------------------------
            -- clk_input  => clk_input_drra(i, j),    --! Propagation signal clk input 
            -- rst_input  => rst_input_drra(i, j),    --! Propagation signal rst input
            -- clk_output => clk_input_dimarch(i, j), --! Propagation signal clk output 
            -- rst_output => rst_input_dimarch(i, j), --! Propagation signal rst output
            Immediate => Immediate,
            ----------------------------------------------------
            -- End of modification REV 2 -----------------------
            ----------------------------------------------------

            -------------------------
            -- Address signals
            -------------------------
            valid_top   => addr_valid_top(i, j),  --! Valid signals, used to signal that the assignment of the address is complete
            thisRow_top => row_top(i, j),         --! The row address assigned to the cell
            thisCol_top => col_top(i, j),         --! The column address assigned to the cell

            valid_right   => addr_valid_right(i, j),  --! Valid signals, used to signal that the assignment of the address is complete
            thisRow_right => row_right(i, j),         --! The row address assigned to the cell
            thisCol_right => col_right(i, j),         --! The column address assigned to the cell

            valid_bot                  => addr_valid_bot(i, j),  --! Copy of the valid signal, connection to the bottom row
            thisRow_bot                => row_bot(i, j),  --! Copy of the row signal, connection to the bottom row
            thisCol_bot                => col_bot(i, j),  --! Copy of the col signal, connection to the bottom row
            ------------------------------
            -- Data in (from next row)
            ------------------------------
            data_in_next               => dimarch_silego_data_out(i, j + 1),  --! data from other row
            dimarch_silego_rd_out_next => dimarch_silego_rd_out(i, 0),        --! ready signal from the other row

            ------------------------------
            -- Data out to DiMArch
            ------------------------------
            dimarch_data_in_out => dimarch_silego_data_in(i, j + 1),  --! data from DiMArch to the next row

            ------------------------------
            -- Global signals for configuration
            ------------------------------
            -- inputs (left hand side)
            instr_ld                 => instr_ld,              --! load instruction signal
            instr_inp                => instr_inp,             --! Actual instruction to be loaded
            seq_address_rb           => seq_address_rb,        --! in order to generate addresses for sequencer rows
            seq_address_cb           => seq_address_cb,        --! in order to generate addresses for sequencer cols
            -- outputs (right hand side)
            instr_ld_out_right       => instr_ld_right(i, j),  --! Registered instruction load signal, broadcast to the next cell
            instr_inp_out_right      => instr_inp_right(i, j),  --! Registered instruction signal, bradcast to the next cell
            seq_address_rb_out_right => seq_address_rb_right(i, j),  --! registered signal, broadcast to the next cell, in order to generate addresses for sequencer rows
            seq_address_cb_out_right => seq_address_cb_right(i, j),  --! registed signal, broadcast to the next cell, in order to generate addresses for sequencer cols

            instr_ld_out_bot           => instr_ld_bot(i, j),  --! Registered instruction load signal, broadcast to the next cell
            instr_inp_out_bot          => instr_inp_bot(i, j),  --! Registered instruction signal, bradcast to the next cell
            seq_address_rb_out_bot     => seq_address_rb_bot(i, j),  --! registered signal, broadcast to the next cell, in order to generate addresses for sequencer rows
            seq_address_cb_out_bot     => seq_address_cb_bot(i, j),  --! registed signal, broadcast to the next cell, in order to generate addresses for sequencer cols
            ------------------------------
            -- Silego core cell
            ------------------------------
            --RegFile
            -- Data transfer only allowed through the dimarch
            dimarch_data_in            => dimarch_silego_data_in(i, j),   --! data from dimarch (top)
            dimarch_data_out           => dimarch_silego_data_out(i, j),  --! data out to dimarch (top)
            ------------------------------
            -- DiMArch bus output
            ------------------------------
            noc_bus_out                => noc_bus_out(i, j),   --! noc bus signal to the dimarch (top)
            ------------------------------
            -- NoC bus from the next row to the DiMArch
            ------------------------------
            -- TODO we can move the noc bus selector from the DiMArch to the cell in order to save some routing
            noc_bus_in                 => noc_bus_out(i, j + 1),     --! noc bus signal from the adjacent row (bottom)
            ------------------------------
            --Horizontal Busses
            ------------------------------
            ---------------------------------------------------------------------------------------
            -- Modified by Dimitris to remove inputs and outputs that are not connected (left hand side)
            -- Date 15/03/2018
            ---------------------------------------------------------------------------------------
            --Horizontal Busses
            h_bus_reg_in_out0_3_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 3),
            h_bus_reg_in_out0_4_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 4),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),
            h_bus_reg_in_out1_3_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 3),
            h_bus_reg_in_out1_4_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 4),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),
            h_bus_dpu_in_out0_3_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out0_4_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),
            h_bus_dpu_in_out1_3_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out1_4_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            --sel_r_ext_in               
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            --ext_v_input_bus_in        =>    
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            --sel_r_ext_out             =>    
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            --ext_v_input_bus_out       =>    
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

      if_drra_top : if j = 0 and i > 0 and i < (COLUMNS - 1) generate  -- top row, non-corner case
        Silago_top_inst : entity work.Silago_top
          port map(
            clk                        => clk,
            rst_n                      => rst_n,
            ----------------------------------------------------
            -- REV 2 2020-02-11 --------------------------------
            ----------------------------------------------------
            -------------------------
            -- Pass-through clock and reset signals
            -------------------------
            -- clk_input  => clk_input_drra(i, j),    --! Propagation signal clk input 
            -- rst_input  => rst_input_drra(i, j),    --! Propagation signal rst input
            -- clk_output => clk_input_dimarch(i, j), --! Propagation signal clk output 
            -- rst_output => rst_input_dimarch(i, j), --! Propagation signal rst output
            Immediate                  => Immediate,
            ----------------------------------------------------
            -- End of modification REV 2 -----------------------
            ----------------------------------------------------
            -- Address signals
            -------------------------
            start_row                  => addr_valid_right(i - 1, j),  --! Start signal (connected to the valid signal of the previous block in the same row) 
            prevRow                    => row_right(i - 1, j),  --! Row address assigned to the previous cell                     
            prevCol                    => col_right(i - 1, j),  --! Col address assigned to the previous cell                     
            valid                      => addr_valid_right(i, j),  --! Valid signals, used to signal that the assignment of the address is complete       
            thisRow                    => row_right(i, j),  --! The row address assigned to the cell                          
            thisCol                    => col_right(i, j),  --! The column address assigned to the cell                       
            ------------------------------
            -- Data in (from next row)
            ------------------------------
            data_in_next               => dimarch_silego_data_out(i, j + 1),  --! data from other row   
            dimarch_silego_rd_out_next => dimarch_silego_rd_out(i, 0),  --! ready signal from the other row         

            ------------------------------
            -- Data out to DiMArch
            ------------------------------
            dimarch_data_in_out => dimarch_silego_data_in(i, j + 1),  --! data from DiMArch to the next row 

            ------------------------------
            -- Global signals for configuration
            ------------------------------
            -- inputs (left hand side)
            instr_ld                   => instr_ld_right(i - 1, j),  --! load instruction signal                                                                                                     
            instr_inp                  => instr_inp_right(i - 1, j),  --! Actual instruction to be loaded                                                            
            seq_address_rb             => seq_address_rb_right(i - 1, j),  --! in order to generate addresses for sequencer rows                                                 
            seq_address_cb             => seq_address_cb_right(i - 1, j),  --! in order to generate addresses for sequencer cols                                              
            -- outputs (right hand side)
            instr_ld_out               => instr_ld_right(i, j),  --! Registered instruction load signal, broadcast to the next cell                                                              
            instr_inp_out              => instr_inp_right(i, j),  --! Registered instruction signal, bradcast to the next cell                                   
            seq_address_rb_out         => seq_address_rb_right(i, j),  --! registered signal, broadcast to the next cell, in order to generate addresses for sequencer rows  
            seq_address_cb_out         => seq_address_cb_right(i, j),  --! registed signal, broadcast to the next cell, in order to generate addresses for sequencer cols 
            ------------------------------
            -- Silego core cell
            ------------------------------
            --RegFile
            -- Data transfer only allowed through the dimarch
            dimarch_data_in            => dimarch_silego_data_in(i, j),    --! data from dimarch (top)
            dimarch_data_out           => dimarch_silego_data_out(i, j),   --! data out to dimarch (top)
            ------------------------------
            -- DiMArch bus output
            ------------------------------
            noc_bus_out                => noc_bus_out(i, j),     --! noc bus signal to the dimarch (top)
            ------------------------------
            -- NoC bus from the next row to the DiMArch
            ------------------------------
            -- TODO we can move the noc bus selector from the DiMArch to the cell in order to save some routing
            noc_bus_in                 => noc_bus_out(i, j + 1),  --! noc bus signal from the adjacent row (bottom)                          
            ------------------------------
            --Horizontal Busses
            ------------------------------
            --Horizontal Busses
            h_bus_reg_in_out0_0_left   => h_bus_reg_seg_0(2 * i + j, 0),   -- h_bus_reg_seg_0(i+1,0) ,
            h_bus_reg_in_out0_1_left   => h_bus_reg_seg_0(2 * i + j, 1),   --h_bus_reg_seg_0(i+1,1),
            h_bus_reg_in_out0_3_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 3),
            h_bus_reg_in_out0_4_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 4),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),
            h_bus_reg_in_out1_0_left   => h_bus_reg_seg_1(2 * i + j, 0),
            h_bus_reg_in_out1_1_left   => h_bus_reg_seg_1(2 * i + j, 1),
            h_bus_reg_in_out1_3_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 3),
            h_bus_reg_in_out1_4_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 4),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),

            h_bus_dpu_in_out0_0_left   => h_bus_dpu_seg_0(2 * i + j, 0),
            h_bus_dpu_in_out0_1_left   => h_bus_dpu_seg_0(2 * i + j, 1),
            h_bus_dpu_in_out0_3_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out0_4_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),
            h_bus_dpu_in_out1_0_left   => h_bus_dpu_seg_1(2 * i + j, 0),
            h_bus_dpu_in_out1_1_left   => h_bus_dpu_seg_1(2 * i + j, 1),
            h_bus_dpu_in_out1_3_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out1_4_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            --sel_r_ext_in               
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            --ext_v_input_bus_in        =>    
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            --sel_r_ext_out             =>    
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            --ext_v_input_bus_out       =>    
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

      if_drra_top_r_corner : if j = 0 and i = COLUMNS - 1 generate     -- top row, corners
        Silago_top_r_corner_inst : entity work.Silago_top_right_corner
          port map(
            clk                        => clk,
            rst_n                      => rst_n,
            ----------------------------------------------------
            -- REV 2 2020-02-11 --------------------------------
            ----------------------------------------------------
            -------------------------
            -- Pass-through clock and reset signals
            -------------------------
            -- clk_input  => clk_input_drra(i, j),    --! Propagation signal clk input 
            -- rst_input  => rst_input_drra(i, j),    --! Propagation signal rst input
            -- clk_output => clk_input_dimarch(i, j), --! Propagation signal clk output 
            -- rst_output => rst_input_dimarch(i, j), --! Propagation signal rst output
            Immediate                  => Immediate,
            ----------------------------------------------------
            -- End of modification REV 2 -----------------------
            ----------------------------------------------------
            -------------------------
            -- Address signals
            -------------------------
            start_row                  => addr_valid_right(i - 1, j),  --! Start signal (connected to the valid signal of the previous block in the same row) 
            --start_col       => '0', --! Start signal (connected to the valid signal of the previous block in the same col) 
            prevRow                    => row_right(i - 1, j),  --! Row address assigned to the previous cell                     
            prevCol                    => col_right(i - 1, j),  --! Col address assigned to the previous cell 
            ------------------------------
            -- Data in (from next row)
            ------------------------------
            data_in_next               => dimarch_silego_data_out(i, j + 1),  --! data from other row
            dimarch_silego_rd_out_next => dimarch_silego_rd_out(i, 0),        --! ready signal from the other row

            ------------------------------
            -- Data out to DiMArch
            ------------------------------
            dimarch_data_in_out => dimarch_silego_data_in(i, j + 1),  --! data from DiMArch to the next row

            ------------------------------
            -- Global signals for configuration
            ------------------------------
            -- inputs (left hand side)
            instr_ld                   => instr_ld_right(i - 1, j),  --! load instruction signal                                                                                                     
            instr_inp                  => instr_inp_right(i - 1, j),  --! Actual instruction to be loaded                                                            
            seq_address_rb             => seq_address_rb_right(i - 1, j),  --! in order to generate addresses for sequencer rows                                                 
            seq_address_cb             => seq_address_cb_right(i - 1, j),  --! in order to generate addresses for sequencer cols 
            ------------------------------
            -- Silego core cell
            ------------------------------
            --RegFile
            -- Data transfer only allowed through the dimarch
            dimarch_data_in            => dimarch_silego_data_in(i, j),    --! data from dimarch (top)
            dimarch_data_out           => dimarch_silego_data_out(i, j),   --! data out to dimarch (top)
            ------------------------------
            -- DiMArch bus output
            ------------------------------
            noc_bus_out                => noc_bus_out(i, j),         --! noc bus signal to the dimarch (top)
            ------------------------------
            -- NoC bus from the next row to the DiMArch
            ------------------------------
            -- TODO we can move the noc bus selector from the DiMArch to the cell in order to save some routing
            noc_bus_in                 => noc_bus_out(i, j + 1),     --! noc bus signal from the adjacent row (bottom)
            ------------------------------
            --Horizontal Busses
            ------------------------------
            ---------------------------------------------------------------------------------------
            -- Modified by Dimitris to remove inputs and outputs that are not connected (left hand side)
            -- Date 15/03/2018
            ---------------------------------------------------------------------------------------
            --Horizontal Busses
            h_bus_reg_in_out0_0_left   => h_bus_reg_seg_0(2 * i + j, 0),
            h_bus_reg_in_out0_1_left   => h_bus_reg_seg_0(2 * i + j, 1),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),

            h_bus_reg_in_out1_0_left   => h_bus_reg_seg_1(2 * i + j, 0),
            h_bus_reg_in_out1_1_left   => h_bus_reg_seg_1(2 * i + j, 1),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),

            h_bus_dpu_in_out0_0_left   => h_bus_dpu_seg_0(2 * i + j, 0),
            h_bus_dpu_in_out0_1_left   => h_bus_dpu_seg_0(2 * i + j, 1),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),

            h_bus_dpu_in_out1_0_left   => h_bus_dpu_seg_1(2 * i + j, 0),
            h_bus_dpu_in_out1_1_left   => h_bus_dpu_seg_1(2 * i + j, 1),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            --sel_r_ext_in               
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            --ext_v_input_bus_in        =>    
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            --sel_r_ext_out             =>    
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            --ext_v_input_bus_out       =>    
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

      if_drra_bot_l_corner : if j = (ROWS - 1) and i = 0 generate  -- bottom row, corner case
        Silago_bot_l_corner_inst : entity work.Silago_bot_left_corner
          port map(
            clk       => clk,
            rst_n     => rst_n,
            ----------------------------------------------------
            -- REV 2 2020-02-11 --------------------------------
            ----------------------------------------------------
            -------------------------
            -- Pass-through clock and reset signals
            -------------------------
            -- clk_input  => clk_input_drra(i, j),    --! Propagation signal clk input 
            -- rst_input  => rst_input_drra(i, j),    --! Propagation signal rst input
            -- clk_output => clk_input_dimarch(i, j), --! Propagation signal clk output 
            -- rst_output => rst_input_dimarch(i, j), --! Propagation signal rst output
            Immediate => Immediate,
            ----------------------------------------------------
            -- End of modification REV 2 -----------------------
            ----------------------------------------------------

            -------------------------
            -- Address signals
            -------------------------
            --start_row               => '0', --! Start signal (connected to the valid signal of the previous block in the same row)
            start_col        => addr_valid_bot(i, j - 1),  --! Start signal (connected to the valid signal of the previous block in the same col)
            prevRow          => row_bot(i, j - 1),       --! Row address assigned to the previous cell
            prevCol          => col_bot(i, j - 1),       --! Col address assigned to the previous cell
            valid            => addr_valid_right(i, j),  --! Valid signals, used to signal that the assignment of the address is complete
            thisRow          => row_right(i, j),         --! The row address assigned to the cell
            thisCol          => col_right(i, j),         --! The column address assigned to the cell
            ------------------------------
            -- Data in (from next row)
            ------------------------------
            -- TODO In this version we have removed the incoming connections from the top row, if a DiMArch is connected to the bottom row also a better scheme needs to be decided
            --    data_in_next                 : in  STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data from other row
            --    dimarch_silego_rd_2_out_next : in  std_logic; --! ready signal from the other row
            ------------------------------
            -- Data in (to next row)
            ------------------------------
            dimarch_rd_out   => dimarch_silego_rd_out(i, 0),    --! ready signal to the adjacent row (top)
            dimarch_data_out => dimarch_silego_data_out(i, j),  --! data out to the adjacent row (top)

            ------------------------------
            -- Global signals for configuration
            ------------------------------
            -- inputs
            instr_ld           => instr_ld_bot(i, j - 1),      --! load instruction signal
            instr_inp          => instr_inp_bot(i, j - 1),     --! Actual instruction to be loaded
            seq_address_rb     => seq_address_rb_bot(i, j - 1),  --! in order to generate addresses for sequencer rows
            seq_address_cb     => seq_address_cb_bot(i, j - 1),  --! in order to generate addresses for sequencer cols
            -- outputs
            instr_ld_out       => instr_ld_right(i, j),  --! Registered instruction load signal, broadcast to the next cell
            instr_inp_out      => instr_inp_right(i, j),  --! Registered instruction signal, bradcast to the next cell
            seq_address_rb_out => seq_address_rb_right(i, j),  --! registered signal, broadcast to the next cell, in order to generate addresses for sequencer rows
            seq_address_cb_out => seq_address_cb_right(i, j),  --! registed signal, broadcast to the next cell, in order to generate addresses for sequencer cols

            ------------------------------
            -- Silego core cell
            ------------------------------

            -----------------------------
            -- DiMArch data
            -----------------------------
            dimarch_data_in            => dimarch_silego_data_in(i, j),  --! data from dimarch (through the adjacent cell) (top)
            -- TODO this signal has been removed in this version, if a DiMArch is connected to the bottom row also we need a better shceme
            noc_bus_out                => noc_bus_out(i, j),  --! NoC bus signal to the adjacent row (top), to be propagated to the DiMArch
            -----------------------------
            --Horizontal Busses
            -----------------------------
            ---------------------------------------------------------------------------------------
            -- Modified by Dimitris to remove inputs and outputs that are not connected (left hand side)
            -- Date 15/03/2018
            ---------------------------------------------------------------------------------------
            h_bus_reg_in_out0_3_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 3),
            h_bus_reg_in_out0_4_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 4),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),

            h_bus_reg_in_out1_3_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 3),
            h_bus_reg_in_out1_4_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 4),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),

            h_bus_dpu_in_out0_3_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out0_4_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),

            h_bus_dpu_in_out1_3_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out1_4_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

      if_drra_bot : if j = (ROWS - 1) and i > 0 and i < (COLUMNS - 1) generate  -- bottom row, non-corner case
        Silago_bot_inst : entity work.Silago_bot
          port map(
            clk              => clk,
            rst_n            => rst_n,
            ----------------------------------------------------
            -- REV 2 2020-02-11 --------------------------------
            ----------------------------------------------------
            -------------------------
            -- Pass-through clock and reset signals
            -------------------------
            -- clk_input  => clk_input_drra(i, j),    --! Propagation signal clk input 
            -- rst_input  => rst_input_drra(i, j),    --! Propagation signal rst input
            -- clk_output => clk_input_dimarch(i, j), --! Propagation signal clk output 
            -- rst_output => rst_input_dimarch(i, j), --! Propagation signal rst output
            Immediate        => Immediate,
            ----------------------------------------------------
            -- End of modification REV 2 -----------------------
            ----------------------------------------------------
            -------------------------
            -- Address signals
            -------------------------
            start_row        => addr_valid_right(i - 1, j),  --! Start signal (connected to the valid signal of the previous block in the same row) 
            --start_col       => '0', --! Start signal (connected to the valid signal of the previous block in the same col) 
            prevRow          => row_right(i - 1, j),  --! Row address assigned to the previous cell                     
            prevCol          => col_right(i - 1, j),  --! Col address assigned to the previous cell                     
            valid            => addr_valid_right(i, j),  --! Valid signals, used to signal that the assignment of the address is complete       
            thisRow          => row_right(i, j),      --! The row address assigned to the cell                          
            thisCol          => col_right(i, j),      --! The column address assigned to the cell  
            ------------------------------
            -- Data in (from next row)
            ------------------------------
            -- TODO In this version we have removed the incoming connections from the top row, if a DiMArch is connected to the bottom row also a better scheme needs to be decided
            --    data_in_next                 : in  STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data from other row
            --    dimarch_silego_rd_2_out_next : in  std_logic; --! ready signal from the other row
            ------------------------------
            -- Data in (to next row)
            ------------------------------
            dimarch_rd_out   => dimarch_silego_rd_out(i, 0),  --! ready signal to the adjacent row (top)
            dimarch_data_out => dimarch_silego_data_out(i, j),                  --! data out to the adjacent row (top)

            ------------------------------
            -- Global signals for configuration
            ------------------------------
            -- inputs (left hand side)
            instr_ld                   => instr_ld_right(i - 1, j),  --! load instruction signal                                                                                                     
            instr_inp                  => instr_inp_right(i - 1, j),  --! Actual instruction to be loaded                                                            
            seq_address_rb             => seq_address_rb_right(i - 1, j),  --! in order to generate addresses for sequencer rows                                                 
            seq_address_cb             => seq_address_cb_right(i - 1, j),  --! in order to generate addresses for sequencer cols                                              
            -- outputs (right hand side)
            instr_ld_out               => instr_ld_right(i, j),  --! Registered instruction load signal, broadcast to the next cell                                                              
            instr_inp_out              => instr_inp_right(i, j),  --! Registered instruction signal, bradcast to the next cell                                   
            seq_address_rb_out         => seq_address_rb_right(i, j),  --! registered signal, broadcast to the next cell, in order to generate addresses for sequencer rows  
            seq_address_cb_out         => seq_address_cb_right(i, j),  --! registed signal, broadcast to the next cell, in order to generate addresses for sequencer cols 
            ------------------------------
            -- Silego core cell
            ------------------------------
            --RegFile
            -----------------------------
            -- DiMArch data
            -----------------------------
            dimarch_data_in            => dimarch_silego_data_in(i, j),  --! data from dimarch (through the adjacent cell) (top)
            -- TODO this signal has been removed in this version, if a DiMArch is connected to the bottom row also we need a better shceme
            --    dimarch_data_out             : out STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data out to dimarch (bot)
            -- DiMArch bus output
            noc_bus_out                => noc_bus_out(i, j),  --! NoC bus signal to the adjacent row (top), to be propagated to the DiMArch
            -----------------------------
            --Horizontal Busses
            -----------------------------
            --Horizontal Busses
            h_bus_reg_in_out0_0_left   => h_bus_reg_seg_0(2 * i + j, 0),   -- h_bus_reg_seg_0(i+1,0) ,
            h_bus_reg_in_out0_1_left   => h_bus_reg_seg_0(2 * i + j, 1),   --h_bus_reg_seg_0(i+1,1),
            h_bus_reg_in_out0_3_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 3),
            h_bus_reg_in_out0_4_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 4),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),
            h_bus_reg_in_out1_0_left   => h_bus_reg_seg_1(2 * i + j, 0),
            h_bus_reg_in_out1_1_left   => h_bus_reg_seg_1(2 * i + j, 1),
            h_bus_reg_in_out1_3_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 3),
            h_bus_reg_in_out1_4_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 4),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),

            h_bus_dpu_in_out0_0_left   => h_bus_dpu_seg_0(2 * i + j, 0),
            h_bus_dpu_in_out0_1_left   => h_bus_dpu_seg_0(2 * i + j, 1),
            h_bus_dpu_in_out0_3_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out0_4_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),
            h_bus_dpu_in_out1_0_left   => h_bus_dpu_seg_1(2 * i + j, 0),
            h_bus_dpu_in_out1_1_left   => h_bus_dpu_seg_1(2 * i + j, 1),
            h_bus_dpu_in_out1_3_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out1_4_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            --sel_r_ext_in               
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            --ext_v_input_bus_in        =>    
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            --sel_r_ext_out             =>    
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            --ext_v_input_bus_out       =>    
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

      if_drra_bot_r_corner : if j = (ROWS - 1) and i = COLUMNS - 1 generate  -- bottom row, corner case
        Silago_bot_r_corner_inst : entity work.Silago_bot_right_corner
          port map(
            clk       => clk,
            rst_n     => rst_n,
            ----------------------------------------------------
            -- REV 2 2020-02-11 --------------------------------
            ----------------------------------------------------
            -------------------------
            -- Pass-through clock and reset signals
            -------------------------
            -- clk_input  => clk_input_drra(i, j),    --! Propagation signal clk input 
            -- rst_input  => rst_input_drra(i, j),    --! Propagation signal rst input
            -- clk_output => clk_input_dimarch(i, j), --! Propagation signal clk output 
            -- rst_output => rst_input_dimarch(i, j), --! Propagation signal rst output
            Immediate => Immediate,
            ----------------------------------------------------
            -- End of modification REV 2 -----------------------
            ----------------------------------------------------

            -------------------------
            -- Address signals
            -------------------------
            start_row        => addr_valid_right(i - 1, j),  --! Start signal (connected to the valid signal of the previous block in the same row) 
            --start_col       => '0', --! Start signal (connected to the valid signal of the previous block in the same col) 
            prevRow          => row_right(i - 1, j),         --! Row address assigned to the previous cell
            prevCol          => col_right(i - 1, j),         --! Col address assigned to the previous cell
            ------------------------------
            -- Data in (from next row)
            ------------------------------
            -- TODO In this version we have removed the incoming connections from the top row, if a DiMArch is connected to the bottom row also a better scheme needs to be decided
            --    data_in_next                 : in  STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data from other row
            --    dimarch_silego_rd_2_out_next : in  std_logic; --! ready signal from the other row
            ------------------------------
            -- Data in (to next row)
            ------------------------------
            dimarch_rd_out   => dimarch_silego_rd_out(i, 0),    --! ready signal to the adjacent row (top)
            dimarch_data_out => dimarch_silego_data_out(i, j),  --! data out to the adjacent row (top)

            ------------------------------
            -- Global signals for configuration
            ------------------------------
            -- inputs
            instr_ld       => instr_ld_right(i - 1, j),  --! load instruction signal                                                                                                     
            instr_inp      => instr_inp_right(i - 1, j),  --! Actual instruction to be loaded                                                            
            seq_address_rb => seq_address_rb_right(i - 1, j),  --! in order to generate addresses for sequencer rows                                                 
            seq_address_cb => seq_address_cb_right(i - 1, j),  --! in order to generate addresses for sequencer cols 

            ------------------------------
            -- Silego core cell
            ------------------------------

            -----------------------------
            -- DiMArch data
            -----------------------------
            dimarch_data_in            => dimarch_silego_data_in(i, j),  --! data from dimarch (through the adjacent cell) (top)
            -- TODO this signal has been removed in this version, if a DiMArch is connected to the bottom row also we need a better shceme
            --    dimarch_data_out             : out STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data out to dimarch (bot)
            -- DiMArch bus output
            noc_bus_out                => noc_bus_out(i, j),  --! NoC bus signal to the adjacent row (top), to be propagated to the DiMArch
            -----------------------------
            --Horizontal Busses
            -----------------------------
            ---------------------------------------------------------------------------------------
            -- Modified by Dimitris to remove inputs and outputs that are not connected (left hand side)
            -- Date 15/03/2018
            ---------------------------------------------------------------------------------------
            --Horizontal Busses
            h_bus_reg_in_out0_0_left   => h_bus_reg_seg_0(2 * i + j, 0),
            h_bus_reg_in_out0_1_left   => h_bus_reg_seg_0(2 * i + j, 1),
            --h_bus_reg_in_out0_3_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 3),
            --h_bus_reg_in_out0_4_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 4),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),

            h_bus_reg_in_out1_0_left   => h_bus_reg_seg_1(2 * i + j, 0),
            h_bus_reg_in_out1_1_left   => h_bus_reg_seg_1(2 * i + j, 1),
            --h_bus_reg_in_out1_3_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 3),
            --h_bus_reg_in_out1_4_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 4),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),

            h_bus_dpu_in_out0_0_left   => h_bus_dpu_seg_0(2 * i + j, 0),
            h_bus_dpu_in_out0_1_left   => h_bus_dpu_seg_0(2 * i + j, 1),
            --h_bus_dpu_in_out0_3_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 3),
            --h_bus_dpu_in_out0_4_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),

            h_bus_dpu_in_out1_0_left   => h_bus_dpu_seg_1(2 * i + j, 0),
            h_bus_dpu_in_out1_1_left   => h_bus_dpu_seg_1(2 * i + j, 1),
            --h_bus_dpu_in_out1_3_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 3),
            --h_bus_dpu_in_out1_4_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            --sel_r_ext_in               
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            --ext_v_input_bus_in        =>    
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            --sel_r_ext_out             =>    
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            --ext_v_input_bus_out       =>    
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

    end generate MTRF_ROWS;

  end generate MTRF_COLS;

end architecture rtl;
