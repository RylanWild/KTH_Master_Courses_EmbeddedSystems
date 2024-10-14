-------------------------------------------------------
--! @file crossbar_types_n_constants.vhd
--! @brief 
--! @details 
--! @author 
--! @version 1.0
--! @date 
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
-- Title      : 
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : crossbar_types_n_constants.vhd
-- Author     : 
-- Company    : KTH
-- Created    : 
-- Last update: 2022-04-05
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2014
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
--             2.1      Dimitrios Stathis       Debugging crossbar data propagation
--                                              error
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
USE ieee.math_real.ALL;
USE work.noc_types_n_constants.ALL;
USE work.top_consts_types_package.SRAM_WIDTH;
USE work.misc.log2_ceil;
PACKAGE crossbar_types_n_constants IS
  --------------------------------------------------------------------
  -- CROSSBAR 
  --------------------------------------------------------------------
  CONSTANT nr_of_crossbar_ports  : INTEGER := 5;
  CONSTANT crossbar_select_width : INTEGER := INTEGER(ceil(log2(real(nr_of_crossbar_ports))));

  TYPE CROSSBAR_DATA_TYPE IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR (SRAM_WIDTH - 1 DOWNTO 0);
  --------------------------------------------------------------------
  -- CROSSBAR DIRECTIONS 
  --------------------------------------------------------------------
  TYPE CROSSBAR_select_type IS ARRAY (nr_of_crossbar_ports - 1 DOWNTO 0) OF STD_LOGIC_VECTOR (crossbar_select_width - 1 DOWNTO 0);

  TYPE CORSSBAR_INSTRUCTION_RECORD_TYPE IS RECORD
    ENABLE      : STD_LOGIC;
    SELECT_FROM : STD_LOGIC_VECTOR (crossbar_select_width - 1 DOWNTO 0);
    SELECT_TO   : STD_LOGIC_VECTOR (crossbar_select_width - 1 DOWNTO 0);
  END RECORD;

  CONSTANT NORTH_INT            : INTEGER                                              := to_integer(unsigned(NORTH));
  CONSTANT SOUTH_INT            : INTEGER                                              := to_integer(unsigned(SOUTH));
  CONSTANT EAST_INT             : INTEGER                                              := to_integer(unsigned(EAST));
  CONSTANT WEST_INT             : INTEGER                                              := to_integer(unsigned(WEST));
  CONSTANT MEMORY_INT           : INTEGER                                              := 4;
  CONSTANT DEFAULT_INT          : INTEGER                                              := 5;

  CONSTANT to_north             : STD_LOGIC_VECTOR(crossbar_select_width - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(NORTH_INT, crossbar_select_width));
  CONSTANT to_east              : STD_LOGIC_VECTOR(crossbar_select_width - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(EAST_INT, crossbar_select_width));
  CONSTANT to_west              : STD_LOGIC_VECTOR(crossbar_select_width - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(WEST_INT, crossbar_select_width));
  CONSTANT to_south             : STD_LOGIC_VECTOR(crossbar_select_width - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(SOUTH_INT, crossbar_select_width));
  CONSTANT to_memory            : STD_LOGIC_VECTOR(crossbar_select_width - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(MEMORY_INT, crossbar_select_width));

  CONSTANT from_north           : STD_LOGIC_VECTOR(crossbar_select_width - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(NORTH_INT, crossbar_select_width));
  CONSTANT from_east            : STD_LOGIC_VECTOR(crossbar_select_width - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(EAST_INT, crossbar_select_width));
  CONSTANT from_west            : STD_LOGIC_VECTOR(crossbar_select_width - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(WEST_INT, crossbar_select_width));
  CONSTANT from_south           : STD_LOGIC_VECTOR(crossbar_select_width - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(SOUTH_INT, crossbar_select_width));
  CONSTANT from_memory          : STD_LOGIC_VECTOR(crossbar_select_width - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned(MEMORY_INT, crossbar_select_width));

  CONSTANT IGNORE               : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('0', from_memory, to_memory);

  CONSTANT FROM_NORTH_TO_MEMORY : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_north, to_memory);
  CONSTANT FROM_EAST_TO_MEMORY  : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_east, to_memory);
  CONSTANT FROM_WEST_TO_MEMORY  : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_west, to_memory);
  CONSTANT FROM_SOUTH_TO_MEMORY : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_south, to_memory);

  CONSTANT FROM_MEMORY_TO_NORTH : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_memory, to_north);
  CONSTANT FROM_EAST_TO_NORTH   : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_east, to_north);
  CONSTANT FROM_WEST_TO_NORTH   : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_west, to_north);
  CONSTANT FROM_SOUTH_TO_NORTH  : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_south, to_north);

  CONSTANT FROM_MEMORY_TO_EAST  : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_memory, to_east);
  CONSTANT FROM_NORTH_TO_EAST   : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_north, to_east);
  CONSTANT FROM_WEST_TO_EAST    : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_west, to_east);
  CONSTANT FROM_SOUTH_TO_EAST   : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_south, to_east);

  CONSTANT FROM_MEMORY_TO_WEST  : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_memory, to_west);
  CONSTANT FROM_NORTH_TO_WEST   : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_north, to_west);
  CONSTANT FROM_EAST_TO_WEST    : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_east, to_west);
  CONSTANT FROM_SOUTH_TO_WEST   : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_south, to_west);

  CONSTANT FROM_MEMORY_TO_SOUTH : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_memory, to_south);
  CONSTANT FROM_NORTH_TO_SOUTH  : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_north, to_south);
  CONSTANT FROM_EAST_TO_SOUTH   : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_east, to_south);
  CONSTANT FROM_WEST_TO_SOUTH   : CORSSBAR_INSTRUCTION_RECORD_TYPE                     := ('1', from_west, to_south);

END PACKAGE crossbar_types_n_constants;