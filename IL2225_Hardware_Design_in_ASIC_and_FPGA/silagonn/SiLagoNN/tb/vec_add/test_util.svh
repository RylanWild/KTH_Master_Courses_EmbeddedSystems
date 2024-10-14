
`ifndef _TEST_UTIL_
`define _TEST_UTIL_

`include "macros.svh"

package test_util;

`include "type_def.svh"

	RegData regData[ROWS][COLUMNS];
	SequencerData sequencerData[ROWS][COLUMNS];
	SramData sramData[ROWS-1][COLUMNS];
	string regFileActivities[ROWS][COLUMNS];
	string sequencerActivities[ROWS][COLUMNS];
	int oldpcs[ROWS][COLUMNS];
	InstructionCode instructionCode;

	function automatic string getRegValueStr(shortint row, col, address, data, portNo, executionCycle, variablesStartAddr, addressOffset,
											 bit is_input, string regVariable, bit is_fixed_point, bit ignoreWriteAccess, output string resultStr);
		
		const string name = is_input ? (portNo == 0 ? "in0 :" : "in1 :") : (portNo == 0 ? "out0:" : "out1:");
		const string dataValue = is_fixed_point ? $sformatf("%.4f", data * 2.0 ** -15) : $sformatf("%2d", data);
		const string lineStr = $sformatf({(is_input ? "WT" : "RD"), ": %1s(%2d) = ", dataValue, "; \t{ addr_", name, " %2d, data_", name, " %2d }"},
		         			regVariable, addressOffset + address - variablesStartAddr + 1, address, data);
		const string timeStr = $sformatf(",\t@ %5d ns (cycle: %2d)", $time, executionCycle);

		regFileActivities[row][col] = {regFileActivities[row][col], lineStr, timeStr, "\n"};
		resultStr = is_input && !ignoreWriteAccess ? $sformatf({"\n%1s(%2d)=", dataValue}, regVariable, addressOffset + address - variablesStartAddr + 1) : "";

		return lineStr;
	endfunction

	function automatic string printDimarchData(integer fileId, shortint executionCycle);

		for (int col = 0; col < COLUMNS; col++)
			if (`currSramData.writeEn)
				$fdisplay(fileId, printStileData(0, col, executionCycle, `currSramData.writeAddress, `currSramData.data));

	endfunction

	function automatic string printStileData(shortint row, col, executionCycle, address, logic [SRAM_WIDTH-1:0] data);
		const string timeStr = $sformatf(",\t@ %5d ns (cycle: %2d)", $time, executionCycle);
		return $sformatf("\nWT to SRAM(%1d,%1d), ADDRESS(%3d) -> %h%s", row, col, address, data, timeStr);
	endfunction

	function automatic void createSequencerActivity(int row, col, executionCycle);

		string instDetail;

		if (`currSequencerData.pc != oldpcs[row][col])
		begin
			instructionCode = InstructionCode'(`currInstruction[INSTR_CODE_RANGE_BASE:INSTR_CODE_RANGE_END]);

			// Specifying the instruction details
			case (instructionCode)
				iDpu:
					instDetail = $sformatf("mode: %0d", `currInstruction[DPU_MODE_SEL_RANGE_BASE : DPU_MODE_SEL_RANGE_END]);
				iRefi:
					instDetail = $sformatf("port: %0d, startAddr: %0d, noOfAddr: %0d, initialDelay: %0d",
						 `currInstruction[NR_OF_REG_FILE_PORTS_RANGE_BASE : NR_OF_REG_FILE_PORTS_RANGE_END],
						 `currInstruction[STARTING_ADDRS_RANGE_BASE 	  :       STARTING_ADDRS_RANGE_END],
						 `currInstruction[NR_OF_ADDRS_RANGE_BASE		  : 	     NR_OF_ADDRS_RANGE_END],
						 `currInstruction[INIT_DELAY_RANGE_BASE			  : 		  INIT_DELAY_RANGE_END]); 
				iRefi2:
					instDetail = $sformatf("stepVal: %0d, stepValSign: %0d, middleDelay: %0d, noOfRepetition: %0d, repetitionStepVal: %0d",
						 `currInstruction[STEP_VALUE_RANGE_BASE 			: 			 STEP_VALUE_RANGE_END],
						 `currInstruction[STEP_VALUE_SIGN_RANGE_BASE		: 		STEP_VALUE_SIGN_RANGE_END],
						 `currInstruction[REG_FILE_MIDDLE_DELAY_RANGE_BASE	: REG_FILE_MIDDLE_DELAY_RANGE_END],
						 `currInstruction[NUM_OF_REPT_RANGE_BASE			: 			NUM_OF_REPT_RANGE_END],
						 `currInstruction[REP_STEP_VALUE_RANGE_BASE			:		 REP_STEP_VALUE_RANGE_END]); 
				iRefi3:
					instDetail = "REFI3"; 
				iSwb:
					instDetail =  $sformatf("srcRow: %0d, srcDpuOrRefi: %4s, HbIndex: %0d, VIndex: %0d, srcOutputNr: %0d, SendToOtherRow: %3s",
						 `currInstruction[SWB_SRC_ADDR_ROW_BASE		 :		SWB_SRC_ADDR_ROW_END],
						 (`currInstruction[SWB_SRC_DPU_REFI_BASE	 :		SWB_SRC_DPU_REFI_END] == 0 ? "REFI" : "DPU"),
						 `currInstruction[SWB_HB_INDEX_BASE			 :			SWB_HB_INDEX_END],
						 `currInstruction[SWB_V_INDEX_BASE 			 :			 SWB_V_INDEX_END],
						 `currInstruction[SWB_SRC_OUTPUT_NR_BASE 	 :	   SWB_SRC_OUTPUT_NR_END],										 
						 `currInstruction[SWB_SEND_TO_OTHER_ROW_BASE : SWB_SEND_TO_OTHER_ROW_END] == 0 ? "NO" : "YES"); 
				iWait:
					instDetail = $sformatf("delay cycles: %0d", `currInstruction[DLY_CYCLES_RANGE_BASE : DLY_CYCLES_RANGE_END]); 
				iBranch:
					instDetail = $sformatf("mode: %0d, falseAddr: %0d", 
						`currInstruction[BR_MODE_RANGE_BASE 	   : 		BR_MODE_RANGE_END],
						`currInstruction[BR_FALSE_ADDRS_RANGE_BASE : BR_FALSE_ADDRS_RANGE_END]);
				iJump:
					instDetail = $sformatf("Address: %0d", `currInstruction[TRUE_ADDRS_RANGE_BASE : TRUE_ADDRS_RANGE_END]);

				iRaccu:
					instDetail = $sformatf("Mode: %0d, Op1: %0d, Op2: %0d, ResAddress: %0d",
						`currInstruction[RACCU_MODE_SEL_RANGE_BASE 	  :    RACCU_MODE_SEL_RANGE_END],
						`currInstruction[RACCU_OPERAND1_RANGE_BASE 	  :    RACCU_OPERAND1_RANGE_END],
						`currInstruction[RACCU_OPERAND2_RANGE_BASE 	  :    RACCU_OPERAND2_RANGE_END],
						`currInstruction[RACCU_RESULT_ADDR_RANGE_BASE : RACCU_RESULT_ADDR_RANGE_END]);

				iLoop:
					instDetail = $sformatf("LoopId: %0d, IndexStart: %0d, IterationNo: %0d", 
						`currInstruction[FOR_INDEX_ADDR_RANGE_BASE 	 :  FOR_INDEX_ADDR_RANGE_END],
						`currInstruction[FOR_INDEX_START_RANGE_BASE  : FOR_INDEX_START_RANGE_END],
						`currInstruction[FOR_ITER_NO_RANGE_BASE 	 :     FOR_ITER_NO_RANGE_END]);

				default:
					instDetail = "";
			endcase

			sequencerActivities[row][col] = { sequencerActivities[row][col], 
				$sformatf("%5d\t%5d\t%8h\t%8s\t--->\t(%s)\n", executionCycle, `currSequencerData.pc,
						  `currInstruction, instructionCode.name(), instDetail) };

			oldpcs[row][col] = `currSequencerData.pc;
		end
	endfunction

	function automatic void printRegFileActivity(int fileid, row, col);
		if (regFileActivities[row][col].len() > 0)
		begin
			$fdisplay(fileid, "#----------------- RegFile <%0d,%0d> -----------------\n", row, col);
			$fdisplay(fileid, regFileActivities[row][col]);
		end
	endfunction

	function automatic void printSequencerActivity(int fileid, row, col);
		if (sequencerActivities[row][col].len() > 0)
		begin
			$fdisplay(fileid, "#----------------- Sequencer <%0d,%0d> -----------------", row, col);
			$fdisplay(fileid, "%5s\t%5s\t%8s\t%8s\t--->\t%s\n", "CYCLE", "PC", "INST_VAL", "INST_TYPE", "DETAILS");
			$fdisplay(fileid, sequencerActivities[row][col]);
		end
	endfunction

endpackage

`endif //_TEST_UTIL_
