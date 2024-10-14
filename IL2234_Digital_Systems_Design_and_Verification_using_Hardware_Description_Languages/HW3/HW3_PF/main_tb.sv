`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/02 17:18:12
// Design Name: 
// Module Name: main_tb
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


module main_tb( );
 logic clk;
 logic rstn;
 logic in;
 logic detected;
    
    main DUT (clk,rstn,in,detected);
    
    initial 
    begin
        clk=1'b0;
        rstn=1'b1;
        in=1'b0;  
    end
    
    always #5 clk=~clk;
    
    initial
    begin
    #10;//10ns
    in=1'b1;//1
    #10;//20ns
    in=1'b1;//11
    #10;//30ns
    in=1'b1;//111
    #10;//40ns
    in=1'b1;//1111
    #10;//50ns
    in=1'b1;//11111
    #10;//60ns
    in=1'b1;//111111
    #10;//70ns
    in=1'b0;//1111110
    #10;//80ns
    in=1'b1;//11111101
    #10;//90ns
    in=1'b1;//111111011
    #10;//100ns
    in=1'b1;//1111110111
    #10;//110ns
    in=1'b1;//11111101111
    #10;//120ns
    in=1'b1;//11111101111
    #10;//130ns
    in=1'b1;//111111011111
    #10;//140ns
    in=1'b1;//1111110111111
    rstn=1'b0;
    
    end
        
endmodule
