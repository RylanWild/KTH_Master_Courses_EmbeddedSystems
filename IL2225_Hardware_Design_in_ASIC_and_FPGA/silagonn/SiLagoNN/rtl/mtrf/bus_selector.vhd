---------------- Copyright (c) notice -----------------------------------------
--
-- The VHDL code, the logic and concepts described in this file constitute
-- the intellectual property of the authors listed below, who are affiliated
-- to KTH(Kungliga Tekniska H�gskolan), School of ICT, Kista.
-- Any unauthorised use, copy or distribution is strictly prohibited.
-- Any authorised use, copy or distribution should carry this copyright notice
-- unaltered.
-- This is a bus selector  which is used to select which bus of silego should go 
-- through
--
--
--
-- revised by Muhammad Adeel Tajammul: PhD student, ES, School of ICT, KTH, Kista.
-- Contact: tajammul@kth.se


---------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
--use work.drra_types_n_constants.ROWS;
--use work.drra_types_n_constants.COLUMNS;
--use work.drra_types_n_constants.INSTR_WIDTH;
use work.noc_types_n_constants.all;
--use WORK.SINGLEPORT_SRAM_AGU_types_n_constants.initial_delay_WIDTH;
--use work.misc.all;

entity bus_selector is
	port(
		noc_bus_in0 : in NOC_BUS_TYPE;--INST_SIGNAL_TYPE(0 to COLUMNS, 0 to ROWS-1);
		noc_bus_in1 : in NOC_BUS_TYPE;
		noc_bus_out : out NOC_BUS_TYPE
	);
end entity bus_selector;

architecture RTL of bus_selector is
begin
	noc_bus_out  <= noc_bus_in0 when (noc_bus_in0.bus_enable = '1' ) else
					noc_bus_in1 when (noc_bus_in1.bus_enable = '1' ) else
					IDLE_BUS;

end architecture RTL;

