library ieee, work;
use ieee.std_logic_1164.all;
USE IEEE.std_logic_signed.ALL;
USE ieee.numeric_std.ALL;
use work.functions.log2c;

entity trail_zeros_cnt is
	generic(Nb	: integer);
	port(
			d_in	: in std_logic_vector(Nb-1 downto 0);
			d_out	: out std_logic_vector(log2c(Nb)-1 downto 0)
		);
end entity;

architecture bhv of trail_zeros_cnt is
	type bits_cmp_type is array(1 to Nb) of std_logic_vector(Nb-1 downto 0);
	signal bits_cmp	: bits_cmp_type;
	signal cmp_res	: std_logic_vector(Nb downto 1);
	signal count 	: std_logic_vector(log2c(Nb)-1 downto 0);
begin
	
	--bits_cmp(0) <= (others => '0');
	bits_cmp(Nb) <= (others => '0');
	bits_cmp_init: for i in 1 to Nb-1 generate
		if_mspart_exist: if i < Nb-1 generate
			bits_cmp(i)(Nb-1 downto i+1) <= (others => '0');
		end generate;
		bits_cmp(i)(i) <= '1';
		bits_cmp(i)(i-1 downto 0) <= (others => '0');
	end generate;
	
	count_proc: process(d_in, bits_cmp)
		variable count	: integer;
	begin
		count := 0;
		for i in 1 to Nb-1 loop
			if d_in(i downto 0) = bits_cmp(i)(i downto 0) then
				count := i-1; -- Encode the (#zeros -1) inside the data word
			end if;
		end loop;
		if d_in = bits_cmp(Nb) then
			count := Nb-1;  -- Encode the (#zeros -1) inside the data word
		end if;
		d_out <= std_logic_vector(to_unsigned(count, d_out'length));
	end process;
	
end architecture;