-------------------------------------------------------
--! @file autoloop.vhd
--! @brief Auto loop management unit
--! @details 
--! @author Dimitrios Stathis
--! @version 1.0
--! @date 2020-02-24
--! @bug NONE
--! @todo Check if there is a need for storing the start value
--! @todo check if the related loop is needed or not
--! @todo The jump to end process might only needed when the loop has to exit immediately, otherwise it will continue with next pc
--! @todo The "Loop management for each loop" should be moved to a component "loop_fsm"
--! @fixme Remove default step, move it to sequencer.
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
-- Title      : Auto loop management unit
-- Project    : SiLago
-------------------------------------------------------------------------------
-- File       : autoloop.vhd
-- Author     : Dimitrios Stathis
-- Company    : KTH
-- Created    : 2020-02-24
-- Last update: 2020-02-24
-- Platform   : SiLago
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Copyright (c) 2020
-------------------------------------------------------------------------------
-- Contact    : Dimitrios Stathis <stathis@kth.se>
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2020-02-24  1.0      Dimitrios Stathis       Created
--             1.1      Dimitrios Stathis       Check for change in the PC before
--                                              updating the loop (bug when the
--                                              end PC is a delay instruction)
-- 2022-03-18  1.2      Dimitrios Stathis       Added function to iterate in the
--                                              same PC (i.e. start and end PC is the same)
-- 2022-03-21  1.3      Dimitrios Stathis       Added functionality to create the related_loops
--                                              flags so that the compiler doesn't have to.
--                      !!!IMPORTANT!!!         This rev should be reversed when the assembler
--                                              or compiler can calculate this information.
-- 2022-03-21  1.4      Dimitrios Stathis       Fixed issue when two loops have the same end PC
--                                              and one does not reset
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

--! IEEE and work library
LIBRARY IEEE, work;
--! Use standard library
USE IEEE.std_logic_1164.ALL;
--! Use numeric standard library for arithmetic operations
USE ieee.numeric_std.ALL;
--! Use top_constant package
USE work.top_consts_types_package.ALL;
--! Use misc package for the log2 function
USE work.misc.ALL;
--! Use ieee misc package for the or_reduce function
USE ieee.std_logic_misc.ALL;

--! Auto loop unit, get configured to automatically manage for loops. 

--!
ENTITY autoloop IS
  PORT (
    rst_n       : IN STD_LOGIC;                                      --! Reset (active-low)
    clk         : IN STD_LOGIC;                                      --! Clock
    --------------------------------------------------------------------------------
    -- Instruction input
    --------------------------------------------------------------------------------
    instr       : IN STD_LOGIC;                                      --! Bit signaling the configuration of the unit.
    config      : IN For_instr_ty;                                   --! Configuration input
    --------------------------------------------------------------------------------
    -- Extra inputs from the sequencer
    --------------------------------------------------------------------------------
    pc          : IN unsigned(PC_SIZE - 1 DOWNTO 0);                 --! Program counter.
    --done        : IN std_logic;                                      --! Signal from the sequencer to show that the instruction execution has been completed.
    pc_out      : OUT unsigned(PC_SIZE - 1 DOWNTO 0);                --! GOTO Program counter.
    jump        : OUT STD_LOGIC;                                     --! Signal the sequencer that the goto address should be the one used to update the program counter.
    ----------------------------------------------------
    -- REV 1.2 2022-03-18 ------------------------------
    ----------------------------------------------------
    is_delay    : IN STD_LOGIC;                                      --! Signal inferring that there is an active delay instruction
    ----------------------------------------------------
    -- End of modification REV 1.2 ---------------------
    ----------------------------------------------------
    --------------------------------------------------------------------------------
    -- RACCU Registers
    --------------------------------------------------------------------------------
    raccu_regs  : IN raccu_reg_out_ty;                               --! Contents of the RACCU registers
    iterators   : OUT loop_iterators_ty;                             --! Output new values for the iterator values
    active_iter : OUT STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0) --! Active bits, each bit is bound to an iterator. If '1' then the register holding the current value of the iterator will be updated with the value from the 'iterators' output 
  );
END autoloop;

--! @brief 
--! @details The auto-loop employees 4 different concurrent threads. 
--!     -  Thread 1: Configuration and 0 iteration loop checking thread \n
--!        This thread is triggered whenever a new configuration is coming in.
--!        If the incoming loop configuration has 0 iterations then: \n
--!        -# Signal that this loop is complete \n
--!        -# Check if other (previous loops) have the same end-pc as this \n
--!             - If they do, signal their update (thread 3) and signal the PC update (thread 4) \n
--!             - if they do not, signal the PC update (thread 4) \n
--!     - Thread 2: PC checking \n 
--!       This thread is receiving the current PC for the sequencer and compares it with the end-PC 
--!       of each loop. When it finds a match is signaling the update of the specific loop (thread 3) \n
--!     - Thread 3: Loop update \n
--!       This thread is triggered by the previous two threads (1 and 2). Each loop has its own unique thread.
--!       When the thread is active: \n
--!         -# It increments the loop counter and its iterator (part of the RACCU register) \n
--!         -# It checks to see if the loop has completed one or all its iteration \n
--!             - If it has completed one it signals the PC update (thread 4) with the new PC (PC-start) \n
--!             - If it has completed all then it signals the PC update (thread 4) accordingly \n
--!         -# The loop iterators and incrementors are updated in order (i.e. if more than one loops have the same end-PC 
--!            then the inner loop will updated first and only if it has completed all its iterations the next loop in the
--!            hierarchy will be updated) \n
--!     - Thread 4: PC update \n
--!       This thread is triggered from the previous threads (1 and 3) and it updates the PC according to the signals 
--!       from thread 3 and 1. If there are multiple loops that have finish one or all their iterations. If a loop has
--!       completed one iteration the the PC is updated to the head of the loop (PC-start).  \n
--! NOTE: The related loop field is only used when the loop has to exit before looping (0 iterations) 
ARCHITECTURE RTL OF autoloop IS
  CONSTANT LEVELS                        : NATURAL := log2(MAX_NO_OF_LOOPS);

  SIGNAL config_reg                      : loop_config_reg_ty;                              --! Configuration registers

  SIGNAL clear                           : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Signal to clear a configuration register

  SIGNAL incrementor_reg                 : incrementor_reg_ty;                              --! Incrementor registers 
  SIGNAL incrementor_next                : incrementor_reg_ty;                              --! New values for the incrementor registers

  SIGNAL loop_upd_from_0_loop            : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Update the loop when a new loop comes with 0 iterations
  SIGNAL upd_pc_from_0_loop              : STD_LOGIC;                                       --! Update the pc because of 0 loop 
  SIGNAL loop_upd_from_PC                : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Update the loop because of PC = end pc
  SIGNAL loop_upd_done_from_PC           : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Update the loop_done because of end PC = PC + 1
  SIGNAL loop_done                       : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Loop end pc matches with the current PC (register)

  SIGNAL skip_configuration_reg          : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Skip the configuration register and execute the loop
  SIGNAL upd_pc_trigger_to_end           : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! 

  SIGNAL ID_in                           : priority_input_ty(MAX_NO_OF_LOOPS - 1 DOWNTO 0); --! Input IDs to the priority mux
  SIGNAL ID_out                          : unsigned(FOR_LOOP_ID - 1 DOWNTO 0);              --! Output ID from the priority mux

  SIGNAL PC_update_to_end                : STD_LOGIC;                                       --! Signal used to trigger the PC_update

  SIGNAL jump_to_top_loop                : unsigned(FOR_LOOP_ID - 1 DOWNTO 0);              --! Loop ID to jump in the start of the loop
  SIGNAL jump_to_top                     : STD_LOGIC;                                       --! Signal to activate jump to top (Jump to top has a higher priority than jump to end)

  SIGNAL trigger                         : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Trigger signal for loop update
  SIGNAL trigger_done                    : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Trigger signal for loop_done update

  SIGNAL jump_to_top_atomic              : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Signal from each loop to jump on top
  SIGNAL increment_trigger               : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Trigger condition for increment

  SIGNAL any_done                        : STD_LOGIC;                                       --! Trigger if any loop done

  ----------------------------------------------------
  -- REV 1.2 -----------------------------------------
  ----------------------------------------------------
  --SIGNAL old_pc                 : unsigned(PC_SIZE - 1 DOWNTO 0);                  --! Signal that register the value of the PC to check for a change
  --SIGNAL pc_change              : STD_LOGIC;                                       --! Flag that signals the change of the PC
  ----------------------------------------------------
  -- End of modification REV 1.2 ---------------------
  ----------------------------------------------------

  ----------------------------------------------------
  -- REV 1.4 2022-03-21 ------------------------------
  ----------------------------------------------------
  SIGNAL loop_done_from_iter             : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Trigger flags that a loop is done when all the loop iterations complete
  --TYPE related_loops_array IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR (MAX_NO_OF_LOOPS - 1 DOWNTO 0);    --! This type creates an array of "related loop" flags
  --SIGNAL related_loops_monitor           : related_loops_array(MAX_NO_OF_LOOPS - 1 DOWNTO 0);                 --! When a new configuration comes in this will find and hold the related loops that have the same end_pc
  --CONSTANT related_zero                  : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0) := (OTHERS => '0'); --! Reset value for related loops
  SIGNAL not_active_or_triggered_to_done : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Signal that calculates if a loop is inactive or if it is triggered to be done
  SIGNAL prev_loops_triggered_to_done    : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Flags that signal if all previous loops have completed their iterations
  SIGNAL check_cond_for_done             : STD_LOGIC_VECTOR(MAX_NO_OF_LOOPS - 1 DOWNTO 0);  --! Result of the check condition for a loop to be done
  ----------------------------------------------------
  -- End of modification REV 1.4 ---------------------
  ----------------------------------------------------
BEGIN
  ----------------------------------------------------
  -- REV 1.3 2022-03-21 (reverted)--------------------
  ----------------------------------------------------
  --! This process checks when there is a new configuration, if any of the other loops are related
  --relations_p : PROCESS (instr, config, config_reg)
  --BEGIN
  --  FOR loop_n IN 0 TO MAX_NO_OF_LOOPS - 1 LOOP
  --    related_loops_monitor(loop_n) <= config_reg(loop_n).related_loops;
  --  END LOOP;
  --  IF instr = '1' THEN
  --    FOR loop_n IN 0 TO MAX_NO_OF_LOOPS - 1 LOOP
  --      IF (loop_n /= to_integer(config.loop_id)) THEN
  --        IF (config_reg(loop_n).end_pc = config.end_pc) THEN
  --          related_loops_monitor(loop_n)(to_integer(config.loop_id)) <= '1';
  --          related_loops_monitor(to_integer(config.loop_id))(loop_n) <= '1';
  --        END IF;
  --      ELSE
  --        related_loops_monitor(loop_n)(loop_n) <= '1';
  --      END IF;
  --    END LOOP;
  --  END IF;
  --END PROCESS;
  ----------------------------------------------------
  -- End of modification REV 1.3 (reverted)-----------
  ----------------------------------------------------
  --! This process checks if the loop should be executed (i.e. if  number of iterations >0 )
  zero_loop : PROCESS (instr, config, raccu_regs)
    VARIABLE iterations : unsigned(FOR_ITER - 1 DOWNTO 0);
  BEGIN
    loop_upd_from_0_loop   <= (OTHERS => '0');
    skip_configuration_reg <= (OTHERS => '0');
    upd_pc_from_0_loop     <= '0';
    -- Temporary variable tha gets the number of iterations
    iterations := (OTHERS => '0');
    IF instr = '1' THEN
      IF config.iter_sd = '1' THEN -- dynamic, read the data from the register
        iterations := resize(unsigned(raccu_regs(to_integer(unsigned(config.iter)))), FOR_ITER);
      ELSE -- static read the data from the instruction
        iterations := unsigned(config.iter);
      END IF;
      IF (iterations = 0) THEN
        ----------------------------------------------------
        -- REV 1.3 2022-03-21 (reverted)--------------------
        ----------------------------------------------------
        loop_upd_from_0_loop                               <= config.related_loops;
        --loop_upd_from_0_loop                               <= related_loops_monitor(to_integer(config.loop_id));
        ----------------------------------------------------
        -- End of modification REV 1.3 (reverted)-----------
        ----------------------------------------------------
        upd_pc_from_0_loop                                 <= '1';
        -- Specify which loop it is so that we can later bypass 
        -- the configuration register and send out the correct PC
        skip_configuration_reg(to_integer(config.loop_id)) <= '1';
      END IF;
    END IF;
  END PROCESS zero_loop;

  --! Configuration & clear of the units registers with new loops
  config_regs : PROCESS (clk, rst_n)
    VARIABLE loop_id : INTEGER;
  BEGIN
    IF rst_n = '0' THEN
      config_reg <= (OTHERS => conf_zero);
    ELSIF rising_edge(clk) THEN
      -- clear any loops that needs to be cleared
      FOR loop_n IN 0 TO (MAX_NO_OF_LOOPS - 1) LOOP
        IF clear(loop_n) = '1' THEN -- If the clear signal is enabled, clear the pointed register 
          config_reg(loop_n) <= conf_zero;
        END IF;
      END LOOP;
      -- Configure new loops when new instruction
      IF (instr = '1' AND upd_pc_from_0_loop = '0') THEN -- New configuration of non 0 loop
        loop_id := to_integer(config.loop_id);
        config_reg(loop_id).active        <= '1';
        config_reg(loop_id).end_pc        <= config.end_pc;
        config_reg(loop_id).start_pc      <= config.start_pc;
        ----------------------------------------------------
        -- REV 1.3 2022-03-21 (reverted)--------------------
        ----------------------------------------------------
        config_reg(loop_id).related_loops <= config.related_loops;
        --FOR loop_n IN 0 TO (MAX_NO_OF_LOOPS - 1) LOOP
        --IF (related_loops_monitor(loop_n) /= related_zero) THEN
        --  config_reg(loop_n).related_loops <= related_loops_monitor(loop_n);
        --END IF;
        --END LOOP;

        -- Dynamic/static configuration is controlled from the sequencer
        config_reg(loop_id).start         <= signed(config.start);
        config_reg(loop_id).iter          <= unsigned(config.iter);
        IF config.default_step = '1' THEN
          config_reg(loop_id).step <= to_signed(1, config_reg(loop_id).step'length);
        ELSE
          config_reg(loop_id).step <= signed(config.step);
        END IF;

        -- Start value --
        --IF config.start_sd = '1' THEN -- dynamic, read the data from the register
        --config_reg(loop_id).start <= resize(signed(raccu_regs(to_integer(unsigned(config.start)))), FOR_START);
        --ELSE -- static read the data from the instruction
        --config_reg(loop_id).start <= signed(config.start);
        --END IF;
        -- Iter value --
        --IF config.iter_sd = '1' THEN -- dynamic, read the data from the register
        --config_reg(loop_id).iter <= resize(unsigned(raccu_regs(to_integer(unsigned(config.iter)))), FOR_ITER);
        --ELSE -- static read the data from the instruction
        --config_reg(loop_id).iter  <= unsigned(config.iter);
        --END IF;
        -- Step value --
        -- Check for the default step, if there is default step then just use step of 1
        -- IF config.default_step = '1' THEN
        --  config_reg(loop_id).step <= to_signed(1, config_reg(loop_id).step'length);
        --  ELSE
        --  IF config.step_sd = '1' THEN -- dynamic, read the data from the register
        --  config_reg(loop_id).step <= resize(signed(raccu_regs(to_integer(unsigned(config.step)))), FOR_EX_STEP);
        --  ELSE -- static read the data from the instruction
        --  config_reg(loop_id).step <= signed(config.step);
        --  END IF;
        --  END IF;

        ----------------------------------------------------
        -- End of modification REV 1.3 (reverted)-----------
        ----------------------------------------------------
      END IF;
    END IF;
  END PROCESS config_regs;

  ----------------------------------------------------
  -- REV 1.2 -----------------------------------------
  ----------------------------------------------------
  --! Process to register the PC to be checked if it is updated or not
  --P_reg : PROCESS (clk, rst_n)
  --BEGIN
  --  IF rst_n = '0' THEN
  --    old_pc <= (OTHERS => '0');
  --  ELSIF rising_edge(clk) THEN
  --    old_pc <= pc;
  --  END IF;
  --END PROCESS;
  ----! Process that compares the registered value of the PC with the current one
  --P_comb : PROCESS (old_pc, pc)
  --BEGIN
  --  IF old_pc /= pc THEN
  --    pc_change <= '1';
  --  ELSE
  --    pc_change <= '0';
  --  END IF;
  --END PROCESS;
  ----------------------------------------------------
  -- End of modification REV 1.2 ---------------------
  ----------------------------------------------------

  --! Process that compares the current PC with the end-PC of each loop
  pc_check : PROCESS (ALL) --(config_reg, pc, is_delay)
    VARIABLE debug : unsigned(PC_SIZE - 1 DOWNTO 0);
  BEGIN
    -- For every loop that is active check if the end-PC matches the current PC
    --loop_upd_from_PC <= (OTHERS => '0');
    --loop_upd_done_from_PC <= (OTHERS => '0');
    FOR loop_n IN 0 TO (MAX_NO_OF_LOOPS - 1) LOOP
      ----------------------------------------------------
      -- REV 1.2 2022-03-18 ------------------------------
      ----------------------------------------------------
      -- A loop should trigger a pc update only if the loop is active, a delay instruction is not in effect, and the inner loop is complete.
      IF (config_reg(loop_n).active = '1') AND (is_delay = '0') AND (increment_trigger(loop_n) = '1') THEN
        IF (pc = config_reg(loop_n).end_pc) THEN
          loop_upd_from_PC(loop_n) <= '1';
        ELSE
          loop_upd_from_PC(loop_n) <= '0';
        END IF;
      ELSE
        loop_upd_from_PC(loop_n) <= '0';
      END IF;
      debug := pc + 1;
      IF (debug = config_reg(loop_n).end_pc) THEN
        loop_upd_done_from_PC(loop_n) <= '1';
      ELSE
        loop_upd_done_from_PC(loop_n) <= '0';
      END IF;
      ----------------------------------------------------
      -- End of modification REV 1.2 ---------------------
      ----------------------------------------------------
    END LOOP;
  END PROCESS pc_check;

  trigger      <= loop_upd_from_0_loop OR loop_upd_from_PC;
  trigger_done <= loop_upd_from_0_loop OR loop_upd_done_from_PC OR loop_done_from_iter;

  ----------------------------------------------------
  -- REV 1.4 2022-03-23 ------------------------------
  ----------------------------------------------------
  --! Combinatorial process that selects the right trigger for the PC update.
  --! The trigger is the fed to the priority mux that will select the 
  --! and output the ID of the loop where you should jump to. (only used for zero iter loops)
  pc_upd_trigger_comb : PROCESS (ALL)
  BEGIN
    --FOR loop_n IN 0 TO MAX_NO_OF_LOOPS - 1 LOOP
    --  upd_pc_trigger_to_end(loop_n) <= '0';
    --  IF (incrementor_reg(loop_n) = config_reg(loop_n).iter - 1) THEN
    --    upd_pc_trigger_to_end(loop_n) <= '1' AND config_reg(loop_n).active AND (prev_loops_triggered_to_done(loop_n)) AND trigger_done(loop_n);
    --  END IF;
    --END LOOP;
    --upd_pc_trigger_to_end <= loop_done;
    upd_pc_trigger_to_end <= (OTHERS => '0');
    IF (upd_pc_from_0_loop = '1') THEN
      upd_pc_trigger_to_end(to_integer(config.loop_id)) <= '1';
    END IF;
  END PROCESS pc_upd_trigger_comb;
  ----------------------------------------------------
  -- End of modification REV 1.4 ---------------------
  ----------------------------------------------------

  --------------------------------------------------------------------------------
  --! Loop management for each loop <BEGIN>
  --------------------------------------------------------------------------------   
  loop_update_G : FOR loop_n IN 0 TO (MAX_NO_OF_LOOPS - 1) GENERATE

    -- Increment the loop if it is not done (only if the previous one is done or the lower in the hierarchy)
    last_loop : IF loop_n = (MAX_NO_OF_LOOPS - 1) GENERATE -- If this is the lowest loop in the hierarchy, then always increment (if active and triggered)
      increment_trigger(loop_n)            <= '1';
      ----------------------------------------------------
      -- REV 1.4 2022-03-23 ------------------------------
      ----------------------------------------------------
      check_cond_for_done(loop_n)          <= trigger_done(loop_n) AND config_reg(loop_n).active;
      prev_loops_triggered_to_done(loop_n) <= '1';
      ----------------------------------------------------
      -- End of modification REV 1.4 ---------------------
      ----------------------------------------------------
    END GENERATE last_loop;
    ----------------------------------------------------
    -- REV 1.4 2022-03-23 ------------------------------
    ----------------------------------------------------
    not_active_or_triggered_to_done(loop_n) <= (trigger_done(loop_n) OR (NOT config_reg(loop_n).active));
    ----------------------------------------------------
    -- End of modification REV 1.4 ---------------------
    ----------------------------------------------------
    other_loop : IF loop_n < (MAX_NO_OF_LOOPS - 1) GENERATE                                                                                                  -- If not the lowest loop in the hierarchy, then only increment if the next loop in the hierarchy is inactive or active but done (if active and triggered).
      increment_trigger(loop_n)            <= (NOT config_reg(loop_n + 1).active) OR (config_reg(loop_n + 1).active AND prev_loops_triggered_to_done(loop_n)); --loop_done(loop_n + 1));
      ----------------------------------------------------
      -- REV 1.4 2022-03-23 ------------------------------
      ----------------------------------------------------
      prev_loops_triggered_to_done(loop_n) <= and_reduce((not_active_or_triggered_to_done(MAX_NO_OF_LOOPS - 1 DOWNTO loop_n + 1)));
      -- If not the most inner loop in the hierarchy check if the loop is triggered and that it is active and the previous (inner) loop is triggered to end or is not active
      check_cond_for_done(loop_n)          <= trigger_done(loop_n) AND config_reg(loop_n).active AND (prev_loops_triggered_to_done(loop_n));
      ----------------------------------------------------
      -- End of modification REV 1.4 ---------------------
      ----------------------------------------------------
    END GENERATE other_loop;

    ----------------------------------------------------
    -- REV 1.4 2022-03-24 ------------------------------
    ----------------------------------------------------
    --! Process that updates the counters individual loops.
    --! This process also triggers the jump
    loop_update_p : PROCESS (ALL)
      VARIABLE raccu_value : signed(RACCU_REG_BITWIDTH - 1 DOWNTO 0);
      VARIABLE temp_result : signed(RACCU_REG_BITWIDTH - 1 DOWNTO 0);
    BEGIN
      incrementor_next(loop_n)    <= incrementor_reg(loop_n);
      clear(loop_n)               <= '0';
      jump_to_top_atomic(loop_n)  <= '0';
      loop_done_from_iter(loop_n) <= '0';
      -- Assign the start value if the loop instruction is coming in

      -- Check if the loop is on its last iteration
      IF (loop_upd_from_PC(loop_n) = '1') AND (incrementor_reg(loop_n) = config_reg(loop_n).iter - 1) THEN
        loop_done_from_iter(loop_n) <= '1';
      ELSE
        loop_done_from_iter(loop_n) <= '0';
      END IF;
      -- Check if loop configuration should be cleared
      --IF (config_reg(loop_n).active = '1') AND ((increment_trigger(loop_n) = '1') OR check_cond_for_done(loop_n) = '1') AND (is_delay = '0') AND (prev_loops_triggered_to_done(loop_n) = '1') THEN
      IF (incrementor_reg(loop_n) = config_reg(loop_n).iter - 1) AND (loop_upd_from_PC(loop_n) = '1') THEN -- AND (pc = config_reg(loop_n).end_pc) THEN
        clear(loop_n) <= '1';
      ELSE
        clear(loop_n) <= '0';
        --        END IF;
      END IF;
      
      -- Check and increment
      IF instr = '1' AND upd_pc_from_0_loop = '0' AND loop_n = to_integer(config.loop_id) THEN
          iterators(loop_n)   <= STD_LOGIC_VECTOR(resize(signed(config.start), iterators(loop_n)'length));
          active_iter(loop_n) <= '1';
          incrementor_next(loop_n) <= (OTHERS => '0');
      ELSE
        iterators(loop_n)   <= raccu_regs(RACCU_REGFILE_DEPTH - 1 - loop_n);
        active_iter(loop_n) <= '0';
      IF (config_reg(loop_n).active = '0') OR (clear(loop_n) = '1') THEN--(incrementor_reg(loop_n) = config_reg(loop_n).iter - 1) THEN
        -- if the loop is done
        -- Zero out the incrementor and iterator of the loop
        incrementor_next(loop_n) <= (OTHERS => '0');
        iterators(loop_n)        <= (OTHERS => '0');
        active_iter(loop_n)      <= '1';
      ELSE
        IF (trigger(loop_n) = '1') AND (increment_trigger(loop_n) = '1') AND (is_delay = '0') THEN
          incrementor_next(loop_n) <= incrementor_reg(loop_n) + 1;
          ---------------------------------------------------------------------------------
          -- Temporary variables (for readability)
          -- ---------------------------------------------------------------------------------
          raccu_value := signed(raccu_regs(RACCU_REGFILE_DEPTH - 1 - loop_n));
          temp_result := raccu_value + config_reg(loop_n).step;
          ---------------------------------------------------------------------------------
          iterators(loop_n)          <= STD_LOGIC_VECTOR(temp_result);
          active_iter(loop_n)        <= '1';
          -- Trigger the PC update 
          jump_to_top_atomic(loop_n) <= '1';
        END IF;
      END IF;
      END IF;
    END PROCESS loop_update_p;

    ----------------------------------------------------
    -- End of modification REV 1.4 ---------------------
    ----------------------------------------------------
    --------------------------------------------------------------------------------
    --! Loop management for each loop <END>
    --------------------------------------------------------------------------------   

    --! Registered process for each loop.
    --! This process controls the loop_done flag.
    --! The loop_done flag is used as a signal that the end_PC
    --! of the loop matches the current PC
    loop_done_update_p : PROCESS (rst_n, clk)
    BEGIN
      IF rst_n = '0' THEN
        loop_done(loop_n) <= '0';
      ELSIF rising_edge(clk) THEN
        loop_done(loop_n) <= '0';
        ----------------------------------------------------
        -- REV 1.4 2022-03-23 ------------------------------
        ----------------------------------------------------
        IF (incrementor_reg(loop_n) = config_reg(loop_n).iter - 1) THEN
          loop_done(loop_n) <= '1' AND check_cond_for_done(loop_n);
          --loop_done(loop_n) <= '1';
        END IF;
        ----------------------------------------------------
        -- End of modification REV 1.4 ---------------------
        ----------------------------------------------------
      END IF;
    END PROCESS loop_done_update_p;

  END GENERATE loop_update_G;

  -- jump to top if any of the loops are done
  jump_to_top <= or_reduce(jump_to_top_atomic);

  --! Priority mux that decides the jump to top PC
  PriorMux_top : ENTITY work.priorityMux
    GENERIC MAP(
      LEVELS   => LEVELS,
      i        => LEVELS - 1,
      N_sel_in => MAX_NO_OF_LOOPS,
      N_in     => MAX_NO_OF_LOOPS,
      N        => MAX_NO_OF_LOOPS
    )
    PORT MAP(
      ID_in  => ID_in,
      sel_in => jump_to_top_atomic,
      ID_out => jump_to_top_loop
    );

  --! Register process uses to register the incrementor of each loop
  Reg : PROCESS (clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      incrementor_reg <= (OTHERS => (OTHERS => '0'));
    ELSIF rising_edge(clk) THEN
      incrementor_reg <= incrementor_next;
    END IF;
  END PROCESS Reg;

  --! If any of the loops trigger the update of the PC then to jump out of the loop
  --! this signal should be '1'.
  PC_update_to_end <= or_reduce(upd_pc_trigger_to_end);

  PriorMux_end : ENTITY work.priorityMux
    GENERIC MAP(
      LEVELS   => LEVELS,
      i        => LEVELS - 1,
      N_sel_in => MAX_NO_OF_LOOPS,
      N_in     => MAX_NO_OF_LOOPS,
      N        => MAX_NO_OF_LOOPS
    )
    PORT MAP(
      ID_in  => ID_in,
      sel_in => upd_pc_trigger_to_end,
      ID_out => ID_out
    );

  --! Generate the ID inputs for the priority muxes
  IDS : FOR k IN 0 TO (MAX_NO_OF_LOOPS - 1) GENERATE
    ID_in(k) <= to_unsigned(k, FOR_LOOP_ID);
  END GENERATE IDS;

  --! Combinatorial process that selects and outputs the PC depending
  --! if we need to exit a loop or jump to the top
  PC_select : PROCESS (ID_out, config, config_reg, PC_update_to_end, skip_configuration_reg, jump_to_top, jump_to_top_loop)
  BEGIN
    pc_out <= (OTHERS => '0');
    jump   <= '0';
    -- PC requires update
    IF jump_to_top = '1' THEN --! Jump to the beginning 
      pc_out <= config_reg(to_integer(jump_to_top_loop)).start_pc;
      jump   <= '1';
    ELSIF PC_update_to_end = '1' THEN --! Jump to the end 
      jump <= '1';
      IF skip_configuration_reg(to_integer(ID_out)) = '1' THEN
        pc_out <= config.end_pc + 1;
      ELSE
        pc_out <= config_reg(to_integer(ID_out)).end_pc + 1;
      END IF;
    END IF;
  END PROCESS PC_select;
END RTL;
