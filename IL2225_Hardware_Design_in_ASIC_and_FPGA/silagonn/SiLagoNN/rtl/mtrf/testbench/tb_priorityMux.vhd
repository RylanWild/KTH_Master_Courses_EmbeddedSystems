-------------------------------------------------------
--! @file tb_priorityMux.vhd
--! @brief testbench for the priority Mux
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2020-02-28
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
-- Title      : testbench for the priority Mux
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : tb_priorityMux.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2020-02-28
-- Last update: 2020-02-28
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2020
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2020-02-28  1.0      Dimitrios Stathis      Created
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

--! IEEE Library
LIBRARY IEEE;
--! Use standard library
USE IEEE.std_logic_1164.ALL;
--! Use numeric standard library for arithmetic operations
USE ieee.numeric_std.ALL;
--! Use numeric standard library for arithmetic operations
USE ieee.numeric_std.ALL;
--! Use of top constant and types package
USE work.top_consts_types_package.ALL;
--! Use of misc package for arithmetic non-synthesizable functions 
USE work.misc.ALL;

--!

--!
ENTITY testbench IS

END testbench;
--! @brief 
--! @details
ARCHITECTURE priorityMux OF testbench IS
    CONSTANT LEVELS : NATURAL := 2;
    CONSTANT i      : NATURAL := 2;
    CONSTANT N      : NATURAL := 4;
    SIGNAL ID_in    : priority_input_ty(N - 1 DOWNTO 0);  --! Input IDs 
    SIGNAL sel_in   : std_logic_vector(N - 1 DOWNTO 0);   --! Valid/select bits (from all loops)
    SIGNAL ID_out   : unsigned(FOR_LOOP_ID - 1 DOWNTO 0); --! Output IDs 
BEGIN
    DUT : ENTITY work.priorityMux
        GENERIC MAP(
            LEVELS   => LEVELS,
            i        => i - 1,
            N_sel_in => N,
            N_in     => N,
            N        => N
        )
        PORT MAP(
            ID_in  => ID_in,
            sel_in => sel_in,
            ID_out => ID_out
        );

    IDS : FOR k IN 0 TO N - 1 GENERATE
        ID_in(k) <= to_unsigned(k, FOR_LOOP_ID);
    END GENERATE IDS;

    PROCESS
    BEGIN
        FOR i IN 0 TO 15 LOOP
            sel_in <= std_logic_vector(to_unsigned(i, N));
            WAIT FOR 5 ns;
        END LOOP;
    END PROCESS;

    test_1 : PROCESS (ID_out)
    BEGIN
        IF (sel_in(0) = '1') THEN
            ASSERT(ID_out = 0) REPORT "ID_out not 0 when sel_in(0)=1" SEVERITY error;
            ASSERT(ID_out /= 0) REPORT "ID_out = 0 when sel_in(0)=1" SEVERITY note;
            ELSIF sel_in(1) = '1' THEN
            ASSERT(ID_out = 1) REPORT "ID_out not 1 when sel_in(1)=1" SEVERITY error;
            ASSERT(ID_out /= 1) REPORT "ID_out = 1 when sel_in(1)=1" SEVERITY note;
            ELSIF sel_in(2) = '1' THEN
            ASSERT(ID_out = 2) REPORT "ID_out not 2 when sel_in(2)=1" SEVERITY error;
            ASSERT(ID_out /= 2) REPORT "ID_out = 2 when sel_in(2)=1" SEVERITY note;
            ELSIF sel_in(3) = '1' THEN
            ASSERT(ID_out = 3) REPORT "ID_out not 3 when sel_in(3)=1" SEVERITY error;
            ASSERT(ID_out /= 3) REPORT "ID_out = 3 when sel_in(3)=1" SEVERITY note;
        END IF;

    END PROCESS test_1;
END priorityMux;