-------------------------------------------------------------------------------
-- Title      :Register Row
-- Project    : MTRF Fabric
-------------------------------------------------------------------------------
-- File       : register_row.vhd
-- Supervisor  : Nasim Farahini
-- Author     : sadiq  <sadiq@drrasystem>
-- Company    : 
-- Created    : 2013-07-19
-- Last update: 2013-10-06
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: <cursor>
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Contact    : Nasim Farahini <farahini@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2013-07-19  1.0      sadiq	Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;  
use work.top_consts_types_package.all;


entity register_row is
	--generic  (initial_vector : signed(REG_FILE_DATA_WIDTH-1 downto 0));
	port(
		rst_n	:in  std_logic;
		clk	:in  std_logic;
		wr_enb	:in  std_logic;
		reg_in	:in  signed(REG_FILE_DATA_WIDTH-1 downto 0);
		reg_out	:out signed(REG_FILE_DATA_WIDTH-1 downto 0));
end register_row;

architecture behavioral of register_row is
  
begin
	process(rst_n,clk,reg_in)
	begin
		if rst_n = '0' then
			reg_out <= (others=>'0');
		elsif clk'event and clk = '1' then
			if wr_enb = '1' then
				reg_out <= reg_in;
			end if;
		end if;
	end process;
end behavioral;
