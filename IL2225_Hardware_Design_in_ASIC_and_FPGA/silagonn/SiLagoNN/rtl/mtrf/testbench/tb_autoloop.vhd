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
--! @brief 
--! @details
ARCHITECTURE autoloop OF testbench IS
    SIGNAL rst_n             : STD_LOGIC := '0';                                              --! Reset (active-low)
    SIGNAL clk               : STD_LOGIC := '0';                                              --! Clock
    SIGNAL instr_loop        : std_logic;                                                     --! Bit signaling the configuration of the autoloop unit.
    SIGNAL config_loop       : For_instr_ty;                                                  --! Configuration input of autoloop
    SIGNAL pc                : unsigned(PC_SIZE - 1 DOWNTO 0);                                --! Program counter.
    SIGNAL done              : std_logic;                                                     --! Signal from the sequencer to show that the instruction execution has been completed.
    SIGNAL pc_out            : unsigned(PC_SIZE - 1 DOWNTO 0);                                --! GOTO Program counter.
    SIGNAL jump              : std_logic;                                                     --! Signal the sequencer that the goto address should be the one used to update the program 
    SIGNAL raccu_in1_sd      : std_logic;                                                     --! Static or dynamic operand 1
    SIGNAL raccu_in1         : std_logic_vector (RACCU_OPERAND1_VECTOR_SIZE - 1 DOWNTO 0);    --! Value of operand 1 or address of RACCU RF when dynamic
    SIGNAL raccu_in2_sd      : std_logic;                                                     --! Static or dynamic operand 2
    SIGNAL raccu_in2         : std_logic_vector (RACCU_OPERAND2_VECTOR_SIZE - 1 DOWNTO 0);    --! Value of operand 2 or address of RACCU RF when dynamic
    SIGNAL raccu_cfg_mode    : std_logic_vector (RACCU_MODE_SEL_VECTOR_SIZE - 1 DOWNTO 0);    --! RACCU mode
    SIGNAL raccu_res_address : std_logic_vector (RACCU_RESULT_ADDR_VECTOR_SIZE - 1 DOWNTO 0); --! RF address where to store the result of the operation
    SIGNAL en                : std_logic_vector(RACCU_REGFILE_DEPTH - 1 DOWNTO 0);            --! Enable for the RACCU register file
    SIGNAL raccu_regout      : raccu_reg_out_ty;                                              --! Output values from the RACCU RF
BEGIN

    rst_n <= '0', '1' AFTER 4 ns;
    clk   <= NOT clk AFTER 2.5 ns;

    pc_proc : PROCESS (clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            pc <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            pc <= pc + 1;
            IF jump = '1' THEN
                pc <= pc_out;
            END IF;
        END IF;
    END PROCESS pc_proc;

    en <= (OTHERS => '1');

    CONFIGURATION_proc : PROCESS (clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            instr_loop                <= '0';
            config_loop.loop_id       <= (OTHERS => '0');
            config_loop.end_pc        <= (OTHERS => '0');
            config_loop.start_pc      <= (OTHERS => '0');
            config_loop.start_sd      <= '0';
            config_loop.start         <= (OTHERS => '0');
            config_loop.iter_sd       <= '0';
            config_loop.iter          <= (OTHERS => '0');
            config_loop.default_step  <= '0';
            config_loop.step_sd       <= '0';
            config_loop.step          <= (OTHERS => '0');
            config_loop.related_loops <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF pc = 1 THEN -- Issue in pc = 2
                config_loop.loop_id       <= to_unsigned(0, config_loop.loop_id'length);
                config_loop.start_pc      <= to_unsigned(3, config_loop.start_pc'LENGTH);
                config_loop.end_pc        <= to_unsigned(10, config_loop.end_pc'length);
                config_loop.start_sd      <= '0';
                config_loop.start         <= to_signed(1, config_loop.start'length);
                config_loop.iter_sd       <= '0';
                config_loop.iter          <= to_unsigned(3, config_loop.iter'length);
                config_loop.default_step  <= '0';
                config_loop.step_sd       <= '0';
                config_loop.step          <= to_signed(1, config_loop.step'length);
                config_loop.related_loops <= (OTHERS => '0');
                instr_loop                <= '1';
            ELSIF pc = 3 THEN -- Issue in pc = 4
                config_loop.loop_id       <= to_unsigned(1, config_loop.loop_id'length);
                config_loop.start_pc      <= to_unsigned(5, config_loop.start_pc'LENGTH);
                config_loop.end_pc        <= to_unsigned(10, config_loop.end_pc'length);
                config_loop.start_sd      <= '0';
                config_loop.start         <= to_signed(1, config_loop.start'length);
                config_loop.iter_sd       <= '0';
                config_loop.iter          <= to_unsigned(2, config_loop.iter'length);
                config_loop.default_step  <= '0';
                config_loop.step_sd       <= '0';
                config_loop.step          <= to_signed(2, config_loop.step'length);
                config_loop.related_loops <= "0001";
                instr_loop                <= '1';
            ELSIF pc = 5 THEN -- Issue in pc = 6
                config_loop.loop_id       <= to_unsigned(2, config_loop.loop_id'length);
                config_loop.start_pc      <= to_unsigned(7, config_loop.start_pc'LENGTH);
                config_loop.end_pc        <= to_unsigned(8, config_loop.end_pc'length);
                config_loop.start_sd      <= '0';
                config_loop.start         <= to_signed(-3, config_loop.start'length);
                config_loop.iter_sd       <= '0';
                config_loop.iter          <= to_unsigned(2, config_loop.iter'length);
                config_loop.default_step  <= '0';
                config_loop.step_sd       <= '0';
                config_loop.step          <= to_signed(-1, config_loop.step'length);
                config_loop.related_loops <= (OTHERS => '0');
                instr_loop                <= '1';
            ELSIF pc = 12 THEN -- Issue in pc = 13
                config_loop.loop_id       <= to_unsigned(0, config_loop.loop_id'length);
                config_loop.start_pc      <= to_unsigned(14, config_loop.start_pc'LENGTH);
                config_loop.end_pc        <= to_unsigned(15, config_loop.end_pc'length);
                config_loop.start_sd      <= '0';
                config_loop.start         <= to_signed(5, config_loop.start'length);
                config_loop.iter_sd       <= '0';
                config_loop.iter          <= to_unsigned(4, config_loop.iter'length);
                config_loop.default_step  <= '0';
                config_loop.step_sd       <= '0';
                config_loop.step          <= to_signed(5, config_loop.step'length);
                config_loop.related_loops <= (OTHERS => '0');
                instr_loop                <= '1';
            ELSE
                instr_loop                <= '0';
                config_loop.loop_id       <= (OTHERS => '0');
                config_loop.end_pc        <= (OTHERS => '0');
                config_loop.start_sd      <= '0';
                config_loop.start         <= (OTHERS => '0');
                config_loop.iter_sd       <= '0';
                config_loop.iter          <= (OTHERS => '0');
                config_loop.default_step  <= '0';
                config_loop.step_sd       <= '0';
                config_loop.step          <= (OTHERS => '0');
                config_loop.related_loops <= (OTHERS => '0');
            END IF;
        END IF;
    END PROCESS CONFIGURATION_proc;

    DUT : ENTITY work.RaccuAndLoop
        PORT MAP(
            rst_n             => rst_n,
            clk               => clk,
            instr_loop        => instr_loop,
            config_loop       => config_loop,
            pc                => pc,
            --done              => done,
            pc_out            => pc_out,
            jump              => jump,
            raccu_in1_sd      => raccu_in1_sd,
            raccu_in1         => raccu_in1,
            raccu_in2_sd      => raccu_in2_sd,
            raccu_in2         => raccu_in2,
            raccu_cfg_mode    => raccu_cfg_mode,
            raccu_res_address => raccu_res_address,
            en                => en,
            raccu_regout      => raccu_regout
        );

    PROCESS (PC)
    BEGIN
        IF (pc = 60) THEN
            std.env.finish;
        END IF;
    END PROCESS;
END autoloop;