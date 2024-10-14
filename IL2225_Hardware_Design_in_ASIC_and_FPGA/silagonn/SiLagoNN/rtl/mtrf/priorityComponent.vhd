-------------------------------------------------------
--! @file priorityComponent.vhd
--! @brief component for the Priority mux
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2020-02-26
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
-- Title      : component for the Priority mux
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : priorityComponent.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2020-02-26
-- Last update: 2020-02-26
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2020
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2020-02-26  1.0      Dimitrios Stathis      Created
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

--! IEEE and work Library
LIBRARY IEEE, work;
--! Use standard library
USE IEEE.std_logic_1164.ALL;
--! Use numeric standard library for arithmetic operations
USE ieee.numeric_std.ALL;
--! Use ieee misc package for the or_reduce function
USE ieee.std_logic_misc.ALL;
--! Use of top constant and types package
USE work.top_consts_types_package.ALL;
--! Use of misc package for arithmetic non-synthesizable functions 
USE work.misc.ALL;

--! This is a component that is used to build the internal layers of the priority mux.

--! The mux get a number of select bits, the select bits are then OR-ed together and the result is used to
--! select the output between inA and inB.
ENTITY priorityComponent IS
    GENERIC (No_Select : NATURAL := 0); --! Number of select signals
    PORT (
        ID_A   : IN unsigned(FOR_LOOP_ID - 1 DOWNTO 0);       --! Input ID A, always use port ID_A for the id with highest priority 
        ID_B   : IN unsigned(FOR_LOOP_ID - 1 DOWNTO 0);       --! Input ID B, always use port ID_B for the id with lowest priority
        sel_in : IN std_logic_vector(No_Select - 1 DOWNTO 0); --! Select bits, directly from the input
        ID_out : OUT unsigned(FOR_LOOP_ID - 1 DOWNTO 0)       --! Output of the mux
    );
END priorityComponent;

--! @brief The component is a simple mux with an additional OR before the select signal
--! @details TODO put figure here.
ARCHITECTURE RTL OF priorityComponent IS
    SIGNAL select_sig : std_logic;
BEGIN
    select_sig <= or_reduce(sel_in);
    selection : PROCESS (ALL)
    BEGIN
        IF select_sig = '1' THEN
            ID_out <= ID_A;
            ELSE
            ID_out <= ID_B;
        END IF;
    END PROCESS selection;
END RTL;