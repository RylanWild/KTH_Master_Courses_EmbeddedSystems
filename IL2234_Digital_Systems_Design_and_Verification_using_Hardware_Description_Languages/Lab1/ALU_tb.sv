//------------1.SET TIMESCALE---------------
`timescale 1ns/1ns
`define half_period 5
//------------2.DEFINE INPUT & OUTPUT---------------
module ALU_TB  #(parameter N = 8)();
 logic signed [N-1:0] A;
 logic signed [N-1:0] B;
 logic [2:0] OP;
 logic clk;
 logic signed [2:0] ONZ;
 logic signed [N-1:0] Result;
 logic signed [N:0] Result_Full;
 logic flag1;
 //------------3.MODELIZE SOURCE FILE---------------
ALU DUT (
 .A(A), .B(B), .OP(OP), .ONZ(ONZ),.Result(Result), .Result_Full(Result_Full),.flag1(flag1));
 //localparam period = 20;
 //------------4.SET INITIAL STIMULATION---------------
initial begin

	   OP =3'b000;
	   A ={N{1'b0}};//A is an N-bit binary number
	   B ={N{1'b0}};//B is an N-bit binary number
	repeat(20) begin //test 20 sets
	    #10 clk = 0;
	    
	    //generate random number
		
		#5 A = {$random};
		#0 B = {$random};
		//#0 OP= {$random}%8;
		#0 OP= OP+1;//from 000 to 111
		
		/*
		//制定一组数测试
		#5 A = 8'b01111111;
		#0 B = 8'b01000110;
		#0 OP = 101;
		*/
	end
	//#5 $finish;
end	
 always #`half_period clk = ~clk;//generate the clock

endmodule