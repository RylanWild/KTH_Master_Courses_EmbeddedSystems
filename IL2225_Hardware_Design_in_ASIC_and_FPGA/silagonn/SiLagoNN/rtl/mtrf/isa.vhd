
-- !!! AUTOMATICALLY GENERATED FILE, DON'T EDIT IT !!!

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

LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE isa_package IS
    
    TYPE HALT_instr_type IS RECORD
        instr_code : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
    END RECORD;
    TYPE REFI_instr_type IS RECORD
        instr_code : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        port_no : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
        extra : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
        init_addr_sd : STD_LOGIC;
        init_addr : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
        l1_iter : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
        init_delay : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
        l1_iter_sd : STD_LOGIC;
        init_delay_sd : STD_LOGIC;
        l1_step_sd : STD_LOGIC;
        l1_step : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
        l1_step_sign : STD_LOGIC;
        l1_delay_sd : STD_LOGIC;
        l1_delay : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        l2_iter_sd : STD_LOGIC;
        l2_iter : STD_LOGIC_VECTOR(5 - 1 DOWNTO 0);
        l2_step : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        l2_delay_sd : STD_LOGIC;
        l2_delay : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
        l1_delay_ext : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
        l2_iter_ext : STD_LOGIC;
        l2_step_ext : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
        dimarch : STD_LOGIC;
        compress : STD_LOGIC;
    END RECORD;
    TYPE DPU_instr_type IS RECORD
        instr_code : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        mode : STD_LOGIC_VECTOR(5 - 1 DOWNTO 0);
        control : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
        acc_clear : STD_LOGIC_VECTOR(8 - 1 DOWNTO 0);
        io_change : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
    END RECORD;
    TYPE SWB_instr_type IS RECORD
        instr_code : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        src_row : STD_LOGIC;
        src_block : STD_LOGIC;
        src_port : STD_LOGIC;
        hb_index : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0);
        send_to_other_row : STD_LOGIC;
        v_index : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0);
    END RECORD;
    TYPE JUMP_instr_type IS RECORD
        instr_code : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        pc : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
    END RECORD;
    TYPE WAIT_instr_type IS RECORD
        instr_code : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        cycle_sd : STD_LOGIC;
        cycle : STD_LOGIC_VECTOR(15 - 1 DOWNTO 0);
    END RECORD;
    TYPE LOOP_instr_type IS RECORD
        instr_code : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        extra : STD_LOGIC;
        loopid : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
        endpc : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
        start_sd : STD_LOGIC;
        start : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
        iter_sd : STD_LOGIC;
        iter : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
        step_sd : STD_LOGIC;
        step : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
        link : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
    END RECORD;
    TYPE RACCU_instr_type IS RECORD
        instr_code : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        mode : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0);
        operand1_sd : STD_LOGIC;
        operand1 : STD_LOGIC_VECTOR(7 - 1 DOWNTO 0);
        operand2_sd : STD_LOGIC;
        operand2 : STD_LOGIC_VECTOR(7 - 1 DOWNTO 0);
        result : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
    END RECORD;
    TYPE BRANCH_instr_type IS RECORD
        instr_code : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        mode : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
        false_pc : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
    END RECORD;
    TYPE ROUTE_instr_type IS RECORD
        instr_code : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        horizontal_dir : STD_LOGIC;
        horizontal_hops : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0);
        vertical_dir : STD_LOGIC;
        vertical_hops : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0);
        direction : STD_LOGIC;
        select_drra_row : STD_LOGIC;
    END RECORD;
    TYPE SRAM_instr_type IS RECORD
        instr_code : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        rw : STD_LOGIC;
        init_addr : STD_LOGIC_VECTOR(7 - 1 DOWNTO 0);
        init_delay : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
        l1_iter : STD_LOGIC_VECTOR(7 - 1 DOWNTO 0);
        l1_step : STD_LOGIC_VECTOR(8 - 1 DOWNTO 0);
        l1_delay : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
        l2_iter : STD_LOGIC_VECTOR(7 - 1 DOWNTO 0);
        l2_step : STD_LOGIC_VECTOR(8 - 1 DOWNTO 0);
        l2_delay : STD_LOGIC_VECTOR(6 - 1 DOWNTO 0);
        init_addr_sd : STD_LOGIC;
        l1_iter_sd : STD_LOGIC;
        l2_iter_sd : STD_LOGIC;
        init_delay_sd : STD_LOGIC;
        l1_delay_sd : STD_LOGIC;
        l2_delay_sd : STD_LOGIC;
        l1_step_sd : STD_LOGIC;
        l2_step_sd : STD_LOGIC;
        hops : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
    END RECORD;

    
    FUNCTION unpack_HALT_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN HALT_instr_type;
    FUNCTION unpack_REFI1_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN REFI_instr_type;
    FUNCTION unpack_REFI2_record(arg : std_logic_vector(54 - 1 DOWNTO 0)) RETURN REFI_instr_type;
    FUNCTION unpack_REFI3_record(arg : std_logic_vector(81 - 1 DOWNTO 0)) RETURN REFI_instr_type;
    FUNCTION unpack_DPU_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN DPU_instr_type;
    FUNCTION unpack_SWB_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN SWB_instr_type;
    FUNCTION unpack_JUMP_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN JUMP_instr_type;
    FUNCTION unpack_WAIT_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN WAIT_instr_type;
    FUNCTION unpack_LOOP1_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN LOOP_instr_type;
    FUNCTION unpack_LOOP2_record(arg : std_logic_vector(54 - 1 DOWNTO 0)) RETURN LOOP_instr_type;
    FUNCTION unpack_RACCU_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN RACCU_instr_type;
    FUNCTION unpack_BRANCH_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN BRANCH_instr_type;
    FUNCTION unpack_ROUTE_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN ROUTE_instr_type;
    FUNCTION unpack_SRAM1_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN SRAM_instr_type;
    FUNCTION unpack_SRAM2_record(arg : std_logic_vector(54 - 1 DOWNTO 0)) RETURN SRAM_instr_type;
    FUNCTION unpack_SRAM3_record(arg : std_logic_vector(81 - 1 DOWNTO 0)) RETURN SRAM_instr_type;
END;

PACKAGE BODY isa_package IS
    
    FUNCTION unpack_HALT_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN HALT_instr_type IS
        VARIABLE result : HALT_instr_type;
    BEGIN
        result.instr_code := arg(26 DOWNTO 23);
        RETURN result;
    END;
    
    FUNCTION unpack_REFI1_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN REFI_instr_type IS
        VARIABLE result : REFI_instr_type;
    BEGIN
        result.instr_code := arg(26 DOWNTO 23);
        result.port_no := arg(22 DOWNTO 21);
        result.extra := arg(20 DOWNTO 19);
        result.init_addr_sd := arg(18);
        result.init_addr := arg(17 DOWNTO 12);
        result.l1_iter := arg(11 DOWNTO 6);
        result.init_delay := arg(5 DOWNTO 0);
        result.l1_iter_sd := '0';
        result.init_delay_sd := '0';
        result.l1_step_sd := '0';
        result.l1_step := std_logic_vector(to_unsigned(1, 6));
        result.l1_step_sign := '0';
        result.l1_delay_sd := '0';
        result.l1_delay := std_logic_vector(to_unsigned(0, 4));
        result.l2_iter_sd := '0';
        result.l2_iter := std_logic_vector(to_unsigned(0, 5));
        result.l2_step := std_logic_vector(to_unsigned(1, 4));
        result.l2_delay_sd := '0';
        result.l2_delay := std_logic_vector(to_unsigned(0, 6));
        result.l1_delay_ext := std_logic_vector(to_unsigned(0, 2));
        result.l2_iter_ext := '0';
        result.l2_step_ext := std_logic_vector(to_unsigned(0, 2));
        result.dimarch := '0';
        result.compress := '0';
        RETURN result;
    END;
    FUNCTION unpack_REFI2_record(arg : std_logic_vector(54 - 1 DOWNTO 0)) RETURN REFI_instr_type IS
        VARIABLE result : REFI_instr_type;
    BEGIN
        result.instr_code := arg(53 DOWNTO 50);
        result.port_no := arg(49 DOWNTO 48);
        result.extra := arg(47 DOWNTO 46);
        result.init_addr_sd := arg(45);
        result.init_addr := arg(44 DOWNTO 39);
        result.l1_iter := arg(38 DOWNTO 33);
        result.init_delay := arg(32 DOWNTO 27);
        result.l1_iter_sd := arg(26);
        result.init_delay_sd := arg(25);
        result.l1_step_sd := arg(22);
        result.l1_step := arg(21 DOWNTO 16);
        result.l1_step_sign := arg(15);
        result.l1_delay_sd := arg(14);
        result.l1_delay := arg(13 DOWNTO 10);
        result.l2_iter_sd := arg(9);
        result.l2_iter := arg(8 DOWNTO 4);
        result.l2_step := arg(3 DOWNTO 0);
        result.l2_delay_sd := '0';
        result.l2_delay := std_logic_vector(to_unsigned(0, 6));
        result.l1_delay_ext := std_logic_vector(to_unsigned(0, 2));
        result.l2_iter_ext := '0';
        result.l2_step_ext := std_logic_vector(to_unsigned(0, 2));
        result.dimarch := '0';
        result.compress := '0';
        RETURN result;
    END;
    FUNCTION unpack_REFI3_record(arg : std_logic_vector(81 - 1 DOWNTO 0)) RETURN REFI_instr_type IS
        VARIABLE result : REFI_instr_type;
    BEGIN
        result.instr_code := arg(80 DOWNTO 77);
        result.port_no := arg(76 DOWNTO 75);
        result.extra := arg(74 DOWNTO 73);
        result.init_addr_sd := arg(72);
        result.init_addr := arg(71 DOWNTO 66);
        result.l1_iter := arg(65 DOWNTO 60);
        result.init_delay := arg(59 DOWNTO 54);
        result.l1_iter_sd := arg(53);
        result.init_delay_sd := arg(52);
        result.l1_step_sd := arg(49);
        result.l1_step := arg(48 DOWNTO 43);
        result.l1_step_sign := arg(42);
        result.l1_delay_sd := arg(41);
        result.l1_delay := arg(40 DOWNTO 37);
        result.l2_iter_sd := arg(36);
        result.l2_iter := arg(35 DOWNTO 31);
        result.l2_step := arg(30 DOWNTO 27);
        result.l2_delay_sd := arg(22);
        result.l2_delay := arg(21 DOWNTO 16);
        result.l1_delay_ext := arg(9 DOWNTO 8);
        result.l2_iter_ext := arg(7);
        result.l2_step_ext := arg(6 DOWNTO 5);
        result.dimarch := arg(1);
        result.compress := arg(0);
        RETURN result;
    END;
    
    FUNCTION unpack_DPU_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN DPU_instr_type IS
        VARIABLE result : DPU_instr_type;
    BEGIN
        result.instr_code := arg(26 DOWNTO 23);
        result.mode := arg(22 DOWNTO 18);
        result.control := arg(17 DOWNTO 16);
        result.acc_clear := arg(9 DOWNTO 2);
        result.io_change := arg(1 DOWNTO 0);
        RETURN result;
    END;
    
    FUNCTION unpack_SWB_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN SWB_instr_type IS
        VARIABLE result : SWB_instr_type;
    BEGIN
        result.instr_code := arg(26 DOWNTO 23);
        result.src_row := arg(21);
        result.src_block := arg(20);
        result.src_port := arg(19);
        result.hb_index := arg(18 DOWNTO 16);
        result.send_to_other_row := arg(15);
        result.v_index := arg(14 DOWNTO 12);
        RETURN result;
    END;
    
    FUNCTION unpack_JUMP_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN JUMP_instr_type IS
        VARIABLE result : JUMP_instr_type;
    BEGIN
        result.instr_code := arg(26 DOWNTO 23);
        result.pc := arg(22 DOWNTO 17);
        RETURN result;
    END;
    
    FUNCTION unpack_WAIT_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN WAIT_instr_type IS
        VARIABLE result : WAIT_instr_type;
    BEGIN
        result.instr_code := arg(26 DOWNTO 23);
        result.cycle_sd := arg(22);
        result.cycle := arg(21 DOWNTO 7);
        RETURN result;
    END;
    
    FUNCTION unpack_LOOP1_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN LOOP_instr_type IS
        VARIABLE result : LOOP_instr_type;
    BEGIN
        result.instr_code := arg(26 DOWNTO 23);
        result.extra := arg(22);
        result.loopid := arg(21 DOWNTO 20);
        result.endpc := arg(19 DOWNTO 14);
        result.start_sd := arg(13);
        result.start := arg(12 DOWNTO 7);
        result.iter_sd := arg(6);
        result.iter := arg(5 DOWNTO 0);
        result.step_sd := '0';
        result.step := std_logic_vector(to_unsigned(1, 6));
        result.link := std_logic_vector(to_unsigned(0, 4));
        RETURN result;
    END;
    FUNCTION unpack_LOOP2_record(arg : std_logic_vector(54 - 1 DOWNTO 0)) RETURN LOOP_instr_type IS
        VARIABLE result : LOOP_instr_type;
    BEGIN
        result.instr_code := arg(53 DOWNTO 50);
        result.extra := arg(49);
        result.loopid := arg(48 DOWNTO 47);
        result.endpc := arg(46 DOWNTO 41);
        result.start_sd := arg(40);
        result.start := arg(39 DOWNTO 34);
        result.iter_sd := arg(33);
        result.iter := arg(32 DOWNTO 27);
        result.step_sd := arg(26);
        result.step := arg(25 DOWNTO 20);
        result.link := arg(19 DOWNTO 16);
        RETURN result;
    END;
    
    FUNCTION unpack_RACCU_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN RACCU_instr_type IS
        VARIABLE result : RACCU_instr_type;
    BEGIN
        result.instr_code := arg(26 DOWNTO 23);
        result.mode := arg(22 DOWNTO 20);
        result.operand1_sd := arg(19);
        result.operand1 := arg(18 DOWNTO 12);
        result.operand2_sd := arg(11);
        result.operand2 := arg(10 DOWNTO 4);
        result.result := arg(3 DOWNTO 0);
        RETURN result;
    END;
    
    FUNCTION unpack_BRANCH_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN BRANCH_instr_type IS
        VARIABLE result : BRANCH_instr_type;
    BEGIN
        result.instr_code := arg(26 DOWNTO 23);
        result.mode := arg(22 DOWNTO 21);
        result.false_pc := arg(20 DOWNTO 15);
        RETURN result;
    END;
    
    FUNCTION unpack_ROUTE_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN ROUTE_instr_type IS
        VARIABLE result : ROUTE_instr_type;
    BEGIN
        result.instr_code := arg(26 DOWNTO 23);
        result.horizontal_dir := arg(22);
        result.horizontal_hops := arg(21 DOWNTO 19);
        result.vertical_dir := arg(18);
        result.vertical_hops := arg(17 DOWNTO 15);
        result.direction := arg(14);
        result.select_drra_row := arg(13);
        RETURN result;
    END;
    
    FUNCTION unpack_SRAM1_record(arg : std_logic_vector(27 - 1 DOWNTO 0)) RETURN SRAM_instr_type IS
        VARIABLE result : SRAM_instr_type;
    BEGIN
        result.instr_code := arg(26 DOWNTO 23);
        result.rw := arg(22);
        result.init_addr := arg(21 DOWNTO 15);
        result.init_delay := arg(14 DOWNTO 11);
        result.l1_iter := arg(10 DOWNTO 4);
        result.l1_step := std_logic_vector(to_unsigned(1, 8));
        result.l1_delay := std_logic_vector(to_unsigned(0, 6));
        result.l2_iter := std_logic_vector(to_unsigned(0, 7));
        result.l2_step := std_logic_vector(to_unsigned(1, 8));
        result.l2_delay := std_logic_vector(to_unsigned(0, 6));
        result.init_addr_sd := '0';
        result.l1_iter_sd := '0';
        result.l2_iter_sd := '0';
        result.init_delay_sd := '0';
        result.l1_delay_sd := '0';
        result.l2_delay_sd := '0';
        result.l1_step_sd := '0';
        result.l2_step_sd := '0';
        result.hops := std_logic_vector(to_unsigned(0, 4));
        RETURN result;
    END;
    FUNCTION unpack_SRAM2_record(arg : std_logic_vector(54 - 1 DOWNTO 0)) RETURN SRAM_instr_type IS
        VARIABLE result : SRAM_instr_type;
    BEGIN
        result.instr_code := arg(53 DOWNTO 50);
        result.rw := arg(49);
        result.init_addr := arg(48 DOWNTO 42);
        result.init_delay := arg(41 DOWNTO 38);
        result.l1_iter := arg(37 DOWNTO 31);
        result.l1_step := arg(30 DOWNTO 23);
        result.l1_delay := arg(22 DOWNTO 17);
        result.l2_iter := arg(16 DOWNTO 10);
        result.l2_step := arg(9 DOWNTO 2);
        result.l2_delay := std_logic_vector(to_unsigned(0, 6));
        result.init_addr_sd := '0';
        result.l1_iter_sd := '0';
        result.l2_iter_sd := '0';
        result.init_delay_sd := '0';
        result.l1_delay_sd := '0';
        result.l2_delay_sd := '0';
        result.l1_step_sd := '0';
        result.l2_step_sd := '0';
        result.hops := std_logic_vector(to_unsigned(0, 4));
        RETURN result;
    END;
    FUNCTION unpack_SRAM3_record(arg : std_logic_vector(81 - 1 DOWNTO 0)) RETURN SRAM_instr_type IS
        VARIABLE result : SRAM_instr_type;
    BEGIN
        result.instr_code := arg(80 DOWNTO 77);
        result.rw := arg(76);
        result.init_addr := arg(75 DOWNTO 69);
        result.init_delay := arg(68 DOWNTO 65);
        result.l1_iter := arg(64 DOWNTO 58);
        result.l1_step := arg(57 DOWNTO 50);
        result.l1_delay := arg(49 DOWNTO 44);
        result.l2_iter := arg(43 DOWNTO 37);
        result.l2_step := arg(36 DOWNTO 29);
        result.l2_delay := arg(28 DOWNTO 23);
        result.init_addr_sd := arg(22);
        result.l1_iter_sd := arg(21);
        result.l2_iter_sd := arg(20);
        result.init_delay_sd := arg(19);
        result.l1_delay_sd := arg(18);
        result.l2_delay_sd := arg(17);
        result.l1_step_sd := arg(16);
        result.l2_step_sd := arg(15);
        result.hops := arg(14 DOWNTO 11);
        RETURN result;
    END;
    
END;