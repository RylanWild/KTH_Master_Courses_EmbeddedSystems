---------------- Copyright (c) notice -----------------------------------------
--
-- The VHDL code, the logic and concepts described in this file constitute
-- the intellectual property of the authors listed below, who are affiliated
-- to KTH(Kungliga Tekniska Högskolan), School of ICT, Kista.
-- Any unauthorised use, copy or distribution is strictly prohibited.
-- Any authorised use, copy or distribution should carry this copyright notice
-- unaltered.
-------------------------------------------------------------------------------
---------------------------------------------------------------------------
--! @file
--! @brief This module is used for address assignment in each block in a fabric
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Author(s)		: Dimitrios Stathis <stathis@kth.se>
-- 
-- Creation Date	: 15/01/2018
-- File		    	: addr_assign.vhd
-- Last update      : 15/01/2018
---------------------------------------------------------------------------

--! Standard ieee library
library ieee;
--! Standard logic library
use ieee.std_logic_1164.all;
--! Standard numeric library for signed and unsigned
use ieee.numeric_std.all;
--USE work.hw_setting.ROW_WIDTH;
--USE work.hw_setting.COL_WIDTH;
USE work.noc_types_n_constants.all;

--! @brief This module is used for address assignment in each block(cell) in a fabric
--! @details We use this module to generate and store the global address of the
--! SiLago or DiMArch cell. The module assigns one address (row and column) to
--! the block according to the address of the previous cell. The assignment can be
--! done only once after the reset of the system, and it is blocked after the first
--! assignment. We use the ROW_WIDTH and COL_WIDTH generic to set the required bits for
--! addressing.

entity addr_assign is
	port(
		clk        : in  std_logic; --! Clock 
		rst_n      : in  std_logic; --! Negative reset
		start_row  : in  std_logic; --! Start signal (connected to the valid signal of the previous block in the same row)
		start_col  : in  std_logic; --! Start signal (connected to the valid signal of the previous block in the same col)
		prevRow    : in  UNSIGNED(ROW_WIDTH - 1 DOWNTO 0); --! Row address assigned to the previous cell
		prevCol    : in  UNSIGNED(COL_WIDTH - 1 DOWNTO 0); --! Col address assigned to the previous cell
		valid      : out std_logic; --! Valid signals, used to signal that the assignment of the address is complete
		thisRow    : out UNSIGNED(ROW_WIDTH - 1 DOWNTO 0); --! The row address assigned to the cell
		thisCol    : out UNSIGNED(COL_WIDTH - 1 DOWNTO 0)  --! The column address assigned to the cell
	);
end entity addr_assign;

--! @brief Simple structural architecture for address assignment.
--! @details We use a row and column signal to store the local assigned address.
--! The local address is assigned using the address of the previous cell. When 
--! the previous cell get its address assigned, it rise the valid signal. When
--! this cell reads the assertion of this signal and depending, if the signal
--! arrives from the cell in the previous row then the row address is assigned
--! by adding one (1) in the row address and keeping the column address as is. 
--! When the signal arrives from the cell in the same row, the generated address
--! is assigned by adding one in the row column address and keeps the row address as is.
architecture RTL of addr_assign is
	signal Row  : UNSIGNED(ROW_WIDTH - 1 DOWNTO 0); --! Local row address 
	signal Col  : UNSIGNED(COL_WIDTH - 1 DOWNTO 0); --! Local column address 
	signal lock : std_logic; --! Lock signal, that signals the assignment of address
begin
	thisRow <= Row;
	thisCol <= Col;
	valid   <= lock;

	address_assignment : process(clk, rst_n) is
	begin
		if rst_n = '0' then
			Row  <= (OTHERS => '0');
			Col  <= (others => '0');
			lock <= '0';
		elsif rising_edge(clk) then
			if (lock = '0') then
				if (start_col = '1') then --! Signal coming from the same column (we have a change in rows)
					row  <= prevRow + 1;
					col  <= prevCol;
					lock <= '1';
				end if;
				if (start_row = '1') then --! Signal coming from the same row (we have a change in column)
					col  <= prevCol + 1;
					row  <= prevRow;
					lock <= '1';
				end if;
			end if;
		end if;
	end process address_assignment;

end architecture RTL;

