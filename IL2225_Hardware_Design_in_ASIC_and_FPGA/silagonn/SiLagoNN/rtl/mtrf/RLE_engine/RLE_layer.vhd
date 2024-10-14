library ieee, work;
use ieee.std_logic_1164.all;
USE IEEE.std_logic_signed.ALL;
USE ieee.numeric_std.ALL;
use work.functions.log2c;

entity RLE_layer is
	 generic(
	 			Nw	: integer;
	 			Nb	: integer
	 		);
	 	port(
	 			dec_com_n	: in std_logic; -- 1 for decompression, 0 for compression
	 			d_in		: in std_logic_vector(Nw*Nb-1 downto 0);
	 			proc_word	: out std_logic_vector(Nb-1 downto 0);
	 			d_out		: out std_logic_vector((Nw-1)*Nb-1 downto 0)
	 		);
end entity;

architecture struct of RLE_layer is

	type d_in_array_type is array(0 to Nw-1) of std_logic_vector(Nb-1 downto 0);
	
	-- Common Signals
	signal d_to_bar_sh	: std_logic_vector((Nw-1)*Nb-1 downto 0);
	signal cnt_zeros_final	: std_logic_vector(log2c(Nw)-1 downto 0);
	
	-- Decompression Part signals
	signal data_is_enc	: std_logic;
	signal half_ones	: std_logic_vector(Nb/2-1 downto 0);
	signal word_to_dec, dec_word	: std_logic_vector(Nb-1 downto 0);
	signal cnt_zeros_dec	: std_logic_vector(log2c(Nw)-1 downto 0);
	
	-- Compression Part signals 
	signal d_in_array  		: d_in_array_type;
	signal d_in_word_neq0 	: std_logic_vector(Nw-1 downto 0);
	signal all_ones, enc_word, com_word	: std_logic_vector(Nb-1 downto 0);
	signal cnt_zeros_com	: std_logic_vector(log2c(Nw)-1 downto 0);
	
begin
	half_ones <= (others => '1');
	word_to_dec	<= d_in(Nb-1 downto 0);
	d_to_bar_sh <= d_in(Nw*Nb-1 downto Nb);
	
	-- ########## Get #zeros and processed word for decompression ########## 
	
	data_is_enc <= '1' when word_to_dec(Nb-1 downto Nb/2) = half_ones else '0';
	dec_word <=  word_to_dec when data_is_enc = '0' else (others => '0');
	cnt_zeros_dec <= (others => '0') when data_is_enc = '0' else word_to_dec(cnt_zeros_dec'length-1 downto 0);
	
	-- ########## Get #zeros and processed word for compression ##########
	
	all_ones <= (others => '1');
	
	d_in_array_gen: for i in 0 to Nw-1 generate
		d_in_array(i) <= d_in((i+1)*Nb-1 downto i*Nb);
		d_in_word_neq0(i) <= '1' when d_in_array(i)(Nb-1 downto Nb/2) /= half_ones else '0';
	end generate;
	
	trail_zeros_unit: entity work.trail_zeros_cnt
		generic map(Nb => Nw)
		port map(
					d_in => d_in_word_neq0,
					d_out => cnt_zeros_com
				);

	d_in_0_enc_proc: process(cnt_zeros_com)
	begin
		enc_word(Nb-1 downto Nb/2) <= (others => '1');
		enc_word(Nb/2-1 downto 0) <= (others => '0');
		enc_word(cnt_zeros_com'length-1 downto 0) <= cnt_zeros_com;
	end process;
	
	com_word <= d_in_array(0) when d_in_word_neq0(0) = '1' else enc_word;
	
	-- Choose final #zeros
	cnt_zeros_final <= cnt_zeros_dec when dec_com_n = '1' else cnt_zeros_com;
	
	-- Choose final processed word
	proc_word <= dec_word when dec_com_n = '1' else com_word;
	
	bar_sh_i: entity work.barrel_shifter_rle
	generic map	(
					Nw => Nw-1,
					Nb => Nb
				)
	port map	(
					sh_l_rn => dec_com_n,
					sh_num => cnt_zeros_final,
					d_in => d_to_bar_sh,
					d_out => d_out
				);
	
end architecture;