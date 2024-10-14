-------------------------------------------------------
--! @file priorityMux.vhd
--! @brief priority multiplexer
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2020-02-26
--! @bug NONE
--! @todo Move some of the generics to constants, code requires some clean up
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
-- Title      : priority multiplexer
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : priorityMux.vhd
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
--! Use of top constant and types package
USE work.top_consts_types_package.ALL;
--! Use of misc package for arithmetic non-synthesizable functions 
USE work.misc.ALL;

--! This is a priority mux. It selects the first "active" of N inputs 

--! The mux has N data inputs, M select/valid inputs and L outputs. The purpose of the mux 
--! is to select and output the first (higher priority) active input. Where the highest priority is input (0).
--!  It is build in a recursive form, layer by layer, each layer instantiating the next one.
ENTITY priorityMux IS
  GENERIC (
    LEVELS   : NATURAL := log2(MAX_NO_OF_LOOPS); --! Total number of layers
    i        : NATURAL := log2(MAX_NO_OF_LOOPS); --! Current Layer (0 to number of layers)
    N_sel_in : NATURAL := MAX_NO_OF_LOOPS;       --! Number of "select in" input bits
    N_in     : NATURAL := MAX_NO_OF_LOOPS;       --! Number of inputs
    N        : NATURAL := MAX_NO_OF_LOOPS        --! Number of Select bits (LEVELS**2)
  );
  PORT (
    ID_in  : IN priority_input_ty(N_in - 1 DOWNTO 0);    --! Input IDs 
    sel_in : IN STD_LOGIC_VECTOR(N_sel_in - 1 DOWNTO 0); --! Valid/select bits (from all loops)
    ID_out : OUT unsigned(FOR_LOOP_ID - 1 DOWNTO 0)      --! Output IDs 
  );
END priorityMux;

--! @brief 
--! @details Matlab code that explains the sequence nature of the bounds and  constants:
--! \verbatim
--! N = 16;
--! levels = log2(N);
--! 
--! FOR i = levels - 1 : - 1 : 0
--!     disp("--------------------")
--!     IF i == levels - 1
--!         disp("================")
--!         disp(strcat("State - Level : ", num2str(i + 1)))
--!         disp("First Layer (special selection)")
--!         n_in = 2^(i);
--!         n_out = 2^(i - 1);
--!         disp(strcat("No of Inputs (next state): ", num2str(n_in)))
--!         disp(strcat("No of Outputs (next state): ", num2str(n_out)))
--!         n_com = 2^i;
--!         disp(strcat("Number of components in layer is ", num2str(n_com)))
--!         disp("================")
--!         ELSE
--!         disp(strcat("State - Level : ", num2str(i + 1)))
--!         n_in = 2^(i);
--!         n_out = 2^(i - 1);
--!         IF i ~ = 0
--!             disp(strcat("No of Inputs (next state): ", num2str(n_in)))
--!             disp(strcat("No of Outputs (next state): ", num2str(n_out)))
--!             ELSE
--!             disp("No next state")
--!         END
--!         n_sel_bit = N/(2^(i + 1));
--!         disp(strcat("No of select bits (this state): ", num2str(n_sel_bit)))
--!         n_com = 2^i;
--!         disp(strcat("Number of components in layer is ", num2str(n_com)))
--!         disp("================")
--!         FOR j = 0 : n_com - 1
--!             j_s = j * (n_sel_bit) * 2;
--!             % start OF BIT vector
--!             j_e = (n_sel_bit + j_s) - 1;
--!             % END OF BIT vector
--!             disp(strcat(num2str(j_s), " to ", num2str(j_e)))
--!             disp(strcat("Inputs for this mux component: ", num2str(j * 2), " and ", num2str(j * 2 + 1)))
--!             disp(strcat("Output of this mux component: ", num2str(j)))
--!             disp("================")
--!         END
--!     END
--! END
--! disp("--------------------")
--! \endverbatim
--! The Structure can be seen in the following figure
--! TODO put a figure here
ARCHITECTURE RTL OF priorityMux IS

  COMPONENT priorityMux IS
    GENERIC (
      LEVELS   : NATURAL := log2(MAX_NO_OF_LOOPS); --! Total number of layers
      i        : NATURAL := log2(MAX_NO_OF_LOOPS); --! Current Layer (0 to number of layers)
      N_sel_in : NATURAL := MAX_NO_OF_LOOPS;       --! Number of "select in" input bits
      N_in     : NATURAL := MAX_NO_OF_LOOPS;       --! Number of inputs
      N        : NATURAL := MAX_NO_OF_LOOPS        --! Number of Select bits (LEVELS**2)
    );
    PORT (
      ID_in  : IN priority_input_ty(N_in - 1 DOWNTO 0);    --! Input IDs 
      sel_in : IN STD_LOGIC_VECTOR(N_sel_in - 1 DOWNTO 0); --! Valid/select bits (from all loops)
      ID_out : OUT unsigned(FOR_LOOP_ID - 1 DOWNTO 0)      --! Output IDs 
    );

  END COMPONENT;

  CONSTANT NO_OF_INTER_ID    : NATURAL := 2 ** (i);                            --! Number of outputs from this layer to the next
  CONSTANT N_OF_COMP         : NATURAL := NO_OF_INTER_ID;                      --! Number of internal components in this layer 
  CONSTANT NO_OF_COM_SEL_BIT : NATURAL := N/(2 ** (i + 1));                    --! Number of select inputs bits for the internal components of the layer
  CONSTANT LOW_BOUND         : NATURAL := NO_OF_COM_SEL_BIT * 2;               --! Low bound factor for select signals 
  SIGNAL ID_sig              : priority_input_ty(NO_OF_INTER_ID - 1 DOWNTO 0); --! Output of this layer to the next
  SIGNAL ID_out_tmp          : unsigned(FOR_LOOP_ID - 1 DOWNTO 0);             --! Temporary output used to propagate the output through the hierarchy 
BEGIN
  --! Special case for the first layer
  OUTER_LEVEL : IF i = (LEVELS - 1) GENERATE

    first_layer : FOR j IN 0 TO (N_in/2 - 1) GENERATE
      ID_sig(j) <= ID_in(j * 2) WHEN sel_in(j * 2) = '1' ELSE
      ID_in(j * 2 + 1);
    END GENERATE first_layer;

    --! Generate the next layer 
    layer_1 : priorityMux
    GENERIC MAP(
      LEVELS   => LEVELS,
      i        => i - 1,
      N_sel_in => N_sel_in,
      N_in     => NO_OF_INTER_ID,
      N        => N
    )
    PORT MAP(
      ID_in  => ID_sig,
      sel_in => sel_in,
      ID_out => ID_out_tmp
    );
  END GENERATE OUTER_LEVEL;

  --! For all other layers
  INNER_LEVEL : IF i /= (LEVELS - 1) GENERATE

    --! Generate the next layer 
    Layer_X : IF i /= 0 GENERATE
      gen_inner : FOR j IN 0 TO (N_OF_COMP - 1) GENERATE
        -- Basic Component
        mux_X : ENTITY work.priorityComponent
          GENERIC MAP(No_Select => NO_OF_COM_SEL_BIT)
          PORT MAP(
            ID_A   => ID_in(j * 2),     -- High priority ID
            ID_B   => ID_in(j * 2 + 1), -- Low priority ID
            sel_in => sel_in(((NO_OF_COM_SEL_BIT + j * LOW_BOUND) - 1) DOWNTO (j * LOW_BOUND)),
            ID_out => ID_sig(j)
          );
      END GENERATE gen_inner;

      layer_c_X : priorityMux
      GENERIC MAP(
        LEVELS   => LEVELS,
        i        => i - 1,
        N_sel_in => N_sel_in,
        N_in     => NO_OF_INTER_ID,
        N        => N
      )
      PORT MAP(
        ID_in  => ID_sig,
        sel_in => sel_in,
        ID_out => ID_out_tmp
      );
    END GENERATE layer_X;

    --! Exit (last) layer
    EXIT_tree : IF i = 0 GENERATE
      -- Basic Component
      mux_X : ENTITY work.priorityComponent
        GENERIC MAP(No_Select => (N/2))
        PORT MAP(
          ID_A   => ID_in(0), -- High priority ID
          ID_B   => ID_in(1), -- Low priority ID
          sel_in => sel_in((N/2 - 1) DOWNTO 0),
          ID_out => ID_out_tmp
        );
    END GENERATE EXIT_tree;

  END GENERATE INNER_LEVEL;

  ID_out <= ID_out_tmp;

END RTL;