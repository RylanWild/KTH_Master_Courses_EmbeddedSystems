---------------- Copyright (c) notice -----------------------------------------
--
-- The VHDL code, the logic and concepts described in this file constitute
-- the intellectual property of the authors listed below, who are affiliated
-- to KTH(Kungliga Tekniska Högskolan), School of ICT, Kista.
-- Any unauthorised use, copy or distribution is strictly prohibited.
-- Any authorised use, copy or distribution should carry this copyright notice
-- unaltered.
-------------------------------------------------------------------------------
--! @file
--! @brief Register for std_logic_vector data
-------------------------------------------------------------------------------
-- Authors: Guido Baccelli : Master's student, KTH, Kista.
-- Contact: beccelli@kth.se
-- Creation Date	: 09/01/2019
-- File		    	: reg_n.vhd
-- Last update      : 09/01/2019
--
-------------------------------------------------------------------------------

--! Standard ieee library
LIBRARY ieee;
--! Default working library
LIBRARY work;
--! Standard logic package
USE ieee.std_logic_1164.ALL;
--! Standard numeric package for signed and unsigned
USE ieee.numeric_std.ALL;
--! Package for CGRA Types and Constants
USE work.top_consts_types_package.ALL;

--! @brief Register for std_logic_vector data with reset, clear and enable commands
entity reg_n is 
	generic(Nb : integer); --! Number of bits
	port(
			clk		: in std_logic; --! Clock
			rst_n	: in std_logic; --! Asynchronous Reset
			clear	: in std_logic; --! Clear (synchronous reset)
			en		: in std_logic; --! Enable
			d_in	: in std_logic_vector(Nb-1 downto 0); --! Input data
			d_out	: out std_logic_vector(Nb-1 downto 0)	--! Output data
		);
end entity;

--! @brief Behavioral description with sequential process
architecture bhv of reg_n is
begin
	reg_proc: process(rst_n, clk)
	begin
		if rst_n = '0' then
			d_out <= (others => '0');
		elsif rising_edge(clk) then
			if en = '1' then
				if clear = '0' then
					d_out <= d_in;
				else
					d_out <= (others => '0');
				end if;
			end if;
		end if;
	end process;
end architecture;
