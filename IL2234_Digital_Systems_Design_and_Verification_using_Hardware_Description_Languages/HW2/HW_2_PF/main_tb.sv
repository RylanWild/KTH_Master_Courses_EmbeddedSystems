`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/25 01:40:49
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


module main_tb();
    logic clk;
    logic rst_n;
    logic select;
    logic in;
    logic D;
    logic out;
    logic [5:0]Q;
    
    main DUT(clk,rst_n,select,in,D,out,Q);
    
    initial 
        begin
            rst_n=0;
            clk=0;
            select=0;//shift
            #5//begin at 5ns
            rst_n=1;   
            #100
            rst_n=0;//reset to Q=6'b000000 at 105ns
            #5
            rst_n=1;
            #100
            select=1;//rotate
            
        end
     
     always #5 clk=~clk;
     
     initial begin
        in=0;
        #10 in=0; //00
        #10 in=1; //001
        #10 in=1; //0011
        #10 in=0; //00110
        #10 in=0;
        #10 in=1;
        #10 in=1;
        #10 in=0;
        #10 in=1;
        //reset after 10 sets(105ns)
        #10 in=0; 
        #10 in=1; 
        #10 in=1; 
        #10 in=0; 
        #10 in=0;
        #10 in=1;
        #10 in=1;
        #10 in=0;
        #10 in=1;
        //rotate after 215ns
        //#10 $finish;
  end

endmodule
