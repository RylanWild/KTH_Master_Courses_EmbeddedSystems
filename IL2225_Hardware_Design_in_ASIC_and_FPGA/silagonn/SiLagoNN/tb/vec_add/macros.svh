
`ifndef _MACROS_
`define _MACROS_

// Some macro definitions for simpler access
`define fabricCell_bot_l_corner				DUT.MTRF_COLS[col].MTRF_ROWS[row].if_drra_bot_l_corner.Silago_bot_l_corner_inst.SILEGO_cell.MTRF_cell
`define fabricCell_bot_r_corner				DUT.MTRF_COLS[col].MTRF_ROWS[row].if_drra_bot_r_corner.Silago_bot_r_corner_inst.SILEGO_cell.MTRF_cell
`define fabricCell_bot								DUT.MTRF_COLS[col].MTRF_ROWS[row].if_drra_bot.Silago_bot_inst.SILEGO_cell.MTRF_cell
`define fabricCell_top_l_corner				DUT.MTRF_COLS[col].MTRF_ROWS[row].if_drra_top_l_corner.Silago_top_l_corner_inst.SILEGO_cell.MTRF_cell
`define fabricCell_top_r_corner				DUT.MTRF_COLS[col].MTRF_ROWS[row].if_drra_top_r_corner.Silago_top_r_corner_inst.SILEGO_cell.MTRF_cell
`define fabricCell_top								DUT.MTRF_COLS[col].MTRF_ROWS[row].if_drra_top.Silago_top_inst.SILEGO_cell.MTRF_cell

`define fabricRegTop_bot_l_corner 		`fabricCell_bot_l_corner.reg_top
`define fabricRegTop_bot_r_corner 		`fabricCell_bot_r_corner.reg_top
`define fabricRegTop_bot							`fabricCell_bot.reg_top
`define fabricRegTop_top_l_corner 		`fabricCell_top_l_corner.reg_top
`define fabricRegTop_top_r_corner			`fabricCell_top_r_corner.reg_top
`define fabricRegTop_top							`fabricCell_top.reg_top

`define aguAddressEn_bot_l_corner(port)	`fabricRegTop_bot_l_corner.AGU_``port``_instantiate.addr_en
`define aguAddressEn_bot_r_corner(port)	`fabricRegTop_bot_r_corner.AGU_``port``_instantiate.addr_en
`define aguAddressEn_bot(port)					`fabricRegTop_bot.AGU_``port``_instantiate.addr_en
`define aguAddressEn_top_l_corner(port)	`fabricRegTop_top_l_corner.AGU_``port``_instantiate.addr_en
`define aguAddressEn_top_r_corner(port)	`fabricRegTop_top_r_corner.AGU_``port``_instantiate.addr_en
`define aguAddressEn_top(port)					`fabricRegTop_top.AGU_``port``_instantiate.addr_en

`define aguAddress_bot_l_corner(port)	`fabricRegTop_bot_l_corner.AGU_``port``_instantiate.addr_out
`define aguAddress_bot_r_corner(port)	`fabricRegTop_bot_r_corner.AGU_``port``_instantiate.addr_out
`define aguAddress_bot(port)					`fabricRegTop_bot.AGU_``port``_instantiate.addr_out
`define aguAddress_top_l_corner(port)	`fabricRegTop_top_l_corner.AGU_``port``_instantiate.addr_out
`define aguAddress_top_r_corner(port)	`fabricRegTop_top_r_corner.AGU_``port``_instantiate.addr_out
`define aguAddress_top(port)					`fabricRegTop_top.AGU_``port``_instantiate.addr_out

`define regFileData_bot_l_corner(port)	`fabricRegTop_bot_l_corner.RegisterFile.``port
`define regFileData_bot_r_corner(port)	`fabricRegTop_bot_r_corner.RegisterFile.``port
`define regFileData_bot(port)						`fabricRegTop_bot.RegisterFile.``port
`define regFileData_top_l_corner(port)	`fabricRegTop_top_l_corner.RegisterFile.``port
`define regFileData_top_r_corner(port)	`fabricRegTop_top_r_corner.RegisterFile.``port
`define regFileData_top(port)						`fabricRegTop_top.RegisterFile.``port

`define dimarchDataIn_bot_l_corner			`fabricRegTop_bot_l_corner.dimarch_data_in
`define dimarchDataIn_bot_r_corner			`fabricRegTop_bot_r_corner.dimarch_data_in
`define dimarchDataIn_bot								`fabricRegTop_bot.dimarch_data_in
`define dimarchDataIn_top_l_corner			`fabricRegTop_top_l_corner.dimarch_data_in
`define dimarchDataIn_top_r_corner			`fabricRegTop_top_r_corner.dimarch_data_in
`define dimarchDataIn_top								`fabricRegTop_top.dimarch_data_in

`define currRegVariable		regFileVariables[row][col][address]
`define currRegData 		regData[row][col]
`define currSequencerData	sequencerData[row][col]
`define currInstruction		`currSequencerData.currInst
`define currFixedPointStatus regFileFixedPointStatus[row][col][address]

`define stile_bot_l_corner				DUT.DiMArch_COLS[col].DiMArch_ROWS[row].if_dimarch_bot_l_corner.DiMArchTile_bot_l_inst.u_STILE
`define stile_bot_r_corner				DUT.DiMArch_COLS[col].DiMArch_ROWS[row].if_dimarch_bot_r_corner.DiMArchTile_bot_r_inst.u_STILE
`define stile_bot									DUT.DiMArch_COLS[col].DiMArch_ROWS[row].if_dimarch_bot.DiMArchTile_bot_inst.u_STILE
`define stile											DUT.DiMArch_COLS[col].DiMArch_ROWS[row].if_dimarch.DiMArchTile_inst.u_STILE

`define currSramData		sramData[0][col]

`endif //_MACROS_ 
