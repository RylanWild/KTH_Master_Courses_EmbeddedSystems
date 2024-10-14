-------------------------------------------------------
--! @file DWARE.DW_foundation_comp.vhd
--! @brief DW_package for simulation, it contains the component definitions
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2021-02-22
--! @bug NONE
--! @todo NONE
--! @copyright  GNU Public License [GPL-3.0].
-------------------------------------------------------
---------------- Copyright (c) notice -----------------------------------------
--
-- The VHDL code, the logic and concepts described in this file constitute
-- the intellectual property of the authors listed below, who are affiliated
-- to KTH(Kungliga Tekniska Högskolan), School of EECS, Kista.
-- Any unauthorised use, copy or distribution is strictly prohibited.
-- Any authorised use, copy or distribution should carry this copyright notice
-- unaltered.
-------------------------------------------------------------------------------
-- Title      : DW_package for simulation, it contains the component definitions
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : DWARE.DW_foundation_comp.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2021-02-22
-- Last update: 2021-02-22
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2021-02-22  1.0      Dimitrios Stathis      Created
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

--! This package is used for simulation only
--! and it replaces the synopsys DW_foundation_comp package
PACKAGE DW_foundation_comp IS

  COMPONENT DW01_add IS
    GENERIC (
      width : NATURAL := 4
    );
    PORT (
      A   : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
      B   : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
      CI  : IN STD_LOGIC;
      SUM : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
      CO  : OUT STD_LOGIC
    );
  END COMPONENT;

END PACKAGE;