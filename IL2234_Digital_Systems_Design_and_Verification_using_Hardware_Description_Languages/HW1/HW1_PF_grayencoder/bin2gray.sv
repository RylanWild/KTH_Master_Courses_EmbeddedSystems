`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/08 14:09:59
// Design Name: 
// Module Name: bin2gray
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


module bin2gray(
    input logic[3:0] binary,
    output logic [3:0] bcd
    );
    
    always_comb
     begin
      case(binary)
        4'b0000:bcd=4'b0000;
        4'b0001:bcd=4'b0001;
        4'b0010:bcd=4'b0011;
        4'b0011:bcd=4'b0010;
        4'b0100:bcd=4'b0110;
        4'b0101:bcd=4'b0111;
        4'b0110:bcd=4'b0101;
        4'b0111:bcd=4'b0100;
        4'b1000:bcd=4'b1100;
        4'b1001:bcd=4'b1101;
        4'b1010:bcd=4'b1111;
        4'b1011:bcd=4'b1110;
        4'b1100:bcd=4'b1010;
        4'b1101:bcd=4'b1011;
        4'b1110:bcd=4'b1001;
        4'b1111:bcd=4'b1000;
       endcase
      end
endmodule
