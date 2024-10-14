//-------------- Copyright (c) notice -----------------------------------------
//
// The SV code, the logic and concepts described in this file constitute
// the intellectual property of the authors listed below, who are affiliated
// to KTH (Kungliga Tekniska Högskolan), School of EECS, Kista.
// Any unauthorised use, copy or distribution is strictly prohibited.
// Any authorised use, copy or distribution should carry this copyright notice
// unaltered.
//-----------------------------------------------------------------------------
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
//                                                                         #
//This file is part of IL1332 and IL2234 course.                           #
//                                                                         #
//    The source code is distributed freely: you can                       #
//    redistribute it and/or modify it under the terms of the GNU          #
//    General Public License as published by the Free Software Foundation, #
//    either version 3 of the License, or (at your option) any             #
//    later version.                                                       #
//                                                                         #
//    It is distributed in the hope that it will be useful,                #
//    but WITHOUT ANY WARRANTY; without even the implied warranty of       #
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
//    GNU General Public License for more details.                         #
//                                                                         #
//    See <https://www.gnu.org/licenses/>.                                 #
//                                                                         #
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
module ROM #(parameter N=8,ROM_addressBits = 6, RF_addressBits = 3) (
  input  logic                          clk           ,
  input  logic                          ROM_readEnable,
  input  logic [   ROM_addressBits-1:0] ROM_address   ,
  output logic [4+2*RF_addressBits:0] ROM_data
);

  logic [4+2*RF_addressBits:0] ROM_memory[(2**ROM_addressBits)-1:0];
  initial begin
    ROM_memory = '{default:0};
    $display("Loading rom.");
    // Make sure that the microcode.mem file is in the same folder as your project
    $readmemb("microcode.mem", ROM_memory);
  end

  always @(posedge clk) begin
    if(ROM_readEnable == 1) begin
        ROM_data <= ROM_memory[ROM_address];
    end
  end

endmodule