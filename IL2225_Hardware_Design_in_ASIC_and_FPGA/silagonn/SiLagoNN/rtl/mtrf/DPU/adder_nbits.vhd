-------------------------------------------------------
--! @file adder_nbits.vhd
--! @brief N_bit adder with reconfiguration for n/2 and n/4
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
-- Title      : N_bit adder with reconfiguration for n/2 and n/4
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : adder_nbits.vhd
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
LIBRARY IEEE, work;
LIBRARY DWARE;
--! Use standard library
USE IEEE.std_logic_1164.ALL;
--! Use numeric standard library for arithmetic operations
USE ieee.numeric_std.ALL;
--! DPU package
USE work.DPU_pkg.ALL;
--! DWare package from synopsys
USE DWARE.DWpackages.ALL;
--! DWare package from synopsys
USE DWARE.DW_foundation_comp.ALL;

--! This is an a generic N-bit adder that is broken down to multiple slices. 

--! This adder can perform a full width addition or multiple smaller additions=>
--! The number of additions depends on the number of slices, and the 
--! number of configuration bits "select_w".
ENTITY adder_nbits IS
  GENERIC (
    width    : NATURAL := 16; --! Bitwidth, must be power of 2
    select_w : NATURAL := 2   --! Number of configuration bits @TODO need to move this in the package
  );
  PORT (
    A    : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);          --! Input A
    B    : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);          --! Input B
    conf : IN STD_LOGIC_VECTOR(select_w - 1 DOWNTO 0);       --! Configuration
    SO   : OUT STD_LOGIC_VECTOR(2 ** select_w - 1 DOWNTO 0); --! Sign extension of the slices, depends on the configuration, 
    SUM  : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0)          --! Unsaturated output
  );
END adder_nbits;

--! @brief Architecture for reconfigurable adder.
--! @details The current design works for 0 2 or 4 slices due to the way that we create the configuration signals.
--! To make it general an if close can be use but it be un-optimized solutions. It is better to extend the code
--! if needed by adding more cases.
ARCHITECTURE structural OF adder_nbits IS
  --CONSTANT SLICES     : NATURAL := 2 ** select_w;
  --CONSTANT SLICE_BITS : NATURAL := width/SLICES;
  SIGNAL A_temp    : adder_array_inOut_ty(SLICES - 1 DOWNTO 0);
  SIGNAL B_temp    : adder_array_inOut_ty(SLICES - 1 DOWNTO 0);
  SIGNAL sum_tmp   : adder_array_inOut_ty(SLICES - 1 DOWNTO 0);
  SIGNAL c_chain_i : STD_LOGIC_VECTOR(SLICES - 1 DOWNTO 0);
  SIGNAL c_chain_o : STD_LOGIC_VECTOR(SLICES DOWNTO 1);
  SIGNAL c_select  : STD_LOGIC_VECTOR(select_w - 1 DOWNTO 0);
BEGIN

  c_chain_i(0) <= '0';

  -- Control signals
  select_1b : IF select_w = 1 GENERATE
    c_select <= conf;
  END GENERATE select_1b;

  select_2b : IF select_w = 2 GENERATE
    c_select(0) <= conf(0);
    c_select(1) <= conf(1) AND conf (0);
  END GENERATE select_2b;

  adder_chain : FOR i IN 0 TO SLICES - 1 GENERATE

    -- Break down A and B to sub-vectors
    A_temp(i) <= A(((i + 1) * SLICE_BITS - 1) DOWNTO i * SLICE_BITS);
    B_temp(i) <= B(((i + 1) * SLICE_BITS - 1) DOWNTO i * SLICE_BITS);

    U_add : DW01_add
    GENERIC MAP(
      width => SLICE_BITS
    )
    PORT MAP(
      A   => A_temp(i),
      B   => B_temp(i),
      CI  => c_chain_i(i),
      SUM => sum_tmp(i),
      CO  => c_chain_o(i + 1)
    );

    --------------------------------------------------------------------------------
    -- Select carry value
    i_neq_0 : IF i /= 0 GENERATE

      select_2b : IF select_w = 2 GENERATE
        i_0_or_2 : IF (i = 3) OR (i = 1) GENERATE
          c_chain_i(i) <= c_chain_o(i) WHEN c_select(1) = '0' ELSE
          '0';
        END GENERATE i_0_or_2;

        i_1 : IF (i = 2) GENERATE
          c_chain_i(i) <= c_chain_o(i) WHEN c_select(0) = '0' ELSE
          '0';
        END GENERATE i_1;
      END GENERATE select_2b;

      select_1b : IF select_w = 1 GENERATE
        c_chain_i(i) <= c_chain_o(i) WHEN c_select(0) = '0' ELSE
        '0';
      END GENERATE select_1b;

    END GENERATE i_neq_0;
    --------------------------------------------------------------------------------
    SUM(((i + 1) * SLICE_BITS - 1) DOWNTO i * SLICE_BITS) <= sum_tmp(i);
  END GENERATE adder_chain;

  --------------------------------------------------------------------------------
  -- Calculate the sign of each slice
  --------------------------------------------------------------------------------
  Sign_extension : FOR i IN 0 TO SLICES - 1 GENERATE

    sign_ext : PROCESS (ALL)
      VARIABLE sign_A    : unsigned (0 DOWNTO 0);
      VARIABLE sign_b    : unsigned (0 DOWNTO 0);
      VARIABLE sign_c    : unsigned (0 DOWNTO 0);
      VARIABLE sign_temp : unsigned (0 DOWNTO 0);
    BEGIN
      sign_A    := unsigned(A_temp(i)(SLICE_BITS - 1 DOWNTO slice_bits - 1));
      sign_B    := unsigned(B_temp(i)(SLICE_BITS - 1 DOWNTO slice_bits - 1));
      sign_c    := unsigned(c_chain_o(i + 1 DOWNTO i + 1));
      sign_temp := sign_A + sign_B + sign_c;
      SO(i) <= sign_temp(0);
    END PROCESS;

  END GENERATE Sign_extension;

END structural;