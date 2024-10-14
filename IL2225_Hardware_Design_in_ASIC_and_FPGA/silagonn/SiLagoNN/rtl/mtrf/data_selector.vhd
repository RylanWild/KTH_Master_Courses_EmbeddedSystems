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
--! @brief This module is used to select the access to the dimarch data bus
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Author(s)		: Dimitrios Stathis <stathis@kth.se>
-- 
-- Creation Date	: 15/01/2018
-- File		    	: data_selector.vhd
-- Last update      : 15/01/2018
---------------------------------------------------------------------------

--! Standard ieee library
library ieee;
--! Standard logic library
use ieee.std_logic_1164.all;
--! Standard numeric library for signed and unsigned
use ieee.numeric_std.all;
use work.noc_types_n_constants.DATA_IO_SIGNAL_TYPE;
use work.top_consts_types_package.SRAM_WIDTH;
use work.noc_types_n_constants.zero_block;

--! @brief This module is used to select the access to the dimarch data bus
--! @details We use this module to select which of the 2 DRRA rows will have
--! access to the data bus that connects with the bottom line of the DiMArch
entity data_selector is

	port(
		data_in_this                 : in  STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data from this 
		data_in_next                 : in  STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data from other row
		data_out                     : out STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data out
		dimarch_silego_rd_2_out_this : in  std_logic; --! ready signal from this cell
		dimarch_silego_rd_out_next : in  std_logic  --! ready signal from the other row
	);
end entity data_selector;

--! @brief Simple structural architecture for address assignment.
--! @details This is a simple multiplexer that decides the connection to the data bus
architecture RTL of data_selector is
begin

	data_out <= data_in_this WHEN (dimarch_silego_rd_2_out_this = '1')
	else data_in_next WHEN (dimarch_silego_rd_out_next = '1')
	else zero_block;

end architecture RTL;
