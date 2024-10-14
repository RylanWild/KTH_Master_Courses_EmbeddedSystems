-------------------------------------------------------
--! @file tb_pkg_dpu.vhd
--! @brief Testbench package for the DPU
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2021-06-14
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
-- Title      : Testbench package for the DPU
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : tb_pkg_dpu.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2021-06-14
-- Last update: 2021-06-14
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2021
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2021-06-14  1.0      Dimitrios Stathis      Created
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

--! Standard library IEEE
LIBRARY ieee, work, std;
--! Standard logic package
USE ieee.std_logic_1164.ALL;
--! Package for numeric values
USE ieee.numeric_std.ALL;
--! Basic DPU package
USE work.DPU_pkg.ALL;
--! Use utility package for functions
USE work.util_package.ALL;
--! Basic I/O
USE STD.textio.ALL;
--! I/O for logic types
USE IEEE.std_logic_textio.ALL;

--! Package 
PACKAGE tb_pkg_dpu IS

  CONSTANT bit_width           : INTEGER                            := DPU_bitwidth;

  CONSTANT WIDTH_L             : NATURAL                            := divDown(bit_width, 2); --! Constant value for Width of the upper half
  CONSTANT WIDTH_H             : NATURAL                            := divUp(bit_width, 2);   --! Constant value for Width of the lower half
  CONSTANT WIDTH_2L            : NATURAL                            := divDown(bit_width, 4);
  CONSTANT width_2H            : NATURAL                            := divUp(bit_width, 4);

  CONSTANT TB_MAC_MAX_VALUE    : signed(bit_width * 2 - 1 DOWNTO 0) := "01111111111111111111111111111111";
  CONSTANT TB_MAC_MIN_VALUE    : signed(bit_width * 2 - 1 DOWNTO 0) := "10000000000000000000000000000000";
  CONSTANT TB_MAC_MAX_VALUE_0  : signed(bit_width - 1 DOWNTO 0)     := "0111111111111111";
  CONSTANT TB_MAC_MIN_VALUE_0  : signed(bit_width - 1 DOWNTO 0)     := "1000000000000000";
  CONSTANT TB_MAC_MAX_VALUE_00 : signed(bit_width / 2 - 1 DOWNTO 0) := "01111111";
  CONSTANT TB_MAC_MIN_VALUE_00 : signed(bit_width / 2 - 1 DOWNTO 0) := "10000000";

  CONSTANT TB_OUT_MAX_VALUE    : signed(bit_width - 1 DOWNTO 0)     := "0111111111111111";
  CONSTANT TB_OUT_MIN_VALUE    : signed(bit_width - 1 DOWNTO 0)     := "1000000000000000";
  CONSTANT TB_OUT_MAX_VALUE_0  : signed(bit_width/2 - 1 DOWNTO 0)   := "01111111";
  CONSTANT TB_OUT_MIN_VALUE_0  : signed(bit_width/2 - 1 DOWNTO 0)   := "10000000";
  CONSTANT TB_OUT_MAX_VALUE_00 : signed(bit_width/4 - 1 DOWNTO 0)   := "0111";
  CONSTANT TB_OUT_MIN_VALUE_00 : signed(bit_width/4 - 1 DOWNTO 0)   := "1000";

  TYPE in_out_data IS RECORD
    data     : signed(bit_width - 1 DOWNTO 0);
    data_0   : signed(WIDTH_L - 1 DOWNTO 0);
    data_1   : signed(WIDTH_H - 1 DOWNTO 0);
    data_00  : signed(WIDTH_2L - 1 DOWNTO 0);
    data_01  : signed(WIDTH_2L - 1 DOWNTO 0);
    data_10  : signed(WIDTH_2L - 1 DOWNTO 0);
    data_11  : signed(WIDTH_2H - 1 DOWNTO 0);
    DUT_data : STD_LOGIC_VECTOR(bit_width - 1 DOWNTO 0);
  END RECORD;

  --! Function that populates a in-and-out record.
  --! This functions can be used for both the driving of the DUT, as well as
  --! for recording the reference results in to a record.
  --! \param value    : integer value to be recorded
  --! \param op       : type of operation to used (00: 16-bit, 01: 8-bit, 11: 4-bit)
  --! \return in_out_data, populated record
  FUNCTION populate_in_out_rec (value : INTEGER; op : STD_LOGIC_VECTOR) RETURN in_out_data;
  --! Function that populates a in-and-out record (used for monitoring)
  --! \param value    : std_logic_vector to be recorded
  --! \param op       : type of operation to used (00: 16-bit, 01: 8-bit, 11: 4-bit)
  --! \return in_out_data, populated record
  FUNCTION populate_in_out_rec (value : STD_LOGIC_VECTOR; op : STD_LOGIC_VECTOR) RETURN in_out_data;
  --! Function that populates a in-and-out record (used for the reference results from the tb).
  --! It is given two input values, that will be recorded as 8 bits. Only used when op is 8-bit (11).
  --! The input values are given as integers and the function will saturate accordingly.
  --! !NOTE! Only the data_0, data_1, and DUT_data fields will be populated, the rest will be 0.
  --! \param value_1  : integer 2 to be recorded (MSBs)
  --! \param value_0  : integer 1 to be recorded (LSBs)
  --! \return in_out_data, populated record
  FUNCTION populate_in_out_rec (value_1 : INTEGER; value_0 : INTEGER) RETURN in_out_data;
  --! Function that populates a in-and-out record (used for the reference results from the tb).
  --! It is given four input values, that will be recorded as 4 bits. Only used when op is 4-bit (11).
  --! The input values are given as integers and the function will saturate accordingly.
  --! !NOTE! Only the data_00, data_01, data_10, data_11, and DUT_data fields will be populated, the rest will be 0.
  --! \param value_11  : integer 4 to be recorded (MSBs)
  --! \param value_10  : integer 3 to be recorded
  --! \param value_01  : integer 2 to be recorded
  --! \param value_00  : integer 1 to be recorded (LSBs)
  --! \return in_out_data, populated record
  FUNCTION populate_in_out_rec (value_11 : INTEGER; value_10 : INTEGER; value_01 : INTEGER; value_00 : INTEGER) RETURN in_out_data;
  --! Function that resets a in-and-out record (used for monitoring)
  --! \return in_out_data, populated record
  FUNCTION reset_in_out_rec RETURN in_out_data;
  --! Print MAC function.
  --! This function can be used to print the result and inputs
  --! /param mac    : integer input, result of the MAC
  --! /param input0 : integer input, first input of the MAC
  --! /param input1 : integer input, second input of the MAC
  PROCEDURE print_mac (mac, input0, input1 : IN INTEGER);
END PACKAGE;

PACKAGE BODY tb_pkg_dpu IS

  FUNCTION populate_in_out_rec (value : INTEGER; op : STD_LOGIC_VECTOR) RETURN in_out_data IS
    VARIABLE sig_value  : signed(bit_width - 1 DOWNTO 0);
    VARIABLE tmp_record : in_out_data;
  BEGIN
    sig_value          := to_signed(value, sig_value'length);
    tmp_record.data    := sig_value;
    tmp_record.data_0  := sig_value(WIDTH_L - 1 DOWNTO 0);
    tmp_record.data_1  := sig_value(bit_width - 1 DOWNTO WIDTH_L);
    tmp_record.data_00 := sig_value(WIDTH_2L - 1 DOWNTO 0);
    tmp_record.data_01 := sig_value(WIDTH_L - 1 DOWNTO WIDTH_2L);
    tmp_record.data_10 := sig_value(WIDTH_2H + WIDTH_L - 1 DOWNTO WIDTH_L);
    tmp_record.data_11 := sig_value(bit_width - 1 DOWNTO WIDTH_2H + WIDTH_L);
    CASE op IS
      WHEN "00" =>
        tmp_record.DUT_data := STD_LOGIC_VECTOR(tmp_record.data);
      WHEN "01" =>
        tmp_record.DUT_data := STD_LOGIC_VECTOR(tmp_record.data_1) & STD_LOGIC_VECTOR(tmp_record.data_0);
      WHEN "11" =>
        tmp_record.DUT_data := STD_LOGIC_VECTOR(tmp_record.data_11) & STD_LOGIC_VECTOR(tmp_record.data_10) & STD_LOGIC_VECTOR(tmp_record.data_01) & STD_LOGIC_VECTOR(tmp_record.data_00);
      WHEN OTHERS =>
        NULL;
    END CASE;
    RETURN tmp_record;
  END FUNCTION;

  FUNCTION populate_in_out_rec (value : STD_LOGIC_VECTOR; op : STD_LOGIC_VECTOR) RETURN in_out_data IS
    VARIABLE tmp_record : in_out_data;
  BEGIN
    tmp_record.data    := signed(value);
    tmp_record.data_0  := signed(value(WIDTH_L - 1 DOWNTO 0));
    tmp_record.data_1  := signed(value(bit_width - 1 DOWNTO WIDTH_L));
    tmp_record.data_00 := signed(value(WIDTH_2L - 1 DOWNTO 0));
    tmp_record.data_01 := signed(value(WIDTH_L - 1 DOWNTO WIDTH_2L));
    tmp_record.data_10 := signed(value(WIDTH_2H + WIDTH_L - 1 DOWNTO WIDTH_L));
    tmp_record.data_11 := signed(value(bit_width - 1 DOWNTO WIDTH_2H + WIDTH_L));
    CASE op IS
      WHEN "00" =>
        tmp_record.DUT_data := STD_LOGIC_VECTOR(tmp_record.data);
      WHEN "01" =>
        tmp_record.DUT_data := STD_LOGIC_VECTOR(tmp_record.data_1) & STD_LOGIC_VECTOR(tmp_record.data_0);
      WHEN "11" =>
        tmp_record.DUT_data := STD_LOGIC_VECTOR(tmp_record.data_11) & STD_LOGIC_VECTOR(tmp_record.data_10) & STD_LOGIC_VECTOR(tmp_record.data_01) & STD_LOGIC_VECTOR(tmp_record.data_00);
      WHEN OTHERS =>
        NULL;
    END CASE;
    RETURN tmp_record;
  END FUNCTION;

  FUNCTION populate_in_out_rec (value_1 : INTEGER; value_0 : INTEGER) RETURN in_out_data IS
    VARIABLE tmp_record : in_out_data;
  BEGIN
    tmp_record.data     := (OTHERS => '0');
    tmp_record.data_0   := saturation(value_0, TB_OUT_MAX_VALUE_0, TB_OUT_MIN_VALUE_0);
    tmp_record.data_1   := saturation(value_0, TB_OUT_MAX_VALUE_0, TB_OUT_MIN_VALUE_0);
    tmp_record.data_00  := (OTHERS => '0');
    tmp_record.data_01  := (OTHERS => '0');
    tmp_record.data_10  := (OTHERS => '0');
    tmp_record.data_11  := (OTHERS => '0');
    tmp_record.DUT_data := STD_LOGIC_VECTOR(tmp_record.data_1) & STD_LOGIC_VECTOR(tmp_record.data_0);
    RETURN tmp_record;
  END FUNCTION;

  FUNCTION populate_in_out_rec (value_11 : INTEGER; value_10 : INTEGER; value_01 : INTEGER; value_00 : INTEGER) RETURN in_out_data IS
    VARIABLE tmp_record : in_out_data;
  BEGIN
    tmp_record.data     := (OTHERS => '0');
    tmp_record.data_0   := (OTHERS => '0');
    tmp_record.data_1   := (OTHERS => '0');
    tmp_record.data_00  := saturation(value_00, TB_OUT_MAX_VALUE_00, TB_OUT_MIN_VALUE_00);
    tmp_record.data_01  := saturation(value_01, TB_OUT_MAX_VALUE_00, TB_OUT_MIN_VALUE_00);
    tmp_record.data_10  := saturation(value_10, TB_OUT_MAX_VALUE_00, TB_OUT_MIN_VALUE_00);
    tmp_record.data_11  := saturation(value_11, TB_OUT_MAX_VALUE_00, TB_OUT_MIN_VALUE_00);
    tmp_record.DUT_data := STD_LOGIC_VECTOR(tmp_record.data_11) & STD_LOGIC_VECTOR(tmp_record.data_10) & STD_LOGIC_VECTOR(tmp_record.data_01) & STD_LOGIC_VECTOR(tmp_record.data_00);
    RETURN tmp_record;
  END FUNCTION;

  FUNCTION reset_in_out_rec RETURN in_out_data IS
    VARIABLE tmp_record : in_out_data;
  BEGIN
    tmp_record.data     := (OTHERS => '0');
    tmp_record.data_0   := (OTHERS => '0');
    tmp_record.data_1   := (OTHERS => '0');
    tmp_record.data_00  := (OTHERS => '0');
    tmp_record.data_01  := (OTHERS => '0');
    tmp_record.data_10  := (OTHERS => '0');
    tmp_record.data_11  := (OTHERS => '0');
    tmp_record.DUT_data := (OTHERS => '0');
    RETURN tmp_record;
  END FUNCTION;

  PROCEDURE print_mac (mac, input0, input1 : IN INTEGER) IS
    VARIABLE my_line                         : line;
  BEGIN
    write(my_line, STRING'("input 0 : "));
    write(my_line, input0);
    write(my_line, STRING'(" input 1 : "));
    write(my_line, input1);
    writeline(output, my_line);
    write(my_line, STRING'("MAC : "));
    write(my_line, mac);
    writeline(output, my_line);
  END PROCEDURE;

END PACKAGE BODY;