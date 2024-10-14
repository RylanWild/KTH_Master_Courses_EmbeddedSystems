-------------------------------------------------------------------------------
-- Title      : AGU
-- Project    : 
-------------------------------------------------------------------------------
-- File       : AGU.vhd
-- Author     : Nasim Farahini  
-- Company    : 
-- Created    : 2013-09-10
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2013-09-10  1.0      Nasim Farahini  Created  -- Covers implementation of one level affine loop, 
-- 2014-02-15  2.0      Nasim Farahini  Modified -- Covers Repetition, Repetition Delay, Middle Delay
-------------------------------------------------------------------------------

LIBRARY ieee, work;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE work.top_consts_types_package.ALL;

ENTITY AGU IS
  
  PORT (
    clk                 	: IN  std_logic;
    rst_n               	: IN  std_logic;
    instr_start         	: IN  std_logic;
    instr_initial_delay 	: IN  std_logic_vector(INITIAL_DELAY_WIDTH - 1 DOWNTO 0);
    instr_start_addrs   	: IN  std_logic_vector(START_ADDR_WIDTH - 1 DOWNTO 0);
    instr_step_val      	: IN  std_logic_vector(ADDR_OFFSET_WIDTH - 1 DOWNTO 0);
    instr_step_val_sign 	: IN  std_logic_vector(ADDR_OFFSET_SIGN_WIDTH - 1 DOWNTO 0);
    instr_no_of_addrs   	: IN  std_logic_vector(ADDR_COUNTER_WIDTH - 1 DOWNTO 0);
    instr_middle_delay  	: IN std_logic_vector(REG_FILE_MIDDLE_DELAY_PORT_SIZE-1 DOWNTO 0);
    instr_no_of_rpts    	: IN std_logic_vector(NUM_OF_REPT_PORT_SIZE-1 DOWNTO 0);
    instr_rpt_step_value	: IN std_logic_vector(REP_STEP_VALUE_PORT_SIZE-1 DOWNTO 0);
    instr_rpt_delay 		: IN std_logic_vector(REPT_DELAY_VECTOR_SIZE-1 DOWNTO 0);
    addr_out            	: OUT std_logic_vector(REG_FILE_ADDR_WIDTH - 1 DOWNTO 0);
    addr_en             	: OUT std_logic
    );

END AGU;

ARCHITECTURE behave OF AGU IS

  TYPE state_type IS (IDLE_ST, INITIAL_DELAY_ST, LINEAR_ST, RPT_DELAY_ST , RPT_ST);

  SIGNAL pres_state, next_state                                                                  : state_type;
  SIGNAL delay_counter                                                                           : std_logic_vector(INITIAL_DELAY_WIDTH - 1 DOWNTO 0);
  SIGNAL  addr_counter                                                                          : std_logic_vector(ADDR_COUNTER_WIDTH - 1 DOWNTO 0);
  SIGNAL one_addr , delay_count_en , addr_count_en, addr_value_en  , init_zero , all_done_temp, no_more_rpt, add_sub_addr_en : std_logic;
  SIGNAL rpt_no_count_en ,rpt_start_addrs_en, rpt_delay_count_en, middle_delay_flag, middle_delay_first_cycle, middle_delay_count_en, addr_count_halt_en: std_logic;
  SIGNAL step_val_reg  , step_val_temp_in  : std_logic_vector(ADDR_OFFSET_WIDTH - 1 DOWNTO 0);
  SIGNAL no_of_addrs_reg                                                                         : std_logic_vector(ADDR_COUNTER_WIDTH - 1 DOWNTO 0);
  SIGNAL start_addrs_reg , rpt_start_addrs_reg_in, rpt_start_addrs_reg          : std_logic_vector(START_ADDR_WIDTH - 1 DOWNTO 0);
  SIGNAL initial_delay_reg                                                                       : std_logic_vector(INITIAL_DELAY_WIDTH - 1 DOWNTO 0);
  SIGNAL rpt_no_counter                                                                           : std_logic_vector(5  DOWNTO 0);
  signal middle_delay_reg, middle_delay_counter :  std_logic_vector(REG_FILE_MIDDLE_DELAY_PORT_SIZE-1 DOWNTO 0);
  signal no_of_rpts_reg        :  std_logic_vector(NUM_OF_REPT_PORT_SIZE-1 DOWNTO 0);
  signal rpt_step_value_reg    :  std_logic_vector(REP_STEP_VALUE_PORT_SIZE-1 DOWNTO 0);
  signal rpt_delay_reg,rpt_delay_counter   :  std_logic_vector(REPT_DELAY_VECTOR_SIZE-1 DOWNTO 0);
  signal step_val_sign_reg , add_sub_addr     :  std_logic_vector(ADDR_OFFSET_SIGN_WIDTH - 1 DOWNTO 0);
  signal addr_temp_in, addr_temp_out   : std_logic_vector(REG_FILE_ADDR_WIDTH - 1 DOWNTO 0);
  
BEGIN

one_addr <= '1' when instr_no_of_addrs = "000000" else '0';
init_zero <= '1' when (instr_start = '1' and instr_initial_delay= "0000") else '0';
rpt_start_addrs_reg_in <= start_addrs_reg when rpt_no_counter="000000" else rpt_start_addrs_reg;
no_more_rpt <= '1' when rpt_no_counter= no_of_rpts_reg else '0';  
middle_delay_flag <= '0' when middle_delay_counter= middle_delay_reg else '1';
middle_delay_first_cycle <= '0' when middle_delay_counter="000000" else '1';
add_sub_addr_en <= '0' when add_sub_addr="0" else '1';

  reg_input_param : PROCESS (clk, rst_n) IS
  BEGIN  
    IF rst_n = '0' THEN      
      step_val_reg      <= (OTHERS => '0');
      step_val_sign_reg      <= (OTHERS => '0');
      no_of_addrs_reg   <= (OTHERS => '0');
      start_addrs_reg   <= (OTHERS => '0');
      initial_delay_reg <= (OTHERS => '0');
      middle_delay_reg <= (OTHERS => '0');
      no_of_rpts_reg        <= (OTHERS => '0');
      rpt_step_value_reg   <= (OTHERS => '0');
      rpt_delay_reg <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN 
      IF instr_start = '1' THEN
        step_val_reg      <= instr_step_val;
        step_val_sign_reg      <= instr_step_val_sign;        
        no_of_addrs_reg   <= instr_no_of_addrs;
        start_addrs_reg   <= instr_start_addrs;
        initial_delay_reg <= instr_initial_delay;
        middle_delay_reg <= instr_middle_delay;
        no_of_rpts_reg        <= instr_no_of_rpts;
        rpt_step_value_reg   <= instr_rpt_step_value;
        rpt_delay_reg <= instr_rpt_delay;
      ELSIF all_done_temp = '1' THEN
        step_val_reg      <= (OTHERS => '0');
        step_val_sign_reg      <= (OTHERS => '0');
        no_of_addrs_reg   <= (OTHERS => '0');
        start_addrs_reg   <= (OTHERS => '0');
        initial_delay_reg <= (OTHERS => '0');
        middle_delay_reg <= (OTHERS => '0');
        no_of_rpts_reg        <= (OTHERS => '0');
        rpt_step_value_reg   <= (OTHERS => '0');
        rpt_delay_reg <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS reg_input_param;



  init_del_cnt : PROCESS (clk, rst_n) IS
  BEGIN
    IF rst_n = '0' THEN
      delay_counter <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN
      IF delay_count_en = '1' THEN
        delay_counter <= delay_counter + 1;
      ELSE
        delay_counter <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS init_del_cnt;


  rpt_del_cnt : PROCESS (clk, rst_n) IS
  BEGIN
    IF rst_n = '0' THEN
      rpt_delay_counter <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN
      IF rpt_delay_count_en = '1' THEN
        rpt_delay_counter <= rpt_delay_counter + 1;
      ELSE
        rpt_delay_counter <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS rpt_del_cnt;
  
  
  mdl_del_cnt : PROCESS (clk, rst_n) IS
  BEGIN
    IF rst_n = '0' THEN
      middle_delay_counter <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN
      IF middle_delay_count_en = '1' THEN
        middle_delay_counter <= middle_delay_counter + 1;
      ELSE
        middle_delay_counter <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS mdl_del_cnt;
  
  
  rpt_no_cnt : PROCESS (clk, rst_n) IS
  BEGIN
    IF rst_n = '0' THEN
      rpt_no_counter <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN
      IF rpt_no_count_en = '1' THEN
        rpt_no_counter <= rpt_no_counter + 1;
      elsif all_done_temp='1' then 
      	rpt_no_counter <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS rpt_no_cnt;

  addr_cnt : PROCESS (clk, rst_n)
  BEGIN  
    IF rst_n = '0' THEN                
      addr_counter  <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN  
      IF addr_count_en = '1' and addr_count_halt_en = '0'THEN
        addr_counter <= addr_counter + 1;
      ELSIF addr_count_en = '0' then 
        addr_counter  <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS addr_cnt;
  
  
  rpt_start_addrs_value : PROCESS (clk, rst_n)
  BEGIN  
    IF rst_n = '0' THEN                
      rpt_start_addrs_reg <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN  
      IF rpt_start_addrs_en = '1' THEN
        rpt_start_addrs_reg <= rpt_start_addrs_reg_in + rpt_step_value_reg;
      END IF;
    END IF;
  END PROCESS rpt_start_addrs_value;
  
  
  addr_value : PROCESS(clk, rst_n)
  BEGIN
  	IF rst_n = '0' THEN
  		addr_temp_out <= (OTHERS => '0');
  	ELSIF clk'event AND clk = '1' THEN
  		IF addr_value_en = '1' THEN
  			if add_sub_addr_en = '0' then
  				addr_temp_out <= addr_temp_in + step_val_temp_in;
  			else
  				addr_temp_out <= addr_temp_in - step_val_temp_in;
  			end if;
  		ELSE
  			addr_temp_out <= (OTHERS => '0');
  		END IF;
  	END IF;
  END PROCESS addr_value;

  AGU_FSM : PROCESS (pres_state, middle_delay_flag,middle_delay_first_cycle,rpt_start_addrs_en ,no_more_rpt, rpt_no_count_en, instr_step_val, instr_start_addrs, 
  					 instr_no_of_addrs, instr_start, instr_initial_delay, one_addr, addr_counter, start_addrs_reg, 
  					 initial_delay_reg, delay_counter, addr_temp_out, step_val_sign_reg,no_of_addrs_reg, rpt_delay_reg, rpt_delay_counter, instr_middle_delay, instr_no_of_rpts,
  	 				 instr_step_val_sign, instr_rpt_delay,step_val_reg,instr_rpt_step_value,no_of_rpts_reg,rpt_step_value_reg,rpt_start_addrs_reg)
  BEGIN
    next_state     <= pres_state;
    addr_count_en  <= '0';
    addr_out       <= (OTHERS => '0');
    addr_en        <= '0';
    all_done_temp  <= '0';
    addr_temp_in   <= (OTHERS => '0');
    delay_count_en <= '0';
    step_val_temp_in <= step_val_reg;
    rpt_no_count_en <= '0';
    addr_value_en  <= '0';
    rpt_start_addrs_en <= '0';
    rpt_delay_count_en <= '0';
    middle_delay_count_en <= '0';
    addr_count_halt_en <= '0';
    add_sub_addr <= step_val_sign_reg;

    CASE pres_state IS
      WHEN IDLE_ST =>
      addr_en    <= '0';
      next_state <= IDLE_ST;

      IF instr_start = '1' THEN
      	IF instr_initial_delay = "0000" THEN
      		if instr_middle_delay = "000000" then
      				step_val_temp_in <= instr_step_val;
      				add_sub_addr     <= instr_step_val_sign;
      			if one_addr = '1' THEN
      				if instr_no_of_rpts = "000000" then
      					next_state    <= IDLE_ST;
      					addr_en       <= '1';
      					all_done_temp <= '1';
      						addr_out <= instr_start_addrs;
      				else
      					if instr_rpt_delay = "000000" then
      						addr_temp_in       <= instr_start_addrs;
      						add_sub_addr       <= (OTHERS => '0');
      						rpt_no_count_en    <= '1';
      						rpt_start_addrs_en <= '1';
      						addr_en            <= '1';
      						addr_count_en      <= '0';
      						addr_value_en      <= '1';
      							next_state       <= LINEAR_ST;
      							addr_out         <= instr_start_addrs;
      							step_val_temp_in <= instr_rpt_step_value;
      					else
      						next_state         <= RPT_DELAY_ST;
      						rpt_no_count_en    <= '1';
      						rpt_start_addrs_en <= '1';
      						rpt_delay_count_en <= '0';
      						addr_value_en      <= '1';
      						step_val_temp_in   <= (OTHERS => '0');
      						add_sub_addr       <= (OTHERS => '0');
      						addr_count_en      <= '1';
      						addr_en            <= '1';
      						addr_temp_in       <= instr_start_addrs;
      						addr_out <= instr_start_addrs;
      					end if;
      				end if;
      			ELSE
      				addr_temp_in  <= instr_start_addrs;
      				addr_en       <= '1';
      				addr_count_en <= '1';
      				addr_value_en <= '1';
      				next_state   <= LINEAR_ST;
      				addr_out     <= instr_start_addrs;
      				add_sub_addr <= instr_step_val_sign;
      			END IF;
      		else
      			middle_delay_count_en <= '1';
      			addr_count_halt_en    <= '1';
      			step_val_temp_in      <= (OTHERS => '0');
      			add_sub_addr          <= (OTHERS => '0');
      			addr_temp_in          <= instr_start_addrs;
      			addr_en               <= '1';
      			addr_count_en         <= '1';
      			addr_value_en         <= '1';
      			next_state <= LINEAR_ST;
      			addr_out   <= instr_start_addrs;
      		end if;
      	ELSE
      		IF instr_initial_delay = "0001" THEN
      			step_val_temp_in <= (OTHERS => '0');
      			add_sub_addr     <= (OTHERS => '0');
      			addr_temp_in     <= instr_start_addrs;
      			addr_en          <= '0';
      			addr_count_en    <= '0';
      			addr_value_en    <= '1';
      			next_state <= LINEAR_ST;
      		else
      			next_state     <= INITIAL_DELAY_ST;
      			addr_en        <= '0';
      			delay_count_en <= '1';
      			addr_value_en  <= '0';
      			addr_count_en  <= '0';
      		end if;

      	END IF;


      END IF;

      WHEN INITIAL_DELAY_ST =>
      next_state     <= INITIAL_DELAY_ST;
      delay_count_en <= '1';
      IF delay_counter = initial_delay_reg - 1 THEN
      	delay_count_en   <= '0';
      	addr_en          <= '0';
      	addr_count_en    <= '0';
      	addr_value_en    <= '1';
      	step_val_temp_in <= (OTHERS => '0');
      	addr_temp_in     <= start_addrs_reg;
      	next_state <= LINEAR_ST;
      END IF;

      WHEN LINEAR_ST =>
      addr_count_en  <= '1';
      addr_value_en  <= '1';
      delay_count_en <= '0';
      addr_out       <= addr_temp_out;
      add_sub_addr   <= step_val_sign_reg;
      addr_temp_in   <= addr_temp_out;
      next_state     <= LINEAR_ST;
      if middle_delay_first_cycle='0' then --Remove this condition if you need adr_en=1 during the middle_delay
          addr_en        <= '1';
      else 
          addr_en        <= '0';
      end if;       

      IF addr_counter = no_of_addrs_reg THEN
    		addr_count_en <= '0';
    		addr_value_en <= '1';

    		IF no_of_rpts_reg = "000000" or no_more_rpt = '1' then
    			next_state    <= IDLE_ST;
    			all_done_temp <= '1';
    		else
    			rpt_no_count_en    <= '1';
    			rpt_start_addrs_en <= '1';
    			if rpt_delay_reg = "000000" then
    				if no_of_addrs_reg = "000000" then
    					next_state       <= LINEAR_ST;
    					step_val_temp_in <= rpt_step_value_reg;
    					add_sub_addr     <= (OTHERS => '0');
    				else
    					next_state <= RPT_ST;
    				end if;
    			else
    				next_state         <= RPT_DELAY_ST;
    				rpt_delay_count_en <= '0';
    				addr_value_en      <= '1';
    				step_val_temp_in   <= (OTHERS => '0');
    				add_sub_addr       <= (OTHERS => '0');

    			end if;
    		end if;

      ELSE
        if middle_delay_flag = '1' then
        	addr_count_halt_en    <= '1';
        	step_val_temp_in      <= (OTHERS => '0');
        	add_sub_addr          <= (OTHERS => '0');
        	middle_delay_count_en <= '1';
     
        end if;
      END IF; 

      WHEN RPT_DELAY_ST =>
      next_state         <= RPT_DELAY_ST;
      rpt_delay_count_en <= '1';
      addr_temp_in       <= addr_temp_out;
      step_val_temp_in   <= (OTHERS => '0');
      add_sub_addr       <= (OTHERS => '0');
      addr_value_en      <= '1';
      IF rpt_delay_counter = rpt_delay_reg - 1 THEN
      	rpt_delay_count_en <= '0';
      	if no_of_addrs_reg = "000000" then
      		next_state       <= LINEAR_ST;
      		step_val_temp_in <= rpt_step_value_reg;
      		add_sub_addr <= (OTHERS => '0');
      	else
      		next_state <= RPT_ST;
      	end if;
      END IF;

      WHEN RPT_ST =>
      addr_count_en  <= '1';
      addr_value_en  <= '1';
      delay_count_en <= '0';
      addr_out     <= rpt_start_addrs_reg;
      next_state   <= LINEAR_ST;
      addr_temp_in <= rpt_start_addrs_reg;
      if middle_delay_first_cycle='0' then --Remove this condition if you need adr_en=1 during the middle_delay
          addr_en        <= '1';
      else 
          addr_en        <= '0';
      end if;       
      if middle_delay_flag = '1' then
      	middle_delay_count_en <= '1';
      	addr_count_halt_en    <= '1';
      	step_val_temp_in      <= (OTHERS => '0');
      	add_sub_addr          <= (OTHERS => '0');
      end if;

      WHEN OTHERS => NULL;
      END CASE;
      END PROCESS AGU_FSM;


  State_Reg : PROCESS (clk, rst_n)
  BEGIN 
    IF rst_n = '0' THEN
      pres_state <= IDLE_ST;
    ELSIF clk'event AND clk = '1' THEN
      pres_state <= next_state;
    END IF;
  END PROCESS State_Reg;

END behave;
