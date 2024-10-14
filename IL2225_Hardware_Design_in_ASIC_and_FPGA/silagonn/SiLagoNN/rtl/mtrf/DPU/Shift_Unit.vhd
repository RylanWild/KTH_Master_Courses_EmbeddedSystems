-------------------------------------------------------
--! @file Shift_Unit.vhd
--! @brief Arithmetic Shifter
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2021-04-20
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
-- Title      : Arithmetic Shifter
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : Shift_Unit.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2021-04-20
-- Last update: 2021-04-20
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2021-04-20  1.0      Dimitrios Stathis      Created
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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.DPU_pkg.ALL;
USE work.util_package.ALL;

ENTITY Shift_Unit IS
  GENERIC (b_width : INTEGER); --! Bitwidth of inputs
  PORT (
    d_in    : IN signed(b_width - 1 DOWNTO 0);   --! Input (signed)
    sh_num  : IN unsigned(b_width - 1 DOWNTO 0); --! Number of shifting positions (unsigned)
    sh_l_rn : IN STD_LOGIC;                      --! Left or right shift (1 for left, 0 for right)
    d_out   : OUT signed(b_width - 1 DOWNTO 0)   --! Output
  );
END ENTITY;

ARCHITECTURE Behavior OF Shift_Unit IS
BEGIN

  d_out <= SHIFT_LEFT(d_in, to_integer(sh_num)) WHEN sh_l_rn = '1' ELSE
    SHIFT_RIGHT(d_in, to_integer(sh_num));

END ARCHITECTURE Behavior;