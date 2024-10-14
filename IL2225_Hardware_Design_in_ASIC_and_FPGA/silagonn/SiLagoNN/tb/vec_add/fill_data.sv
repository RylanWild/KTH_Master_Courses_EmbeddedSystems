
`include "macros.svh"
import name_mangling::*;
import test_util::*;

// A module declaration to fill the package data arrays with the corresponding FABRIC signals
module fill_data;
	generate
		for (genvar row = 0; row < ROWS; row++)
			for (genvar col = 0; col < COLUMNS; col++)
			begin
				if(row==0)
				begin
					if(col==0)
					begin
						assign `currRegData.dataIn0 		= `regFileData_top_l_corner(data_in_0);
						assign `currRegData.dataIn1 		= `regFileData_top_l_corner(data_in_1);
						assign `currRegData.dataOut0 		= `regFileData_top_l_corner(data_out_reg_0_left);
						assign `currRegData.dataOut1 		= `regFileData_top_l_corner(data_out_reg_1_left);
						assign `currRegData.addrIn0 		= `aguAddress_top_l_corner(Wr_0);
						assign `currRegData.addrIn1 		= `aguAddress_top_l_corner(Wr_1);
						assign `currRegData.addrOut0 		= `aguAddress_top_l_corner(Rd_0);
						assign `currRegData.addrOut1 		= `aguAddress_top_l_corner(Rd_1);
						assign `currRegData.addrenIn0 		= `aguAddressEn_top_l_corner(Wr_0);
						assign `currRegData.addrenIn1 		= `aguAddressEn_top_l_corner(Wr_1);
						assign `currRegData.addrenOut0		= `aguAddressEn_top_l_corner(Rd_0);
						assign `currRegData.addrenOut1		= `aguAddressEn_top_l_corner(Rd_1);
						assign `currRegData.instStartIn0	= `fabricRegTop_top_l_corner.AGU_Wr_0_instantiate.instr_start;
						assign `currSequencerData.pc 		= `fabricCell_top_l_corner.seq_gen.pc;
						assign `currSequencerData.currInst 	= `fabricCell_top_l_corner.seq_gen.instr;
					end
					else if(col==COLUMNS-1)
					begin
						assign `currRegData.dataIn0 		= `regFileData_top_r_corner(data_in_0);
						assign `currRegData.dataIn1 		= `regFileData_top_r_corner(data_in_1);
						assign `currRegData.dataOut0 		= `regFileData_top_r_corner(data_out_reg_0_left);
						assign `currRegData.dataOut1 		= `regFileData_top_r_corner(data_out_reg_1_left);
						assign `currRegData.addrIn0 		= `aguAddress_top_r_corner(Wr_0);
						assign `currRegData.addrIn1 		= `aguAddress_top_r_corner(Wr_1);
						assign `currRegData.addrOut0 		= `aguAddress_top_r_corner(Rd_0);
						assign `currRegData.addrOut1 		= `aguAddress_top_r_corner(Rd_1);
						assign `currRegData.addrenIn0 		= `aguAddressEn_top_r_corner(Wr_0);
						assign `currRegData.addrenIn1 		= `aguAddressEn_top_r_corner(Wr_1);
						assign `currRegData.addrenOut0		= `aguAddressEn_top_r_corner(Rd_0);
						assign `currRegData.addrenOut1		= `aguAddressEn_top_r_corner(Rd_1);
						assign `currRegData.instStartIn0	= `fabricRegTop_top_r_corner.AGU_Wr_0_instantiate.instr_start;
						assign `currSequencerData.pc 		= `fabricCell_top_r_corner.seq_gen.pc;
						assign `currSequencerData.currInst 	= `fabricCell_top_r_corner.seq_gen.instr;
					end
					else
					begin
						assign `currRegData.dataIn0 		= `regFileData_top(data_in_0);
						assign `currRegData.dataIn1 		= `regFileData_top(data_in_1);
						assign `currRegData.dataOut0 		= `regFileData_top(data_out_reg_0_left);
						assign `currRegData.dataOut1 		= `regFileData_top(data_out_reg_1_left);
						assign `currRegData.addrIn0 		= `aguAddress_top(Wr_0);
						assign `currRegData.addrIn1 		= `aguAddress_top(Wr_1);
						assign `currRegData.addrOut0 		= `aguAddress_top(Rd_0);
						assign `currRegData.addrOut1 		= `aguAddress_top(Rd_1);
						assign `currRegData.addrenIn0 		= `aguAddressEn_top(Wr_0);
						assign `currRegData.addrenIn1 		= `aguAddressEn_top(Wr_1);
						assign `currRegData.addrenOut0		= `aguAddressEn_top(Rd_0);
						assign `currRegData.addrenOut1		= `aguAddressEn_top(Rd_1);
						assign `currRegData.instStartIn0	= `fabricRegTop_top.AGU_Wr_0_instantiate.instr_start;
						assign `currSequencerData.pc 		= `fabricCell_top.seq_gen.pc;
						assign `currSequencerData.currInst 	= `fabricCell_top.seq_gen.instr;
					end
				end
				else
				begin
					if(col==0)
					begin
						assign `currRegData.dataIn0 		= `regFileData_bot_l_corner(data_in_0);
						assign `currRegData.dataIn1 		= `regFileData_bot_l_corner(data_in_1);
						assign `currRegData.dataOut0 		= `regFileData_bot_l_corner(data_out_reg_0_left);
						assign `currRegData.dataOut1 		= `regFileData_bot_l_corner(data_out_reg_1_left);
						assign `currRegData.addrIn0 		= `aguAddress_bot_l_corner(Wr_0);
						assign `currRegData.addrIn1 		= `aguAddress_bot_l_corner(Wr_1);
						assign `currRegData.addrOut0 		= `aguAddress_bot_l_corner(Rd_0);
						assign `currRegData.addrOut1 		= `aguAddress_bot_l_corner(Rd_1);
						assign `currRegData.addrenIn0 		= `aguAddressEn_bot_l_corner(Wr_0);
						assign `currRegData.addrenIn1 		= `aguAddressEn_bot_l_corner(Wr_1);
						assign `currRegData.addrenOut0		= `aguAddressEn_bot_l_corner(Rd_0);
						assign `currRegData.addrenOut1		= `aguAddressEn_bot_l_corner(Rd_1);
						assign `currRegData.instStartIn0	= `fabricRegTop_bot_l_corner.AGU_Wr_0_instantiate.instr_start;
						assign `currSequencerData.pc 		= `fabricCell_bot_l_corner.seq_gen.pc;
						assign `currSequencerData.currInst 	= `fabricCell_bot_l_corner.seq_gen.instr;
					end
					else if(col==COLUMNS-1)
					begin
						assign `currRegData.dataIn0 		= `regFileData_bot_r_corner(data_in_0);
						assign `currRegData.dataIn1 		= `regFileData_bot_r_corner(data_in_1);
						assign `currRegData.dataOut0 		= `regFileData_bot_r_corner(data_out_reg_0_left);
						assign `currRegData.dataOut1 		= `regFileData_bot_r_corner(data_out_reg_1_left);
						assign `currRegData.addrIn0 		= `aguAddress_bot_r_corner(Wr_0);
						assign `currRegData.addrIn1 		= `aguAddress_bot_r_corner(Wr_1);
						assign `currRegData.addrOut0 		= `aguAddress_bot_r_corner(Rd_0);
						assign `currRegData.addrOut1 		= `aguAddress_bot_r_corner(Rd_1);
						assign `currRegData.addrenIn0 		= `aguAddressEn_bot_r_corner(Wr_0);
						assign `currRegData.addrenIn1 		= `aguAddressEn_bot_r_corner(Wr_1);
						assign `currRegData.addrenOut0		= `aguAddressEn_bot_r_corner(Rd_0);
						assign `currRegData.addrenOut1		= `aguAddressEn_bot_r_corner(Rd_1);
						assign `currRegData.instStartIn0	= `fabricRegTop_bot_r_corner.AGU_Wr_0_instantiate.instr_start;
						assign `currSequencerData.pc 		= `fabricCell_bot_r_corner.seq_gen.pc;
						assign `currSequencerData.currInst 	= `fabricCell_bot_r_corner.seq_gen.instr;
					end
					else
					begin
						assign `currRegData.dataIn0 		= `regFileData_bot(data_in_0);
						assign `currRegData.dataIn1 		= `regFileData_bot(data_in_1);
						assign `currRegData.dataOut0 		= `regFileData_bot(data_out_reg_0_left);
						assign `currRegData.dataOut1 		= `regFileData_bot(data_out_reg_1_left);
						assign `currRegData.addrIn0 		= `aguAddress_bot(Wr_0);
						assign `currRegData.addrIn1 		= `aguAddress_bot(Wr_1);
						assign `currRegData.addrOut0 		= `aguAddress_bot(Rd_0);
						assign `currRegData.addrOut1 		= `aguAddress_bot(Rd_1);
						assign `currRegData.addrenIn0 		= `aguAddressEn_bot(Wr_0);
						assign `currRegData.addrenIn1 		= `aguAddressEn_bot(Wr_1);
						assign `currRegData.addrenOut0		= `aguAddressEn_bot(Rd_0);
						assign `currRegData.addrenOut1		= `aguAddressEn_bot(Rd_1);
						assign `currRegData.instStartIn0	= `fabricRegTop_bot.AGU_Wr_0_instantiate.instr_start;
						assign `currSequencerData.pc 		= `fabricCell_bot.seq_gen.pc;
						assign `currSequencerData.currInst 	= `fabricCell_bot.seq_gen.instr;
					end
				end
			end
	endgenerate

	generate
		for (genvar row = 0; row < ROWS-1; row++)
			for (genvar col = 0; col < COLUMNS; col++)
			begin
				if(row==0)
				begin
					if (col==0)
					begin
						assign `currSramData.readEn 		= `stile_bot_l_corner.SRAM_rw_r;
						assign `currSramData.writeEn		= `stile_bot_l_corner.SRAM_rw_w;
						assign `currSramData.writeAddress 	= `stile_bot_l_corner.SRAM_rw_addrs_out_w;
						assign `currSramData.data 			= `stile_bot_l_corner.memory_out;
					end
					else if(col == COLUMNS-1)
					begin
						assign `currSramData.readEn 		= `stile_bot_r_corner.SRAM_rw_r;
						assign `currSramData.writeEn		= `stile_bot_r_corner.SRAM_rw_w;
						assign `currSramData.writeAddress 	= `stile_bot_r_corner.SRAM_rw_addrs_out_w;
						assign `currSramData.data 			= `stile_bot_r_corner.memory_out;
					end
					else
					begin
						assign `currSramData.readEn 		= `stile_bot.SRAM_rw_r;
						assign `currSramData.writeEn		= `stile_bot.SRAM_rw_w;
						assign `currSramData.writeAddress 	= `stile_bot.SRAM_rw_addrs_out_w;
						assign `currSramData.data 			= `stile_bot.memory_out;
					end
				end
				else
				begin
					assign `currSramData.readEn 		= `stile.SRAM_rw_r;
					assign `currSramData.writeEn		= `stile.SRAM_rw_w;
					assign `currSramData.writeAddress 	= `stile.SRAM_rw_addrs_out_w;
					assign `currSramData.data 			= `stile.memory_out;
				end
			end
	endgenerate

	initial
		for (int row = 0; row < ROWS; row++)
			for (int col = 0; col < COLUMNS; col++)
				oldpcs[row][col] = -1;
endmodule
