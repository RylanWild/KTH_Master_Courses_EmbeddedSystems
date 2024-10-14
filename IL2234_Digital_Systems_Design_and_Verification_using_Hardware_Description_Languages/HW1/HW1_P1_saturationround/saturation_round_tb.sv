`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/11 01:55:01
// Design Name: 
// Module Name: saturation_round_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module saturation_round_tb( );
    logic [15:0] in;
    logic up_down;
    logic [7:0] out;
    reg in_dec_int;
    reg in_dec_frac;
    reg out_dec_int;
    reg out_dec_frac;
    
    saturation_round DUT(.in(in), .up_down(up_down), .out(out));
     
     initial begin
      in=16'b0000_0000_0000_0000;
      up_down=1'b0;
      
      for(int i=0;i<15;i++)
        begin
            in=$random;
            //in=16'b1100110100001101;
            up_down=up_down+1;
            //up_down=0;
            #5;
        end
       end 
endmodule

