library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.seq_functions_package.all;
use work.util_package.all;
use work.top_consts_types_package.all;
use work.noc_types_n_constants.all;
use work.crossbar_types_n_constants.all;

entity drra_wrapper is
  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    instr_ld       : in  std_logic;
    instr_inp      : in  std_logic_vector(INSTR_WIDTH - 1 downto 0);
    Immediate      : in  std_logic;
    seq_address_rb : in  std_logic_vector(ROWS - 1 downto 0);
    seq_address_cb : in  std_logic_vector(COLUMNS - 1 downto 0);

    dir_north_out_array : out DATA_IO_SIGNAL_TYPE(0 to COLUMNS - 1);
    dir_south_in_array  : in  DATA_IO_SIGNAL_TYPE(0 to COLUMNS - 1);

    top_instruction_out_array : out PARTITION_INSTRUCTION_TYPE(0 to COLUMNS - 1, 0 to 0);
    top_splitter_dir_in_array : in  DIRECTION_TYPE(0 to COLUMNS - 1, 0 to 0);

    SRAM_INST_ver_top_out : out INST_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to 0);
    SRAM_INST_ver_top_in  : in  INST_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to 0);
    noc_bus_out             : inout INST_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to ROWS - 1);  -- previous was only 0 to COLUMNS
    dimarch_silego_data_in  : inout DATA_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to ROWS - 1);
    dimarch_silego_data_out : inout DATA_SIGNAL_TYPE(0 to COLUMNS - 1, 0 to ROWS - 1);  -- previous was 0 to ROWS-1
    dimarch_silego_rd_out   : inout DATA_RD_TYPE(0 to COLUMNS - 1, 0 to 0)  -- previous second argument was 0 to ROWS-1
  );
end entity drra_wrapper;

architecture rtl of drra_wrapper is

  signal h_bus_reg_seg_0         : h_bus_seg_ty(0 to 2 * COLUMNS + 1, 0 to 2 * MAX_NR_OF_OUTP_N_HOPS);  --horizontal bus register file output 0
  signal h_bus_reg_seg_1         : h_bus_seg_ty(0 to 2 * COLUMNS + 1, 0 to 2 * MAX_NR_OF_OUTP_N_HOPS);  --horizontal bus register file output 1
  signal h_bus_dpu_seg_0         : h_bus_seg_ty(0 to 2 * COLUMNS + 1, 0 to 2 * MAX_NR_OF_OUTP_N_HOPS);  --horizontal bus dpu output 0
  signal h_bus_dpu_seg_1         : h_bus_seg_ty(0 to 2 * COLUMNS + 1, 0 to 2 * MAX_NR_OF_OUTP_N_HOPS);  --horizontal bus dpu output 1
  signal sel_r_seg               : s_bus_switchbox_2d_ty(0 to COLUMNS - 1, 0 to ROWS - 1);
  signal v_bus                   : v_bus_ty_2d(0 to COLUMNS - 1, 0 to ROWS - 1);
  --signal bus_direction_hor : PARTITION_INSTRUCTION_STATUS_TYPE(0 to COLUMNS+1, 0 to MAX_ROW+1);

  -- DRRA
  signal addr_valid_bot   : ADDR_VALID_TYPE(0 to 0, 0 to ROWS - 2);
  signal addr_valid_right : ADDR_VALID_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
  signal addr_valid_top   : ADDR_VALID_TYPE(0 to 0, 0 to MAX_ROW - 1);
  signal row_bot          : ROW_ADDR_TYPE(0 to 0, 0 to ROWS - 2);
  signal row_right        : ROW_ADDR_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
  signal row_top          : ROW_ADDR_TYPE(0 to 0, 0 to MAX_ROW - 1);
  signal col_bot          : COL_ADDR_TYPE(0 to 0, 0 to ROWS - 2);
  signal col_right        : COL_ADDR_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
  signal col_top          : COL_ADDR_TYPE(0 to 0, 0 to MAX_ROW - 1);

  -------------------------
  -- Instruction signals
  -------------------------
  signal instr_ld_right       : DATA_RD_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
  signal instr_ld_bot         : DATA_RD_TYPE(0 to 0, 0 to ROWS - 2);
  signal instr_inp_right      : INSTR_ARRAY_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
  signal instr_inp_bot        : INSTR_ARRAY_TYPE(0 to 0, 0 to ROWS - 2);
  signal seq_address_rb_right : SEQ_ADDR_RB_ARRAY_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
  signal seq_address_rb_bot   : SEQ_ADDR_RB_ARRAY_TYPE(0 to 0, 0 to ROWS - 2);
  signal seq_address_cb_right : SEQ_ADDR_CB_ARRAY_TYPE(0 to COLUMNS - 2, 0 to ROWS - 1);
  signal seq_address_cb_bot   : SEQ_ADDR_CB_ARRAY_TYPE(0 to 0, 0 to ROWS - 2);

  -------------------------
  -- DiMArch signals
  -------------------------
  signal left_splitter_dir_array : DIRECTION_TYPE(0 to COLUMNS - 2, 0 to MAX_ROW - 1);
  signal instruction_dir_right   : PARTITION_INSTRUCTION_TYPE(0 to COLUMNS - 2, 0 to MAX_ROW - 1);
  signal instruction_dir_top     : PARTITION_INSTRUCTION_TYPE(0 to COLUMNS - 1, 0 to MAX_ROW - 1);

begin

  MTRF_COLS : for i in 0 to COLUMNS - 1 generate
  begin
    MTRF_ROWS : for j in 0 to ROWS - 1 generate
    begin
      if_drra_top_l_corner : if j = 0 and i = 0 generate  -- top row, corners
        Silago_top_l_corner_inst : entity work.Silago_top_left_corner
          port map(
            clk       => clk,
            rst_n     => rst_n,
            Immediate => Immediate,
            valid_top   => addr_valid_top(i, j),  --! Valid signals, used to signal that the assignment of the address is complete
            thisRow_top => row_top(i, j),         --! The row address assigned to the cell
            thisCol_top => col_top(i, j),         --! The column address assigned to the cell
            valid_right   => addr_valid_right(i, j),  --! Valid signals, used to signal that the assignment of the address is complete
            thisRow_right => row_right(i, j),         --! The row address assigned to the cell
            thisCol_right => col_right(i, j),         --! The column address assigned to the cell
            valid_bot                  => addr_valid_bot(i, j),  --! Copy of the valid signal, connection to the bottom row
            thisRow_bot                => row_bot(i, j),  --! Copy of the row signal, connection to the bottom row
            thisCol_bot                => col_bot(i, j),  --! Copy of the col signal, connection to the bottom row
            data_in_next               => dimarch_silego_data_out(i, j + 1),  --! data from other row
            dimarch_silego_rd_out_next => dimarch_silego_rd_out(i, 0),        --! ready signal from the other row
            dimarch_data_in_out => dimarch_silego_data_in(i, j + 1),  --! data from DiMArch to the next row
            instr_ld                 => instr_ld,              --! load instruction signal
            instr_inp                => instr_inp,             --! Actual instruction to be loaded
            seq_address_rb           => seq_address_rb,        --! in order to generate addresses for sequencer rows
            seq_address_cb           => seq_address_cb,        --! in order to generate addresses for sequencer cols
            instr_ld_out_right       => instr_ld_right(i, j),  --! Registered instruction load signal, broadcast to the next cell
            instr_inp_out_right      => instr_inp_right(i, j),  --! Registered instruction signal, bradcast to the next cell
            seq_address_rb_out_right => seq_address_rb_right(i, j),  --! registered signal, broadcast to the next cell, in order to generate addresses for sequencer rows
            seq_address_cb_out_right => seq_address_cb_right(i, j),  --! registed signal, broadcast to the next cell, in order to generate addresses for sequencer cols

            instr_ld_out_bot           => instr_ld_bot(i, j),  --! Registered instruction load signal, broadcast to the next cell
            instr_inp_out_bot          => instr_inp_bot(i, j),  --! Registered instruction signal, bradcast to the next cell
            seq_address_rb_out_bot     => seq_address_rb_bot(i, j),  --! registered signal, broadcast to the next cell, in order to generate addresses for sequencer rows
            seq_address_cb_out_bot     => seq_address_cb_bot(i, j),  --! registed signal, broadcast to the next cell, in order to generate addresses for sequencer cols
            -- Data transfer only allowed through the dimarch
            dimarch_data_in            => dimarch_silego_data_in(i, j),   --! data from dimarch (top)
            dimarch_data_out           => dimarch_silego_data_out(i, j),  --! data out to dimarch (top)
            -- DiMArch bus output
            noc_bus_out                => noc_bus_out(i, j),   --! noc bus signal to the dimarch (top)
            -- NoC bus from the next row to the DiMArch
            noc_bus_in                 => noc_bus_out(i, j + 1),     --! noc bus signal from the adjacent row (bottom)

            -- Sliding window interconnect
            --Horizontal Busses
            h_bus_reg_in_out0_3_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 3),
            h_bus_reg_in_out0_4_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 4),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),
            h_bus_reg_in_out1_3_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 3),
            h_bus_reg_in_out1_4_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 4),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),
            h_bus_dpu_in_out0_3_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out0_4_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),
            h_bus_dpu_in_out1_3_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out1_4_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

      if_drra_top : if j = 0 and i > 0 and i < (COLUMNS - 1) generate  -- top row, non-corner case
        Silago_top_inst : entity work.Silago_top
          port map(
            clk                        => clk,
            rst_n                      => rst_n,
            ----------------------------------------------------
            -- REV 2 2020-02-11 --------------------------------
            ----------------------------------------------------
            -------------------------
            -- Pass-through clock and reset signals
            -------------------------
            -- clk_input  => clk_input_drra(i, j),    --! Propagation signal clk input 
            -- rst_input  => rst_input_drra(i, j),    --! Propagation signal rst input
            -- clk_output => clk_input_dimarch(i, j), --! Propagation signal clk output 
            -- rst_output => rst_input_dimarch(i, j), --! Propagation signal rst output
            Immediate                  => Immediate,
            ----------------------------------------------------
            -- End of modification REV 2 -----------------------
            ----------------------------------------------------
            -- Address signals
            -------------------------
            start_row                  => addr_valid_right(i - 1, j),  --! Start signal (connected to the valid signal of the previous block in the same row) 
            --start_col       => '0', --! Start signal (connected to the valid signal of the previous block in the same col) 
            prevRow                    => row_right(i - 1, j),  --! Row address assigned to the previous cell                     
            prevCol                    => col_right(i - 1, j),  --! Col address assigned to the previous cell                     
            valid                      => addr_valid_right(i, j),  --! Valid signals, used to signal that the assignment of the address is complete       
            thisRow                    => row_right(i, j),  --! The row address assigned to the cell                          
            thisCol                    => col_right(i, j),  --! The column address assigned to the cell                       
            ------------------------------
            -- Data in (from next row)
            ------------------------------
            data_in_next               => dimarch_silego_data_out(i, j + 1),  --! data from other row   
            dimarch_silego_rd_out_next => dimarch_silego_rd_out(i, 0),  --! ready signal from the other row         

            ------------------------------
            -- Data out to DiMArch
            ------------------------------
            dimarch_data_in_out => dimarch_silego_data_in(i, j + 1),  --! data from DiMArch to the next row 

            ------------------------------
            -- Global signals for configuration
            ------------------------------
            -- inputs (left hand side)
            instr_ld                   => instr_ld_right(i - 1, j),  --! load instruction signal                                                                                                     
            instr_inp                  => instr_inp_right(i - 1, j),  --! Actual instruction to be loaded                                                            
            seq_address_rb             => seq_address_rb_right(i - 1, j),  --! in order to generate addresses for sequencer rows                                                 
            seq_address_cb             => seq_address_cb_right(i - 1, j),  --! in order to generate addresses for sequencer cols                                              
            -- outputs (right hand side)
            instr_ld_out               => instr_ld_right(i, j),  --! Registered instruction load signal, broadcast to the next cell                                                              
            instr_inp_out              => instr_inp_right(i, j),  --! Registered instruction signal, bradcast to the next cell                                   
            seq_address_rb_out         => seq_address_rb_right(i, j),  --! registered signal, broadcast to the next cell, in order to generate addresses for sequencer rows  
            seq_address_cb_out         => seq_address_cb_right(i, j),  --! registed signal, broadcast to the next cell, in order to generate addresses for sequencer cols 
            ------------------------------
            -- Silego core cell
            ------------------------------
            --RegFile
            -- Data transfer only allowed through the dimarch
            dimarch_data_in            => dimarch_silego_data_in(i, j),    --! data from dimarch (top)
            dimarch_data_out           => dimarch_silego_data_out(i, j),   --! data out to dimarch (top)
            ------------------------------
            -- DiMArch bus output
            ------------------------------
            noc_bus_out                => noc_bus_out(i, j),     --! noc bus signal to the dimarch (top)
            ------------------------------
            -- NoC bus from the next row to the DiMArch
            ------------------------------
            -- TODO we can move the noc bus selector from the DiMArch to the cell in order to save some routing
            noc_bus_in                 => noc_bus_out(i, j + 1),  --! noc bus signal from the adjacent row (bottom)                          
            ------------------------------
            --Horizontal Busses
            ------------------------------
            --Horizontal Busses
            h_bus_reg_in_out0_0_left   => h_bus_reg_seg_0(2 * i + j, 0),   -- h_bus_reg_seg_0(i+1,0) ,
            h_bus_reg_in_out0_1_left   => h_bus_reg_seg_0(2 * i + j, 1),   --h_bus_reg_seg_0(i+1,1),
            h_bus_reg_in_out0_3_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 3),
            h_bus_reg_in_out0_4_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 4),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),
            h_bus_reg_in_out1_0_left   => h_bus_reg_seg_1(2 * i + j, 0),
            h_bus_reg_in_out1_1_left   => h_bus_reg_seg_1(2 * i + j, 1),
            h_bus_reg_in_out1_3_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 3),
            h_bus_reg_in_out1_4_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 4),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),

            h_bus_dpu_in_out0_0_left   => h_bus_dpu_seg_0(2 * i + j, 0),
            h_bus_dpu_in_out0_1_left   => h_bus_dpu_seg_0(2 * i + j, 1),
            h_bus_dpu_in_out0_3_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out0_4_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),
            h_bus_dpu_in_out1_0_left   => h_bus_dpu_seg_1(2 * i + j, 0),
            h_bus_dpu_in_out1_1_left   => h_bus_dpu_seg_1(2 * i + j, 1),
            h_bus_dpu_in_out1_3_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out1_4_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            --sel_r_ext_in               
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            --ext_v_input_bus_in        =>    
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            --sel_r_ext_out             =>    
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            --ext_v_input_bus_out       =>    
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

      if_drra_top_r_corner : if j = 0 and i = COLUMNS - 1 generate     -- top row, corners
        Silago_top_r_corner_inst : entity work.Silago_top_right_corner
          port map(
            clk                        => clk,
            rst_n                      => rst_n,
            ----------------------------------------------------
            -- REV 2 2020-02-11 --------------------------------
            ----------------------------------------------------
            -------------------------
            -- Pass-through clock and reset signals
            -------------------------
            -- clk_input  => clk_input_drra(i, j),    --! Propagation signal clk input 
            -- rst_input  => rst_input_drra(i, j),    --! Propagation signal rst input
            -- clk_output => clk_input_dimarch(i, j), --! Propagation signal clk output 
            -- rst_output => rst_input_dimarch(i, j), --! Propagation signal rst output
            Immediate                  => Immediate,
            ----------------------------------------------------
            -- End of modification REV 2 -----------------------
            ----------------------------------------------------
            -------------------------
            -- Address signals
            -------------------------
            start_row                  => addr_valid_right(i - 1, j),  --! Start signal (connected to the valid signal of the previous block in the same row) 
            --start_col       => '0', --! Start signal (connected to the valid signal of the previous block in the same col) 
            prevRow                    => row_right(i - 1, j),  --! Row address assigned to the previous cell                     
            prevCol                    => col_right(i - 1, j),  --! Col address assigned to the previous cell 
            ------------------------------
            -- Data in (from next row)
            ------------------------------
            data_in_next               => dimarch_silego_data_out(i, j + 1),  --! data from other row
            dimarch_silego_rd_out_next => dimarch_silego_rd_out(i, 0),        --! ready signal from the other row

            ------------------------------
            -- Data out to DiMArch
            ------------------------------
            dimarch_data_in_out => dimarch_silego_data_in(i, j + 1),  --! data from DiMArch to the next row

            ------------------------------
            -- Global signals for configuration
            ------------------------------
            -- inputs (left hand side)
            instr_ld                   => instr_ld_right(i - 1, j),  --! load instruction signal                                                                                                     
            instr_inp                  => instr_inp_right(i - 1, j),  --! Actual instruction to be loaded                                                            
            seq_address_rb             => seq_address_rb_right(i - 1, j),  --! in order to generate addresses for sequencer rows                                                 
            seq_address_cb             => seq_address_cb_right(i - 1, j),  --! in order to generate addresses for sequencer cols 
            ------------------------------
            -- Silego core cell
            ------------------------------
            --RegFile
            -- Data transfer only allowed through the dimarch
            dimarch_data_in            => dimarch_silego_data_in(i, j),    --! data from dimarch (top)
            dimarch_data_out           => dimarch_silego_data_out(i, j),   --! data out to dimarch (top)
            ------------------------------
            -- DiMArch bus output
            ------------------------------
            noc_bus_out                => noc_bus_out(i, j),         --! noc bus signal to the dimarch (top)
            ------------------------------
            -- NoC bus from the next row to the DiMArch
            ------------------------------
            -- TODO we can move the noc bus selector from the DiMArch to the cell in order to save some routing
            noc_bus_in                 => noc_bus_out(i, j + 1),     --! noc bus signal from the adjacent row (bottom)
            ------------------------------
            --Horizontal Busses
            ------------------------------
            ---------------------------------------------------------------------------------------
            -- Modified by Dimitris to remove inputs and outputs that are not connected (left hand side)
            -- Date 15/03/2018
            ---------------------------------------------------------------------------------------
            --Horizontal Busses
            h_bus_reg_in_out0_0_left   => h_bus_reg_seg_0(2 * i + j, 0),
            h_bus_reg_in_out0_1_left   => h_bus_reg_seg_0(2 * i + j, 1),
            --h_bus_reg_in_out0_3_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 3),
            --h_bus_reg_in_out0_4_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 4),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),

            h_bus_reg_in_out1_0_left   => h_bus_reg_seg_1(2 * i + j, 0),
            h_bus_reg_in_out1_1_left   => h_bus_reg_seg_1(2 * i + j, 1),
            --h_bus_reg_in_out1_3_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 3),
            --h_bus_reg_in_out1_4_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 4),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),

            h_bus_dpu_in_out0_0_left   => h_bus_dpu_seg_0(2 * i + j, 0),
            h_bus_dpu_in_out0_1_left   => h_bus_dpu_seg_0(2 * i + j, 1),
            --h_bus_dpu_in_out0_3_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 3),
            --h_bus_dpu_in_out0_4_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),

            h_bus_dpu_in_out1_0_left   => h_bus_dpu_seg_1(2 * i + j, 0),
            h_bus_dpu_in_out1_1_left   => h_bus_dpu_seg_1(2 * i + j, 1),
            --h_bus_dpu_in_out1_3_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 3),
            --h_bus_dpu_in_out1_4_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            --sel_r_ext_in               
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            --ext_v_input_bus_in        =>    
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            --sel_r_ext_out             =>    
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            --ext_v_input_bus_out       =>    
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

      if_drra_bot_l_corner : if j = (ROWS - 1) and i = 0 generate  -- bottom row, corner case
        Silago_bot_l_corner_inst : entity work.Silago_bot_left_corner
          port map(
            clk       => clk,
            rst_n     => rst_n,
            ----------------------------------------------------
            -- REV 2 2020-02-11 --------------------------------
            ----------------------------------------------------
            -------------------------
            -- Pass-through clock and reset signals
            -------------------------
            -- clk_input  => clk_input_drra(i, j),    --! Propagation signal clk input 
            -- rst_input  => rst_input_drra(i, j),    --! Propagation signal rst input
            -- clk_output => clk_input_dimarch(i, j), --! Propagation signal clk output 
            -- rst_output => rst_input_dimarch(i, j), --! Propagation signal rst output
            Immediate => Immediate,
            ----------------------------------------------------
            -- End of modification REV 2 -----------------------
            ----------------------------------------------------

            -------------------------
            -- Address signals
            -------------------------
            --start_row               => '0', --! Start signal (connected to the valid signal of the previous block in the same row)
            start_col        => addr_valid_bot(i, j - 1),  --! Start signal (connected to the valid signal of the previous block in the same col)
            prevRow          => row_bot(i, j - 1),       --! Row address assigned to the previous cell
            prevCol          => col_bot(i, j - 1),       --! Col address assigned to the previous cell
            valid            => addr_valid_right(i, j),  --! Valid signals, used to signal that the assignment of the address is complete
            thisRow          => row_right(i, j),         --! The row address assigned to the cell
            thisCol          => col_right(i, j),         --! The column address assigned to the cell
            ------------------------------
            -- Data in (from next row)
            ------------------------------
            -- TODO In this version we have removed the incoming connections from the top row, if a DiMArch is connected to the bottom row also a better scheme needs to be decided
            --    data_in_next                 : in  STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data from other row
            --    dimarch_silego_rd_2_out_next : in  std_logic; --! ready signal from the other row
            ------------------------------
            -- Data in (to next row)
            ------------------------------
            dimarch_rd_out   => dimarch_silego_rd_out(i, 0),    --! ready signal to the adjacent row (top)
            dimarch_data_out => dimarch_silego_data_out(i, j),  --! data out to the adjacent row (top)

            ------------------------------
            -- Global signals for configuration
            ------------------------------
            -- inputs
            instr_ld           => instr_ld_bot(i, j - 1),      --! load instruction signal
            instr_inp          => instr_inp_bot(i, j - 1),     --! Actual instruction to be loaded
            seq_address_rb     => seq_address_rb_bot(i, j - 1),  --! in order to generate addresses for sequencer rows
            seq_address_cb     => seq_address_cb_bot(i, j - 1),  --! in order to generate addresses for sequencer cols
            -- outputs
            instr_ld_out       => instr_ld_right(i, j),  --! Registered instruction load signal, broadcast to the next cell
            instr_inp_out      => instr_inp_right(i, j),  --! Registered instruction signal, bradcast to the next cell
            seq_address_rb_out => seq_address_rb_right(i, j),  --! registered signal, broadcast to the next cell, in order to generate addresses for sequencer rows
            seq_address_cb_out => seq_address_cb_right(i, j),  --! registed signal, broadcast to the next cell, in order to generate addresses for sequencer cols

            ------------------------------
            -- Silego core cell
            ------------------------------

            -----------------------------
            -- DiMArch data
            -----------------------------
            dimarch_data_in            => dimarch_silego_data_in(i, j),  --! data from dimarch (through the adjacent cell) (top)
            -- TODO this signal has been removed in this version, if a DiMArch is connected to the bottom row also we need a better shceme
            --    dimarch_data_out             : out STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data out to dimarch (bot)
            -- DiMArch bus output
            noc_bus_out                => noc_bus_out(i, j),  --! NoC bus signal to the adjacent row (top), to be propagated to the DiMArch
            -----------------------------
            --Horizontal Busses
            -----------------------------
            ---------------------------------------------------------------------------------------
            -- Modified by Dimitris to remove inputs and outputs that are not connected (left hand side)
            -- Date 15/03/2018
            ---------------------------------------------------------------------------------------
            --Horizontal Busses
            --h_bus_reg_in_out0_0_left   => h_bus_reg_seg_0(2 * i + j, 0),
            --h_bus_reg_in_out0_1_left   => h_bus_reg_seg_0(2 * i + j, 1), 
            h_bus_reg_in_out0_3_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 3),
            h_bus_reg_in_out0_4_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 4),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),

            --h_bus_reg_in_out1_0_left   => h_bus_reg_seg_1(2 * i + j, 0),
            --h_bus_reg_in_out1_1_left   => h_bus_reg_seg_1(2 * i + j, 1),
            h_bus_reg_in_out1_3_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 3),
            h_bus_reg_in_out1_4_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 4),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),

            --h_bus_dpu_in_out0_0_left   => h_bus_dpu_seg_0(2 * i + j, 0),
            --h_bus_dpu_in_out0_1_left   => h_bus_dpu_seg_0(2 * i + j, 1),
            h_bus_dpu_in_out0_3_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out0_4_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),

            --h_bus_dpu_in_out1_0_left   => h_bus_dpu_seg_1(2 * i + j, 0),
            --h_bus_dpu_in_out1_1_left   => h_bus_dpu_seg_1(2 * i + j, 1),
            h_bus_dpu_in_out1_3_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out1_4_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            --sel_r_ext_in               
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            --ext_v_input_bus_in        =>    
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            --sel_r_ext_out             =>    
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            --ext_v_input_bus_out       =>    
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

      if_drra_bot : if j = (ROWS - 1) and i > 0 and i < (COLUMNS - 1) generate  -- bottom row, non-corner case
        Silago_bot_inst : entity work.Silago_bot
          port map(
            clk              => clk,
            rst_n            => rst_n,
            ----------------------------------------------------
            -- REV 2 2020-02-11 --------------------------------
            ----------------------------------------------------
            -------------------------
            -- Pass-through clock and reset signals
            -------------------------
            -- clk_input  => clk_input_drra(i, j),    --! Propagation signal clk input 
            -- rst_input  => rst_input_drra(i, j),    --! Propagation signal rst input
            -- clk_output => clk_input_dimarch(i, j), --! Propagation signal clk output 
            -- rst_output => rst_input_dimarch(i, j), --! Propagation signal rst output
            Immediate        => Immediate,
            ----------------------------------------------------
            -- End of modification REV 2 -----------------------
            ----------------------------------------------------
            -------------------------
            -- Address signals
            -------------------------
            start_row        => addr_valid_right(i - 1, j),  --! Start signal (connected to the valid signal of the previous block in the same row) 
            --start_col       => '0', --! Start signal (connected to the valid signal of the previous block in the same col) 
            prevRow          => row_right(i - 1, j),  --! Row address assigned to the previous cell                     
            prevCol          => col_right(i - 1, j),  --! Col address assigned to the previous cell                     
            valid            => addr_valid_right(i, j),  --! Valid signals, used to signal that the assignment of the address is complete       
            thisRow          => row_right(i, j),      --! The row address assigned to the cell                          
            thisCol          => col_right(i, j),      --! The column address assigned to the cell  
            ------------------------------
            -- Data in (from next row)
            ------------------------------
            -- TODO In this version we have removed the incoming connections from the top row, if a DiMArch is connected to the bottom row also a better scheme needs to be decided
            --    data_in_next                 : in  STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data from other row
            --    dimarch_silego_rd_2_out_next : in  std_logic; --! ready signal from the other row
            ------------------------------
            -- Data in (to next row)
            ------------------------------
            dimarch_rd_out   => dimarch_silego_rd_out(i, 0),  --! ready signal to the adjacent row (top)
            dimarch_data_out => dimarch_silego_data_out(i, j),                  --! data out to the adjacent row (top)

            ------------------------------
            -- Global signals for configuration
            ------------------------------
            -- inputs (left hand side)
            instr_ld                   => instr_ld_right(i - 1, j),  --! load instruction signal                                                                                                     
            instr_inp                  => instr_inp_right(i - 1, j),  --! Actual instruction to be loaded                                                            
            seq_address_rb             => seq_address_rb_right(i - 1, j),  --! in order to generate addresses for sequencer rows                                                 
            seq_address_cb             => seq_address_cb_right(i - 1, j),  --! in order to generate addresses for sequencer cols                                              
            -- outputs (right hand side)
            instr_ld_out               => instr_ld_right(i, j),  --! Registered instruction load signal, broadcast to the next cell                                                              
            instr_inp_out              => instr_inp_right(i, j),  --! Registered instruction signal, bradcast to the next cell                                   
            seq_address_rb_out         => seq_address_rb_right(i, j),  --! registered signal, broadcast to the next cell, in order to generate addresses for sequencer rows  
            seq_address_cb_out         => seq_address_cb_right(i, j),  --! registed signal, broadcast to the next cell, in order to generate addresses for sequencer cols 
            ------------------------------
            -- Silego core cell
            ------------------------------
            --RegFile
            -----------------------------
            -- DiMArch data
            -----------------------------
            dimarch_data_in            => dimarch_silego_data_in(i, j),  --! data from dimarch (through the adjacent cell) (top)
            -- TODO this signal has been removed in this version, if a DiMArch is connected to the bottom row also we need a better shceme
            --    dimarch_data_out             : out STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data out to dimarch (bot)
            -- DiMArch bus output
            noc_bus_out                => noc_bus_out(i, j),  --! NoC bus signal to the adjacent row (top), to be propagated to the DiMArch
            -----------------------------
            --Horizontal Busses
            -----------------------------
            --Horizontal Busses
            h_bus_reg_in_out0_0_left   => h_bus_reg_seg_0(2 * i + j, 0),   -- h_bus_reg_seg_0(i+1,0) ,
            h_bus_reg_in_out0_1_left   => h_bus_reg_seg_0(2 * i + j, 1),   --h_bus_reg_seg_0(i+1,1),
            h_bus_reg_in_out0_3_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 3),
            h_bus_reg_in_out0_4_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 4),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),
            h_bus_reg_in_out1_0_left   => h_bus_reg_seg_1(2 * i + j, 0),
            h_bus_reg_in_out1_1_left   => h_bus_reg_seg_1(2 * i + j, 1),
            h_bus_reg_in_out1_3_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 3),
            h_bus_reg_in_out1_4_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 4),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),

            h_bus_dpu_in_out0_0_left   => h_bus_dpu_seg_0(2 * i + j, 0),
            h_bus_dpu_in_out0_1_left   => h_bus_dpu_seg_0(2 * i + j, 1),
            h_bus_dpu_in_out0_3_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out0_4_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),
            h_bus_dpu_in_out1_0_left   => h_bus_dpu_seg_1(2 * i + j, 0),
            h_bus_dpu_in_out1_1_left   => h_bus_dpu_seg_1(2 * i + j, 1),
            h_bus_dpu_in_out1_3_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 3),
            h_bus_dpu_in_out1_4_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            --sel_r_ext_in               
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            --ext_v_input_bus_in        =>    
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            --sel_r_ext_out             =>    
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            --ext_v_input_bus_out       =>    
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

      if_drra_bot_r_corner : if j = (ROWS - 1) and i = COLUMNS - 1 generate  -- bottom row, corner case
        Silago_bot_r_corner_inst : entity work.Silago_bot_right_corner
          port map(
            clk       => clk,
            rst_n     => rst_n,
            ----------------------------------------------------
            -- REV 2 2020-02-11 --------------------------------
            ----------------------------------------------------
            -------------------------
            -- Pass-through clock and reset signals
            -------------------------
            -- clk_input  => clk_input_drra(i, j),    --! Propagation signal clk input 
            -- rst_input  => rst_input_drra(i, j),    --! Propagation signal rst input
            -- clk_output => clk_input_dimarch(i, j), --! Propagation signal clk output 
            -- rst_output => rst_input_dimarch(i, j), --! Propagation signal rst output
            Immediate => Immediate,
            ----------------------------------------------------
            -- End of modification REV 2 -----------------------
            ----------------------------------------------------

            -------------------------
            -- Address signals
            -------------------------
            start_row        => addr_valid_right(i - 1, j),  --! Start signal (connected to the valid signal of the previous block in the same row) 
            --start_col       => '0', --! Start signal (connected to the valid signal of the previous block in the same col) 
            prevRow          => row_right(i - 1, j),         --! Row address assigned to the previous cell
            prevCol          => col_right(i - 1, j),         --! Col address assigned to the previous cell
            ------------------------------
            -- Data in (from next row)
            ------------------------------
            -- TODO In this version we have removed the incoming connections from the top row, if a DiMArch is connected to the bottom row also a better scheme needs to be decided
            --    data_in_next                 : in  STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data from other row
            --    dimarch_silego_rd_2_out_next : in  std_logic; --! ready signal from the other row
            ------------------------------
            -- Data in (to next row)
            ------------------------------
            dimarch_rd_out   => dimarch_silego_rd_out(i, 0),    --! ready signal to the adjacent row (top)
            dimarch_data_out => dimarch_silego_data_out(i, j),  --! data out to the adjacent row (top)

            ------------------------------
            -- Global signals for configuration
            ------------------------------
            -- inputs
            instr_ld       => instr_ld_right(i - 1, j),  --! load instruction signal                                                                                                     
            instr_inp      => instr_inp_right(i - 1, j),  --! Actual instruction to be loaded                                                            
            seq_address_rb => seq_address_rb_right(i - 1, j),  --! in order to generate addresses for sequencer rows                                                 
            seq_address_cb => seq_address_cb_right(i - 1, j),  --! in order to generate addresses for sequencer cols 

            ------------------------------
            -- Silego core cell
            ------------------------------

            -----------------------------
            -- DiMArch data
            -----------------------------
            dimarch_data_in            => dimarch_silego_data_in(i, j),  --! data from dimarch (through the adjacent cell) (top)
            -- TODO this signal has been removed in this version, if a DiMArch is connected to the bottom row also we need a better shceme
            --    dimarch_data_out             : out STD_LOGIC_VECTOR(SRAM_WIDTH - 1 downto 0); --! data out to dimarch (bot)
            -- DiMArch bus output
            noc_bus_out                => noc_bus_out(i, j),  --! NoC bus signal to the adjacent row (top), to be propagated to the DiMArch
            -----------------------------
            --Horizontal Busses
            -----------------------------
            ---------------------------------------------------------------------------------------
            -- Modified by Dimitris to remove inputs and outputs that are not connected (left hand side)
            -- Date 15/03/2018
            ---------------------------------------------------------------------------------------
            --Horizontal Busses
            h_bus_reg_in_out0_0_left   => h_bus_reg_seg_0(2 * i + j, 0),
            h_bus_reg_in_out0_1_left   => h_bus_reg_seg_0(2 * i + j, 1),
            --h_bus_reg_in_out0_3_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 3),
            --h_bus_reg_in_out0_4_right  => h_bus_reg_seg_0(2 * (i + 1) + j, 4),
            h_bus_reg_out_out0_0_right => h_bus_reg_seg_0(2 * (i + 1) + j, 0),
            h_bus_reg_out_out0_1_right => h_bus_reg_seg_0(2 * (i + 1) + j, 1),
            h_bus_reg_out_out0_3_left  => h_bus_reg_seg_0(2 * i + j, 3),
            h_bus_reg_out_out0_4_left  => h_bus_reg_seg_0(2 * i + j, 4),

            h_bus_reg_in_out1_0_left   => h_bus_reg_seg_1(2 * i + j, 0),
            h_bus_reg_in_out1_1_left   => h_bus_reg_seg_1(2 * i + j, 1),
            --h_bus_reg_in_out1_3_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 3),
            --h_bus_reg_in_out1_4_right  => h_bus_reg_seg_1(2 * (i + 1) + j, 4),
            h_bus_reg_out_out1_0_right => h_bus_reg_seg_1(2 * (i + 1) + j, 0),
            h_bus_reg_out_out1_1_right => h_bus_reg_seg_1(2 * (i + 1) + j, 1),
            h_bus_reg_out_out1_3_left  => h_bus_reg_seg_1(2 * i + j, 3),
            h_bus_reg_out_out1_4_left  => h_bus_reg_seg_1(2 * i + j, 4),

            h_bus_dpu_in_out0_0_left   => h_bus_dpu_seg_0(2 * i + j, 0),
            h_bus_dpu_in_out0_1_left   => h_bus_dpu_seg_0(2 * i + j, 1),
            --h_bus_dpu_in_out0_3_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 3),
            --h_bus_dpu_in_out0_4_right  => h_bus_dpu_seg_0(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out0_0_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out0_1_right => h_bus_dpu_seg_0(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out0_3_left  => h_bus_dpu_seg_0(2 * i + j, 3),
            h_bus_dpu_out_out0_4_left  => h_bus_dpu_seg_0(2 * i + j, 4),

            h_bus_dpu_in_out1_0_left   => h_bus_dpu_seg_1(2 * i + j, 0),
            h_bus_dpu_in_out1_1_left   => h_bus_dpu_seg_1(2 * i + j, 1),
            --h_bus_dpu_in_out1_3_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 3),
            --h_bus_dpu_in_out1_4_right  => h_bus_dpu_seg_1(2 * (i + 1) + j, 4),
            h_bus_dpu_out_out1_0_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 0),
            h_bus_dpu_out_out1_1_right => h_bus_dpu_seg_1(2 * (i + 1) + j, 1),
            h_bus_dpu_out_out1_3_left  => h_bus_dpu_seg_1(2 * i + j, 3),
            h_bus_dpu_out_out1_4_left  => h_bus_dpu_seg_1(2 * i + j, 4),

            --Vertical Busses
            --sel_r_ext_in               
            sel_r_ext_in_0        => sel_r_seg(i, j)(0),
            sel_r_ext_in_1        => sel_r_seg(i, j)(1),
            sel_r_ext_in_2        => sel_r_seg(i, j)(2),
            sel_r_ext_in_3        => sel_r_seg(i, j)(3),
            sel_r_ext_in_4        => sel_r_seg(i, j)(4),
            sel_r_ext_in_5        => sel_r_seg(i, j)(5),
            --ext_v_input_bus_in        =>    
            ext_v_input_bus_in_0  => v_bus(i, j)(0),
            ext_v_input_bus_in_1  => v_bus(i, j)(1),
            ext_v_input_bus_in_2  => v_bus(i, j)(2),
            ext_v_input_bus_in_3  => v_bus(i, j)(3),
            ext_v_input_bus_in_4  => v_bus(i, j)(4),
            ext_v_input_bus_in_5  => v_bus(i, j)(5),
            --sel_r_ext_out             =>    
            sel_r_ext_out_0       => sel_r_seg(i, (j + 1) mod 2)(0),
            sel_r_ext_out_1       => sel_r_seg(i, (j + 1) mod 2)(1),
            sel_r_ext_out_2       => sel_r_seg(i, (j + 1) mod 2)(2),
            sel_r_ext_out_3       => sel_r_seg(i, (j + 1) mod 2)(3),
            sel_r_ext_out_4       => sel_r_seg(i, (j + 1) mod 2)(4),
            sel_r_ext_out_5       => sel_r_seg(i, (j + 1) mod 2)(5),
            --ext_v_input_bus_out       =>    
            ext_v_input_bus_out_0 => v_bus(i, (j + 1) mod 2)(0),
            ext_v_input_bus_out_1 => v_bus(i, (j + 1) mod 2)(1),
            ext_v_input_bus_out_2 => v_bus(i, (j + 1) mod 2)(2),
            ext_v_input_bus_out_3 => v_bus(i, (j + 1) mod 2)(3),
            ext_v_input_bus_out_4 => v_bus(i, (j + 1) mod 2)(4),
            ext_v_input_bus_out_5 => v_bus(i, (j + 1) mod 2)(5)
            );
      end generate;

    end generate MTRF_ROWS;

  end generate MTRF_COLS;
end architecture;
