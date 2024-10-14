LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.top_consts_types_package.ALL;
USE work.noc_types_n_constants.ALL;
USE work.crossbar_types_n_constants.CORSSBAR_INSTRUCTION_RECORD_TYPE;
USE work.crossbar_types_n_constants.nr_of_crossbar_ports;
USE work.misc.ALL;
USE work.ALL;


--! @brief This is the DiMArch middle tile.
--! @details This tile is the combination of all the components
--! That are needed to connect to the DRRA fabric. It is stand-alone (can be harden)
--! and has dynamic addressing
--! Includes the following:
--! \verbatim
--! Address assignment unit
--! Bus segment (set on the right hand side of the SRAMTile) 
--! SRAMTile 
--! bus_selector (was part of the DRRA fabric)
--! \endverbatim
ENTITY DiMArchTile_Top_right_corner IS
    PORT (
        rst_n : IN std_logic;
        clk   : IN std_logic;
        -------------------------
        -- Address signals
        -------------------------
        start_col : IN std_logic;                         --! Connected to the valid signal of the previous block in the same col
        prevRow   : IN unsigned(ROW_WIDTH - 1 DOWNTO 0);  --! Row address assigned to the previous cell
        prevCol   : IN unsigned(COL_WIDTH - 1 DOWNTO 0);  --! Col address assigned to the previous cell
        valid     : OUT std_logic;                        --! Valid signals, used to signal that the assignment of the address is complete
        thisRow   : OUT unsigned(ROW_WIDTH - 1 DOWNTO 0); --! The row address assigned to the cell
        thisCol   : OUT unsigned(COL_WIDTH - 1 DOWNTO 0); --! The column address assigned to the cell
        -------------------------
        -- Datas in/out
        -------------------------
        data_south_out : OUT std_logic_vector(SRAM_WIDTH - 1 DOWNTO 0);
        data_west_out  : OUT std_logic_vector(SRAM_WIDTH - 1 DOWNTO 0);

        data_south_in  : IN std_logic_vector(SRAM_WIDTH - 1 DOWNTO 0);
        data_west_in   : IN std_logic_vector(SRAM_WIDTH - 1 DOWNTO 0);
        --------------------------------------------------
        -- Direction of neibouring buses
        --------------------------------------------------
        bottom_splitter_direction : OUT std_logic_vector(1 DOWNTO 0); --! Going to the cell under
        left_splitter_direction   : OUT std_logic_vector(1 DOWNTO 0); --! Going to the cell on the left
        --------------------------------------------------
        -- Partitioning instruction to neibouring buses
        --------------------------------------------------
        bottom_partition_in    : IN  PARTITION_INSTRUCTION_RECORD_TYPE; --! Coming from the cell under
        left_partition_in      : IN  PARTITION_INSTRUCTION_RECORD_TYPE; --! Coming from the cell on the left
        ----------------------------
        -- Instructions in/out
        ----------------------------
        noc_south_out : OUT NOC_BUS_TYPE;
        noc_west_out  : OUT NOC_BUS_TYPE;

        noc_south_in  : IN  NOC_BUS_TYPE;
        noc_west_in   : IN  NOC_BUS_TYPE;
        --------------------------------------------------------
        --SRAM initialization from testbench -- input signals from the cell on the left
        --------------------------------------------------------
        tb_en    : IN std_logic;
        tb_addrs : IN std_logic_vector(SRAM_ADDRESS_WIDTH - 1 DOWNTO 0);
        tb_inp   : IN std_logic_vector(SRAM_WIDTH - 1 DOWNTO 0);
        tb_ROW   : IN unsigned(ROW_WIDTH - 1 DOWNTO 0);
        tb_COL   : IN unsigned(COL_WIDTH - 1 DOWNTO 0);
        --------------------------------------------------------
        --SRAM initialization from testbench -- output signals to the cell on the right
        --------------------------------------------------------
        tb_en_out    : OUT std_logic;
        tb_addrs_out : OUT std_logic_vector(SRAM_ADDRESS_WIDTH - 1 DOWNTO 0);
        tb_inp_out   : OUT std_logic_vector(SRAM_WIDTH - 1 DOWNTO 0);
        tb_ROW_out   : OUT unsigned(ROW_WIDTH - 1 DOWNTO 0);
        tb_COL_out   : OUT unsigned(COL_WIDTH - 1 DOWNTO 0)
    );
END DiMArchTile_Top_right_corner;

--! @brief Structural architecture of the tile.
--! @details The structure of the module can be seen here:
--! \image html Dimarch_top.png "DiMArch top row cells"
--! Includes the following:
--! \verbatim
--! Address assignment unit
--! Bus segment (set on the right hand side of the SRAMTile) 
--! SRAMTile 
--! bus_selector (was part of the DRRA fabric)
--! input selector (selects the input of the Dimarch cell (top or bottom row of the DRRA)
--! \endverbatim
ARCHITECTURE behv_rtl OF DiMArchTile_Top_Right_corner IS
    -------------------------------
    -- Address signals
    -------------------------------
    SIGNAL This_ROW : UNSIGNED(ROW_WIDTH - 1 DOWNTO 0); --! The row address assigned to the cell
    SIGNAL This_COL : UNSIGNED(COL_WIDTH - 1 DOWNTO 0); --! The column address assigned to the cell
    -------------------------------
    -- Segmented bus <-> STile signals
    -------------------------------
    -- Signals connected between the horizontal bus and the left side of the STile
    SIGNAL bus_hor_direction        : std_logic_vector(1 DOWNTO 0);
    SIGNAL bus_hor_right_in         : NOC_BUS_TYPE;
    SIGNAL bus_hor_right_out        : NOC_BUS_TYPE;
    SIGNAL bus_hor_partition_right  : PARTITION_INSTRUCTION_RECORD_TYPE;
    -- Signals connected between the vertical bus and the bottom side of the STile
    SIGNAL bus_ver_direction        : std_logic_vector(1 DOWNTO 0);
    SIGNAL bus_ver_top_in           : NOC_BUS_TYPE;
    SIGNAL bus_ver_top_out          : NOC_BUS_TYPE;
    SIGNAL bus_ver_partition_top    : PARTITION_INSTRUCTION_RECORD_TYPE;
	SIGNAL data_north_in, data_north_out 		: std_logic_vector(SRAM_WIDTH - 1 DOWNTO 0);
	SIGNAL data_east_in, data_east_out 		: std_logic_vector(SRAM_WIDTH - 1 DOWNTO 0);
    SIGNAL top_splitter_direction 		: std_logic_vector(1 DOWNTO 0); --! Going to the cell under
    SIGNAL right_splitter_direction	 		: std_logic_vector(1 DOWNTO 0); --! Going to the cell under
    SIGNAL top_partition_out     			: PARTITION_INSTRUCTION_RECORD_TYPE; --! Coming from the cell on the left
    SIGNAL right_partition_out     			: PARTITION_INSTRUCTION_RECORD_TYPE; --! Coming from the cell on the left
    SIGNAL noc_north_out, noc_north_in      : NOC_BUS_TYPE;
    SIGNAL noc_east_out, noc_east_in        : NOC_BUS_TYPE;
    
BEGIN
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- Register and transmit global signals
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    --TODO A new type of configuration is required, more efficient 
    register_transfer_global : PROCESS (clk, rst_n) IS
    BEGIN
        IF rst_n = '0' THEN
            tb_en_out    <= '0';
            tb_addrs_out <= (OTHERS => '0');
            tb_inp_out   <= (OTHERS => '0');
            tb_ROW_out   <= (OTHERS => '0');
            tb_COL_out   <= (OTHERS => '0');
            ELSIF rising_edge(clk) THEN
            tb_en_out    <= tb_en;
            tb_addrs_out <= tb_addrs;
            tb_inp_out   <= tb_inp;
            tb_ROW_out   <= tb_ROW;
            tb_COL_out   <= tb_COL;
        END IF;
    END PROCESS register_transfer_global;

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- Buses and STile signals to outputs
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    left_splitter_direction   <= bus_hor_direction;
    bottom_splitter_direction <= bus_ver_direction;
    top_splitter_direction <=  (OTHERS => '0');
    right_splitter_direction <=  (OTHERS => '0');

	data_north_in <= (OTHERS => '0');
	data_east_in <= (OTHERS => '0');

	noc_north_in <= IDLE_BUS;
	noc_east_in <= IDLE_BUS;
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- Segmented buses
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    u_segmented_bus_hor : ENTITY work.segmented_bus
        PORT MAP(
            clk               => clk,
            rst               => rst_n,
            left_instruction  => left_partition_in,           --! Coming from left cell
            right_instruction => bus_hor_partition_right,     --! Coming from STile
            left_in           => noc_west_in,                 --! Coming from left cell
            left_out          => noc_west_out,                --! Going to left cell
            right_in          => bus_hor_right_in,            --! Coming from Stile
            right_out         => bus_hor_right_out,           --! Going to Stile
            bus_direction     => bus_hor_direction            --! Going to left cell and Stile
        );
    
    u_segmented_bus_ver : ENTITY work.segmented_bus
        PORT MAP(
            clk               => clk,
            rst               => rst_n,
            left_instruction  => bottom_partition_in,         --! Coming from down cell
            right_instruction => bus_ver_partition_top,       --! Coming from STile
            left_in           => noc_south_in,                --! Coming from down cell
            left_out          => noc_south_out,               --! Going to down cell
            right_in          => bus_ver_top_in,              --! Coming from STile
            right_out         => bus_ver_top_out,             --! Going to STile
            bus_direction     => bus_ver_direction            --! Going to down cell and STile
        );

    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- Address assignment unit
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    u_addres_assign : ENTITY work.addr_assign(RTL)
        PORT MAP(
            clk       => clk,
            rst_n     => rst_n,
            start_row => '0',
            start_col => start_col,
            prevRow   => prevRow,
            prevCol   => prevCol,
            valid     => valid,
            thisRow   => This_ROW,
            thisCol   => This_COL
        );
    thisRow <= This_ROW;
    thisCol <= This_COL;
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    -- STile
    --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    u_STILE : ENTITY work.STile(behv_rtl)
        GENERIC MAP(ID => 1)
        PORT MAP(
            rst_n => rst_n,
            clk   => clk,
            -- Address 
            This_ROW => This_ROW,
            This_COL => This_COL,
            -- Data interconnection
            north_out => data_north_out,   --! Going to the cell above
            south_out => data_south_out,   --! Going to the cell below
            east_out  => data_east_out,    --! Going to the cell on the right
            west_out  => data_west_out,    --! Going to the cell on the left
            north_in  => data_north_in,    --! Coming from the cell above
            south_in  => data_south_in,    --! Coming from the cell below
            east_in   => data_east_in,     --! Coming from the cell on the right
            west_in   => data_west_in,     --! Coming from the cell on the left
            -- Direction of neighboring buses
            north_splitter_direction => top_splitter_direction,   --! Coming from the cell above
            south_splitter_direction => bus_ver_direction,        --! Coming from the vertical bus
            east_splitter_direction  => right_splitter_direction, --! Coming from the cell on the right
            west_splitter_direction  => bus_hor_direction,        --! Coming from the horizontal bus
            -- Direction to neibouring busses
            top_instruction_out      => top_partition_out,        --! Going to the cell above
            bottom_instruction_out   => bus_ver_partition_top,    --! Going to the vertical bus
            right_instruction_out    => right_partition_out,      --! Going to the cell on the right
            left_instruction_out     => bus_hor_partition_right,  --! Going to the horizontal bus
            -- NoC interconnection
            VER_BUS_TOP_OUT     => noc_north_out,       --! Going to the cell above
            VER_BUS_BOTTOM_OUT  => bus_ver_top_in,      --! Going to the vertical bus
            HOR_BUS_RIGHT_OUT   => noc_east_out,        --! Going to the cell on the right
            HOR_BUS_LEFT_OUT    => bus_hor_right_in,    --! Going to the horizontal bus
            VER_BUS_TOP_IN      => noc_north_in,        --! Coming from the cell above
            VER_BUS_BOTTOM_IN   => bus_ver_top_out,     --! Coming from the vertical bus
            HOR_BUS_RIGHT_IN    => noc_east_in,         --! Coming from the cell on the right
            HOR_BUS_LEFT_IN     => bus_hor_right_out,   --! Coming from the horizontal bus
            -- Testbench signals
            tb_en          => tb_en,
            tb_addrs       => tb_addrs,
            tb_inp         => tb_inp,
            tb_ROW         => tb_ROW,
            tb_COL         => tb_COL
        );
END ARCHITECTURE;
