
`ifndef _NAME_MANGLING_
`define _NAME_MANGLING_

import top_consts_types_package::*;

package name_mangling;

	parameter REG_FILE_DATA_WIDTH 		= top_consts_types_package::reg_file_data_width;
	parameter REG_FILE_ADDR_WIDTH 		= top_consts_types_package::reg_file_addr_width;
	parameter REG_FILE_DEPTH	  		= top_consts_types_package::reg_file_depth;
	parameter REG_FILE_MEM_DATA_WIDTH 	= top_consts_types_package::reg_file_mem_data_width;
	parameter ROWS 				  		= top_consts_types_package::rows;
	parameter COLUMNS 			  		= top_consts_types_package::columns;
	parameter INSTR_WIDTH		    	= top_consts_types_package::instr_width;
	parameter INSTR_CODE_RANGE_BASE 	= top_consts_types_package::instr_code_range_base;
	parameter INSTR_CODE_RANGE_END 		= top_consts_types_package::instr_code_range_end;
	parameter SRAM_WIDTH				= top_consts_types_package::sram_width;

	// DPU parameters
	parameter DPU_MODE_SEL_RANGE_BASE 			= top_consts_types_package::dpu_mode_sel_range_base;
	parameter DPU_MODE_SEL_RANGE_END 			= top_consts_types_package::dpu_mode_sel_range_end;
	// REFI1 parameters
	parameter NR_OF_REG_FILE_PORTS_RANGE_BASE 	= top_consts_types_package::nr_of_reg_file_ports_range_base;
	parameter NR_OF_REG_FILE_PORTS_RANGE_END 	= top_consts_types_package::nr_of_reg_file_ports_range_end;
	parameter STARTING_ADDRS_RANGE_BASE 		= top_consts_types_package::starting_addrs_range_base;
	parameter STARTING_ADDRS_RANGE_END 			= top_consts_types_package::starting_addrs_range_end;
	parameter NR_OF_ADDRS_RANGE_BASE 			= top_consts_types_package::nr_of_addrs_range_base;
	parameter NR_OF_ADDRS_RANGE_END 			= top_consts_types_package::nr_of_addrs_range_end;
	parameter INIT_DELAY_RANGE_BASE 			= top_consts_types_package::init_delay_range_base;
	parameter INIT_DELAY_RANGE_END 				= top_consts_types_package::init_delay_range_end;
	// REFI2 parameters
	parameter STEP_VALUE_RANGE_BASE 			= top_consts_types_package::step_value_range_base;
	parameter STEP_VALUE_RANGE_END 				= top_consts_types_package::step_value_range_end;
	parameter STEP_VALUE_SIGN_RANGE_BASE 		= top_consts_types_package::step_value_sign_range_base;
	parameter STEP_VALUE_SIGN_RANGE_END 		= top_consts_types_package::step_value_sign_range_end;
	parameter REG_FILE_MIDDLE_DELAY_RANGE_BASE 	= top_consts_types_package::reg_file_middle_delay_range_base;
	parameter REG_FILE_MIDDLE_DELAY_RANGE_END 	= top_consts_types_package::reg_file_middle_delay_range_end;
	parameter NUM_OF_REPT_RANGE_BASE 			= top_consts_types_package::num_of_rept_range_base;
	parameter NUM_OF_REPT_RANGE_END 			= top_consts_types_package::num_of_rept_range_end;
	parameter REP_STEP_VALUE_RANGE_BASE 		= top_consts_types_package::rep_step_value_range_base;
	parameter REP_STEP_VALUE_RANGE_END 			= top_consts_types_package::rep_step_value_range_end;
	// SWB parameters
	parameter SWB_SRC_ADDR_ROW_BASE 			= top_consts_types_package::swb_src_addr_row_base;
	parameter SWB_SRC_ADDR_ROW_END 				= top_consts_types_package::swb_src_addr_row_end;
	parameter SWB_SRC_DPU_REFI_BASE 			= top_consts_types_package::swb_src_dpu_refi_base;
	parameter SWB_SRC_DPU_REFI_END 				= top_consts_types_package::swb_src_dpu_refi_end;
	parameter SWB_SRC_OUTPUT_NR_BASE 			= top_consts_types_package::swb_src_output_nr_base;
	parameter SWB_SRC_OUTPUT_NR_END 			= top_consts_types_package::swb_src_output_nr_end;
	parameter SWB_HB_INDEX_BASE 				= top_consts_types_package::swb_hb_index_base;
	parameter SWB_HB_INDEX_END 					= top_consts_types_package::swb_hb_index_end;
	parameter SWB_SEND_TO_OTHER_ROW_BASE 		= top_consts_types_package::swb_send_to_other_row_base;
	parameter SWB_SEND_TO_OTHER_ROW_END 		= top_consts_types_package::swb_send_to_other_row_end;
	parameter SWB_V_INDEX_BASE 					= top_consts_types_package::swb_v_index_base;
	parameter SWB_V_INDEX_END 					= top_consts_types_package::swb_v_index_end;
	// DELAY parameters
	parameter DLY_CYCLES_RANGE_BASE 			= top_consts_types_package::dly_cycles_range_base;
	parameter DLY_CYCLES_RANGE_END 				= top_consts_types_package::dly_cycles_range_end;
	// Branch parameters
	parameter BR_MODE_RANGE_BASE	 			= top_consts_types_package::br_mode_range_base;
	parameter BR_MODE_RANGE_END		 			= top_consts_types_package::br_mode_range_end;
	parameter BR_FALSE_ADDRS_RANGE_BASE			= top_consts_types_package::br_false_addrs_range_base;
	parameter BR_FALSE_ADDRS_RANGE_END 			= top_consts_types_package::br_false_addrs_range_end;
	// Jump parameters
	parameter TRUE_ADDRS_RANGE_BASE 			= top_consts_types_package::true_addrs_range_base;
	parameter TRUE_ADDRS_RANGE_END	 			= top_consts_types_package::true_addrs_range_end;
	// RACCU parameters
	parameter RACCU_MODE_SEL_RANGE_BASE = top_consts_types_package::raccu_mode_sel_range_base;
	parameter RACCU_MODE_SEL_RANGE_END = top_consts_types_package::raccu_mode_sel_range_end;
	parameter RACCU_OPERAND1_RANGE_BASE = top_consts_types_package::raccu_operand1_range_base;
	parameter RACCU_OPERAND1_RANGE_END = top_consts_types_package::raccu_operand1_range_end;
	parameter RACCU_OPERAND2_RANGE_BASE = top_consts_types_package::raccu_operand2_range_base;
	parameter RACCU_OPERAND2_RANGE_END = top_consts_types_package::raccu_operand2_range_end;
	parameter RACCU_RESULT_ADDR_RANGE_BASE = top_consts_types_package::raccu_result_addr_range_base;
	parameter RACCU_RESULT_ADDR_RANGE_END = top_consts_types_package::raccu_result_addr_range_end;
	// FOR_HEADER parameters
	parameter FOR_INDEX_ADDR_RANGE_BASE = top_consts_types_package::for_index_addr_range_base;
	parameter FOR_INDEX_ADDR_RANGE_END = top_consts_types_package::for_index_addr_range_end;
	parameter FOR_INDEX_START_RANGE_BASE = top_consts_types_package::for_index_start_range_base;
	parameter FOR_INDEX_START_RANGE_END = top_consts_types_package::for_index_start_range_end;
	parameter FOR_ITER_NO_RANGE_BASE = top_consts_types_package::for_iter_no_range_base;
	parameter FOR_ITER_NO_RANGE_END = top_consts_types_package::for_iter_no_range_end;
	// FOR_TAIL parameters
	parameter FOR_TAIL_INDEX_ADDR_RANGE_BASE = top_consts_types_package::for_tail_index_addr_range_base;
	parameter FOR_TAIL_INDEX_ADDR_RANGE_END = top_consts_types_package::for_tail_index_addr_range_end;
	parameter FOR_INDEX_STEP_RANGE_BASE = top_consts_types_package::for_index_step_range_base;
	parameter FOR_INDEX_STEP_RANGE_END = top_consts_types_package::for_index_step_range_end;
	parameter FOR_PC_TOGO_RANGE_BASE = top_consts_types_package::for_pc_togo_range_base;
	parameter FOR_PC_TOGO_RANGE_END = top_consts_types_package::for_pc_togo_range_end;

endpackage

import name_mangling::*;

`endif //_NAME_MANGLING_
