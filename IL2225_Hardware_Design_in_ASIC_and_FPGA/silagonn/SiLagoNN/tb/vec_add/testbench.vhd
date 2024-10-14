LIBRARY IEEE;
USE STD.textio.all;
USE IEEE.std_logic_textio.all;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;
USE WORK.top_consts_types_package.ROWS;
USE WORK.top_consts_types_package.COLUMNS;
USE WORK.top_consts_types_package.INSTR_WIDTH;
USE WORK.top_consts_types_package.REG_FILE_MEM_ADDR_WIDTH;
USE WORK.top_consts_types_package.REG_FILE_MEM_DATA_WIDTH;
USE WORK.top_consts_types_package.SRAM_ADDRESS_WIDTH;
USE WORK.top_consts_types_package.SRAM_WIDTH;
USE WORK.tb_instructions.ALL;
USE WORK.const_package.ALL;
USE WORK.noc_types_n_constants.ALL;

ENTITY testbench IS
END testbench;

ARCHITECTURE behavior OF testbench IS

	SIGNAL clk            : std_logic := '0';
	SIGNAL rst_n          : std_logic := '0';
	SIGNAL instr_load     : std_logic := '0';
	SIGNAL instr_input    : std_logic_vector(INSTR_WIDTH-1 downto 0);
	SIGNAL immediate_input: std_logic;
	SIGNAL seq_address_rb : std_logic_vector(ROWS-1 downto 0);
	SIGNAL seq_address_cb : std_logic_vector(COLUMNS-1 downto 0);
	SIGNAL clk_input : std_logic_vector(COLUMNS-1 downto 0);
	SIGNAL rst_input : std_logic_vector(COLUMNS-1 downto 0);
	
	SIGNAL tb_or_dimarch 		: std_logic;
	
	SIGNAL SRAM_INST_ver_top_in	: INST_SIGNAL_TYPE(0 to COLUMNS-1, 0 to 0);
	SIGNAL top_splitter_dir_in_array	: DIRECTION_TYPE(0 to COLUMNS-1,0 to 0);
	SIGNAL south_in_array			: DATA_IO_SIGNAL_TYPE(0 to COLUMNS-1);
	
	SIGNAL tb_en    : std_logic;
	SIGNAL tb_addrs : std_logic_vector (SRAM_ADDRESS_WIDTH-1 downto 0);
	SIGNAL tb_inp   : std_logic_vector (SRAM_WIDTH-1 downto 0);
	SIGNAL tb_ROW   : unsigned (ROW_WIDTH-1 downto 0);
	SIGNAL tb_COL   : unsigned (COL_WIDTH-1 downto 0);
	
	TYPE instruction_type IS ARRAY (0 TO instruction_no-1) OF std_logic_vector(INSTR_WIDTH downto 0);
	SIGNAL instruction : instruction_type;
	SIGNAL immediate : std_logic_vector(instruction_no-1 downto 0);
	
	TYPE cell_info_type IS RECORD
		inst_no : integer range 0 to instruction_no;
		row : std_logic_vector(ROWS-1 downto 0);
		col : std_logic_vector(COLUMNS-1 downto 0);
	END RECORD;
	TYPE cell_infos_type IS ARRAY(0 TO ROWS*COLUMNS-1) OF cell_info_type;
	
	CONSTANT cell_infos : cell_infos_type := (
(27, "01", "00000001"), (27, "01", "00000010"), (27, "01", "00000100"), (27, "01", "00001000"), (27, "01", "00010000"), (27, "01", "00100000"), (27, "01", "01000000"), (27, "01", "10000000"), 
(27, "10", "00000001"), (27, "10", "00000010"), (27, "10", "00000100"), (27, "10", "00001000"), (27, "10", "00010000"), (27, "10", "00100000"), (27, "10", "01000000"), (27, "10", "10000000"));
	
	TYPE mem_value_type IS RECORD

		address : std_logic_vector (SRAM_ADDRESS_WIDTH-1 downto 0);
		row     : unsigned (ROW_WIDTH-1 downto 0);
		col     : unsigned (COL_WIDTH-1 downto 0);
		data   : std_logic_vector (SRAM_WIDTH-1 downto 0);
	
	END RECORD;
	TYPE mem_values_type IS ARRAY (0 to mem_no-1) OF mem_value_type;
	CONSTANT mem_init_values : mem_values_type := (
	  0 => ("0000000", "01", "000", X"000f000e000d000c000b000a0009000800070006000500040003000200010000")
, 1 => ("0000001", "01", "000", X"001f001e001d001c001b001a0019001800170016001500140013001200110010")
, 2 => ("0000010", "01", "000", X"002f002e002d002c002b002a0029002800270026002500240023002200210020")
, 3 => ("0000011", "01", "000", X"003f003e003d003c003b003a0039003800370036003500340033003200310030")
);
	TYPE reg_value_type IS RECORD
		address : std_logic_vector (REG_FILE_MEM_ADDR_WIDTH-1 downto 0);
		row     : std_logic_vector (ROWS-1 downto 0);
		col     : std_logic_vector (COLUMNS-1 downto 0);
		data    : signed (REG_FILE_MEM_DATA_WIDTH-1 downto 0);
	END RECORD;
	TYPE reg_values_type IS ARRAY (0 to reg_load_cycles-1) OF reg_value_type;
	
	CONSTANT reg_init_values : reg_values_type := (
		  ("00", "01", "00000001", X"0000000000000000000000000000000000000000000000000000000000000000")
		, ("01", "01", "00000001", X"0000000000000000000000000000000000000000000000000000000000000000")
		, ("10", "01", "00000001", X"0000000000000000000000000000000000000000000000000000000000000000")
		, ("11", "01", "00000001", X"0000000000000000000000000000000000000000000000000000000000000000")
);

BEGIN

	-- PRF : ENTITY work.profiler
		-- PORT MAP (clk   => clk,
		--           rst_n => rst_n);
	
	input_gen: FOR i in 0 to COLUMNS-1 GENERATE
		SRAM_INST_ver_top_in(i,0) <= ('0', (others => '0'), (others => '0'));
		top_splitter_dir_in_array(i,0) <= (others => '0');
		south_in_array(i) <= (others => '0');
	END GENERATE;
	
	clk_input <= (others => '0');
	rst_input <= (others => '0');
	
	DUT : ENTITY work.silagonn
		PORT MAP (
		          clk                       => clk,
		          rst_n                     => rst_n,
		          clk_input                 => clk_input,
		          rst_input                 => rst_input,
		          instr_ld                  => instr_load,
		          instr_inp                 => instr_input,
		          immediate                 => immediate_input,
		          seq_address_rb            => seq_address_rb,
		          seq_address_cb            => seq_address_cb,
		          tb_en                     => tb_en,
		          tb_addrs                  => tb_addrs,
		          tb_inp                    => tb_inp,
		          tb_ROW                    => tb_ROW,
		          tb_COL                    => tb_COL
		);
	
	rst_n <= '0' AFTER 2.5 ns, '1' AFTER 4 ns;
	clk   <= NOT clk AFTER half_period;
	
	StimuliSequencer : PROCESS (clk, rst_n)
		VARIABLE inst_counter	  : integer := 0;
		VARIABLE curr_cell		  : integer := 0;
		VARIABLE mem_load_counter : integer := 0;
		VARIABLE mem_load_init_delay_counter : integer := 0;
		VARIABLE reg_load_counter : integer := 0;
	BEGIN
		IF (rst_n = '0') THEN
			inst_counter	 := 0;
			curr_cell		 := 0;
			mem_load_counter := 0;
			reg_load_counter := 0;
			instr_load     <= '0';
			instr_input    <= (OTHERS =>'0');
			seq_address_rb <= (OTHERS =>'0');
			seq_address_cb <= (OTHERS =>'0');
			tb_or_dimarch  <= '0';
			tb_en 	 <= '0';
			tb_addrs <= (OTHERS => '0');
			tb_inp	 <= (OTHERS => '0');
			tb_ROW 	 <= (OTHERS => '0');
			tb_COL 	 <= (OTHERS => '0');
		ELSIF clk'EVENT AND clk = '0' THEN
			
			tb_en <= '0';
			
			IF (mem_load_counter < mem_load_cycles) THEN
				if(mem_load_init_delay_counter >= (mem_init_values(mem_load_counter).row + mem_init_values(mem_load_counter).col)) then
					instr_load <= '0';
					tb_en      <= '1';
					tb_addrs   <= mem_init_values(mem_load_counter).address;
					tb_ROW     <= mem_init_values(mem_load_counter).row;
					tb_COL     <= mem_init_values(mem_load_counter).col;
					tb_inp     <= mem_init_values(mem_load_counter).data;
					
					mem_load_counter := mem_load_counter + 1;
				end if;
				mem_load_init_delay_counter := mem_load_init_delay_counter + 1;
			ELSIF (reg_load_counter < reg_load_cycles) THEN
				reg_load_counter := reg_load_counter + 1;
				
			ELSIF (inst_counter >= 0 AND inst_counter < instruction_no) THEN
				
				tb_or_dimarch  <= '1';
				
				WHILE (inst_counter >= cell_infos(curr_cell).inst_no) LOOP
					curr_cell := curr_cell + 1;
				END LOOP;
				
				seq_address_rb <= cell_infos(curr_cell).row;
				seq_address_cb <= cell_infos(curr_cell).col;
				instr_load     <= '1';
				instr_input    <= std_logic_vector(instruction(inst_counter)(INSTR_WIDTH-1 downto 0));
				immediate_input<= immediate(inst_counter);
				inst_counter   := inst_counter + 1;
				
			ELSE
				instr_load      <= '0';
			END IF;
		END IF;
	END PROCESS StimuliSequencer;

	
	InstSequencer : PROCESS IS
		file fptr: text;
		variable fstatus : file_open_status;
		variable instr: std_logic_vector(INSTR_WIDTH-1 downto 0);
		variable row : line;
		variable cell_row : integer := 0;
		variable cell_col : integer := 1;
		variable cell_str : string(1 to 1);
		variable temp_str : string(1 to 3);
		variable index : integer :=0;
	begin
		file_open(fstatus, fptr, "instruction.bin", read_mode);
		while (not endfile(fptr)) loop
			readline(fptr, row);
			if row'length > 0 then
				read(row, cell_str);
				if cell_str(1 to 1) = "C" then
					read(row, temp_str);
					read(row, cell_row);
					read(row, cell_col);
				elsif cell_str(1 to 1) = "0" then
					read(row, instr);
					instruction(index) <= '0' & instr;
					immediate(index) <= '0';
					index := index+1;
				elsif cell_str(1 to 1) = "1" then
					read(row, instr);
					instruction(index) <= '0' & instr;
					immediate(index) <= '1';
					index := index+1;
				end if;
			end if;
		end loop;
		wait;
	END PROCESS InstSequencer;

	
END behavior;
