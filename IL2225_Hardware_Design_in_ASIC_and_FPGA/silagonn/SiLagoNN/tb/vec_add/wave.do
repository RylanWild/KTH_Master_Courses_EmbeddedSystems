
onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -divider
add wave -label clk   clk
add wave -label rst_n rst_n
add wave -divider "Counters"
add wave -noupdate -radix decimal /StimuliSequencer/*

add wave -divider "Compare Register Values"
add wave -group "RegFile <0, 0>"	-radix decimal \
	-label data_out_reg_0 	/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/data_out_reg_0_left		\
	-label data_out_reg_1 	/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/data_out_reg_1_left		\
	-label data_in_0 		/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/data_in_0					\
	-label data_in_1 		/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/data_in_1					\
	-label data_in_dimarch 		/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/dimarch_data_in					\
	-label reg_out			/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/reg_out
add wave -divider
add wave -divider "Cell <0, 0>"

add wave -group "Sequencer <0, 0>"	-radix decimal \
	-label pc 				 /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/seq_gen/pc				\
	-radix decimal \
	-label seq_address_match /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/seq_gen/seq_address_match	\
	-label instr_reg		 /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/seq_gen/instr_reg			\
	-label instr 			 /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/seq_gen/instr

add wave -group "DPU <0, 0>"	-radix decimal \
	-label dpu_in_0  /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/dpu_gen/dpu_in_0			\
	-label dpu_in_1  /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/dpu_gen/dpu_in_1			\
	-label dpu_in_2  /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/dpu_gen/dpu_in_2			\
	-label dpu_in_3  /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/dpu_gen/dpu_in_3			\
	-label dpu_mode  /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/dpu_gen/dpu_mode_cfg		\
	-label dpu_out_0 /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/dpu_gen/dpu_out_0	\
	-label dpu_out_1 /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/dpu_gen/dpu_out_1

add wave -group "Register File <0, 0>"	-radix decimal \
	-label instr_start 		/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/instr_start							\
	-label data_out_reg_0 	/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/data_out_reg_0_left		\
	-label data_out_reg_1 	/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/data_out_reg_1_left		\
	-label data_in_0 		/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/data_in_0					\
	-label data_in_1 		/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/data_in_1					\
	-label data_in_dimarch 		/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/dimarch_data_in					\
	-label reg_out			/DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/RegisterFile/reg_out
add wave -group "AGU Wr0 <0, 0>"	-radix decimal \
	-label instr_start /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Wr_0_instantiate/instr_start	\
	-label addr_out    /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Wr_0_instantiate/addr_out		\
	-label addr_en     /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Wr_0_instantiate/addr_en
add wave -group "AGU Wr1 <0, 0>"	-radix decimal \
	-label instr_start /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Wr_1_instantiate/instr_start	\
	-label addr_out    /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Wr_1_instantiate/addr_out		\
	-label addr_en     /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Wr_1_instantiate/addr_en
add wave -group "AGU Rd0 <0, 0>"	-radix decimal \
	-label instr_start /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Rd_0_instantiate/instr_start	\
	-label addr_out    /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Rd_0_instantiate/addr_out		\
	-label addr_en     /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Rd_0_instantiate/addr_en
add wave -group "AGU Rd1 <0, 0>"	-radix decimal \
	-label instr_start /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Rd_1_instantiate/instr_start	\
	-label addr_out    /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Rd_1_instantiate/addr_out		\
	-label addr_en     /DUT/MTRF_COLS(0)/MTRF_ROWS(0)/if_drra_top_l_corner/Silago_top_l_corner_inst/SILEGO_cell/MTRF_cell/reg_top/AGU_Rd_1_instantiate/addr_en


add wave -divider "SRAM Values"
add wave -group "DiMArch <1, 0>" \
  -label "BANK_0"  /DUT/dimarch/DiMArch_COLS(0)/DiMArch_ROWS(1)/if_dimarch_bot_l/DiMArchTile_bot_l/u_STILE/u_sram/sram_blocks(0)/u_sram_block_X/memory \
  -label "BANK_1"  /DUT/dimarch/DiMArch_COLS(0)/DiMArch_ROWS(1)/if_dimarch_bot_l/DiMArchTile_bot_l/u_STILE/u_sram/sram_blocks(1)/u_sram_block_X/memory
  -label "BANK_0"  /DUT/dimarch/DiMArch_COLS(0)/DiMArch_ROWS(1)/if_dimarch_top_l/DiMArchTile_top_l/u_STILE/u_sram/sram_blocks(0)/u_sram_block_X/memory \
  -label "BANK_1"  /DUT/dimarch/DiMArch_COLS(0)/DiMArch_ROWS(1)/if_dimarch_top_l/DiMArchTile_top_l/u_STILE/u_sram/sram_blocks(1)/u_sram_block_X/memory
  
TreeUpdate [SetDefaultTree]
WaveRestoreCursors { {Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 300
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {170 ns}

