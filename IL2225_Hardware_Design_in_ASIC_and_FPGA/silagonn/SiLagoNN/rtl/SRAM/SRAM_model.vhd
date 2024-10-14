-------------------------------------------------------
--! @file SRAM_model.vhd
--! @brief SRAM abstracct model
--! @details Only to be used for simulation !!!!
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2020-01-24
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
-- Title      : SRAM abstract model
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : SRAM_model.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2020-01-24
-- Last update: 2021-09-02
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2020
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2020-01-24  1.0      Dimitrios Stathis      Created
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

--! IEEE Library and work
library IEEE, work;
--! Use standard library
use IEEE.std_logic_1164.all;
--! Use numeric standard library for arithmetic operations
use ieee.numeric_std.all;
--! Use top_consts_types_package package
use work.top_consts_types_package.all;

--! Basic Model of a synchronous SRAM

--! This a simple SRAM model, only used for simulations. 
--! The SRAM models the behavior of a 128 bit-width SRAM with Chip Enable,
--! Write enable, sleep mode, shutdown mode and write through. 
entity SRAM_model is
  port
    (
      SLP   : in  std_logic;            --! Sleep mode, active high - asynch
      SD    : in  std_logic;            --! Shut down mode, active high - asynch
      CLK   : in  std_logic;            --! Clock 
      CEB   : in  std_logic;            --! Chip enable, active low
      WEB   : in  std_logic;            --! Write enable, active low
      CEBM  : in  std_logic;  --! Chip enable for BIST mode, active low !!!Not Modeled!!! used here to be compatible with actual SRAM
      WEBM  : in  std_logic;  --! Write enable for BIST, active low !!!Not Modeled!!! used here to be compatible with actual SRAM
      AWT   : in  std_logic;            --! Asynch write through
      A     : in  std_logic_vector(6 downto 0);  --! Address input
      D     : in  std_logic_vector(127 downto 0);  --! Data input
      BWEB  : in  std_logic_vector(127 downto 0);  --! Bit write enable, active low, used together with AWT only
      AM    : in  std_logic_vector(6 downto 0);  --! Address input for BIST mode !!!Not Modeled!!! used here to be compatible with actual SRAM
      DM    : in  std_logic_vector(127 downto 0);  --! Data input for BIST mode !!!Not Modeled!!! used here to be compatible with actual SRAM
      BWEBM : in  std_logic_vector(127 downto 0);  --! Bit write enable for BIST mode, active low!!!Not Modeled!!! used here to be compatible with actual SRAM
      BIST  : in  std_logic;            --! BIST interface enable, active high
      Q     : out std_logic_vector(127 downto 0)   --! Data out
      );
end SRAM_model;

--! @brief Behaviour of the SRAM
--! @details A simple model that simulates the behavior of an SRAM
architecture RTL of SRAM_model is
  -- tell synthesis tool to ignore code
  type memory_ty is array (natural range <>) of std_logic_vector(127 downto 0);
  shared variable memory : memory_ty(SRAM_DEPTH - 1 downto 0) := (others => (others => '0'));
  signal OLD             : std_logic_vector(127 downto 0);
begin
  -- SLP  No read no write keep data
  -- SD   Shut down (loose data)
  -- CEB  Chip enable
  -- WEB  Write enable
  -- AWT  Write throuugh 
  -- A    Address 
  -- D    Data in 
  -- Q    Data out


  -- cadence translate_off
  Memory_write : process (clk, CEB, SD, SLP)
  begin
    if (SD = '1') then
      memory := (others => (others => 'X'));
      OLD    <= (others => '0');
    elsif (CEB = '0') and (SLP = '0') then  -- If not sleep mode and chip-enabeled then disable the in/out
      if rising_edge(clk) then
        if (WEB = '0') then
          memory(to_integer(unsigned(A))) := D;
        else
          OLD <= memory(to_integer(unsigned(A)));
        end if;
      end if;
    end if;

  end process Memory_write;
  Memory_read : process (clk, CEB, SD, SLP, WEB)
  begin
    if rising_edge(clk) then 
    if (SD = '1') then
      Q <= (others => '0');
    elsif (CEB = '0') and (SLP = '0') then  -- If not sleep mode and chip-enabeled then disable the in/out
      if (WEB = '1') then
        Q <= memory(to_integer(unsigned(A)));
      else
        if (AWT = '1') then
          Q <= memory(to_integer(unsigned(A)));
        else
          Q <= BWEB xor OLD;
        end if;
      end if;
    else
      if (CEB = '1') then                  --! Chip not enabled
        Q <= OLD;
      else
        if (SLP = '1') then
          Q <= (others => '0');
        end if;
      end if;
    end if;
    end if;

  end process Memory_read;
-- cadence translate_on
end RTL;
