library ieee, work;
use ieee.std_logic_1164.all;
USE IEEE.std_logic_signed.ALL;
USE ieee.numeric_std.ALL;
USE work.functions.all;

entity barrel_shifter_rle is
	 generic(
	 			Nw  : integer;
	 			Nb	: integer
	 			
			);
		port(
				sh_l_rn		: in std_logic;
				sh_num		: in std_logic_vector(log2c(Nw+1)-1 downto 0); -- CHECK input of log2c
				d_in 		: in std_logic_vector(Nw*Nb-1 downto 0);
				d_out		: out std_logic_vector(Nw*Nb-1 downto 0)
			);
end entity;

-- Architecture that uses the function shift_left with a run-time changing number of
-- bits to shift. This way of describing the operation should induce the compiler
-- to instantiate a barrel shifter
architecture bhv_shift of barrel_shifter_rle is
	signal sh_am_signal 	: integer;
begin
	d_out_gen: process(d_in, sh_num, sh_l_rn)
		variable shift_amount 	: integer range 0 to Nb*(2**(sh_num'length)-1);
		--variable shift_amount 	: integer range 0 to Nw*Nb;
	begin
		shift_amount := Nb*to_integer(unsigned(sh_num));
		sh_am_signal <= shift_amount;
		if sh_l_rn = '1' then
			d_out <= std_logic_vector(shift_left(unsigned(d_in), shift_amount));
		else
			d_out  <= std_logic_vector(shift_right(unsigned(d_in), shift_amount));
		end if;
	end process;
	
end architecture;