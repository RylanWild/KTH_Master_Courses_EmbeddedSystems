-------------------------------------------------------
--! @file
--! @brief Global package with the global hardware generics
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
-- Title      : hw_setting
-- Project    : SiLago
-- Supervisor : Dimitrios Stathis
-------------------------------------------------------------------------------
-- File       : hw_setting.vhd
-- Author     : 
-- Company    : KTH
-- Created    : 
-- Last update: 2019-02-25
-- Platform   : SiLago
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Copyright (c) 2015
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2015        1.0                      Created
-- 2019-02-25  1.1      Dimitrios       Comments and License
-- 2019-10-23  1.2      Dimitrios       Doxygen main page
-- 2020-02-24  1.3      Dimitrios       Change for use with the new loop manager and raccu 
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

--! \mainpage Documentation of the SiLago Hardware Platform
--! This is the 2nd stable version of the platform. The platform used a pair of 
--! Coarse Grain Reconfigurable Architectures (CGRAs). We use one CGRA, 
--! DRRA (Dynamically Reconfigurable Resource Array), for computation and a second,
--! DiMArch (Distributed Memory Architecture), to create software controlled caches/
--!scratchpad memories.
--! \section pages Related pages 
--! - \subpage Top_consts_types_package_page

--! @brief HW settings package.
--! @details This package contains the configuration settings
--! for the hardware architecture.
PACKAGE hw_setting IS

  CONSTANT HW_INSTR_DEPTH           : NATURAL := 64;  --! Instruction memory depth (number of instructions)
  CONSTANT HW_RAM_DEPTH             : NATURAL := 128; --! Depth of SRAM memory
  CONSTANT HW_REG_FILE_DEPTH        : NATURAL := 64;  --! Register File depth
  CONSTANT HW_COLUMNS               : NATURAL := 8;   --! Number of DRRA columns (TODO: due to address limitation keep max=8)
  CONSTANT HW_ROWS                  : NATURAL := 2;   --! Number of DRRA rows (keep 2)
  CONSTANT HW_DIMARCH_ROWS          : NATURAL := 2;   --! Number of DiMArch rows
  ----------------------------------------------------
  -- REV 1.3 2020-02-24 ------------------------------
  ----------------------------------------------------
  CONSTANT HW_RACCU_REG_BITWIDTH    : NATURAL := 7;   --! RACCU register bitwidth - To be able to access memory addresses 7
  CONSTANT HW_MAX_NO_OF_RACCU_LOOPS : NATURAL := 4;   --! Number of RACCU Loop registers
  CONSTANT HW_RACCU_REGFILE_DEPTH   : NATURAL := 16;  --! Number of RACCU registers (including the iterator registers for the loop)
  ----------------------------------------------------
  -- End of modification REV 1.3 ---------------------
  ----------------------------------------------------
  CONSTANT HW_DPU_CONSTANT_WIDTH    : NATURAL := 8;   --! Size of DPU constant
  CONSTANT HW_BITWIDTH              : NATURAL := 16;  --! Bitwidth of the arithmetic units and busses
  CONSTANT HW_INSTR_WIDTH           : NATURAL := 27;  --! Bitwidth of the instructions

END PACKAGE hw_setting;

-- Some fixed parameters:
--  * BITWIDTH = 16
--  * RACCU maximum iteration is 64 (It is dependent to the RACCU operand width).
--  * RACCU_REG_BITWIDTH = 6
--  * ...

-- Note:
--   If there is a need for bigger register file then register_file.vhd and also
--   STARTING_ADDRS and NR_OF_ADDRS in top_consts package should be modified.
