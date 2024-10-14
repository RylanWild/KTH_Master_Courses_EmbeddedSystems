`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/15 12:28:16
// Design Name: 
// Module Name: twodevice_tb
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


module twodevice_tb();
logic clk;
logic active;
logic ready;
wire [2:0] data;

logic check_deassert;

//twodevice DUT (clk,active,ready,data);
/*
initial begin
active=1'b0;
#5;
    for(int i=0;i<20;i++)
    begin
        active=$random;
        #10;
    end
end
*/
initial begin
clk=1'b1;
#5;
end
always #5 clk=~clk;



////////////////directed test///////////////////////
initial begin
active=0;
ready=0;
#10
active=1;
#60
active=0;
#10
ready=1;

end
////////////////Assertions//////////////////////////

    //1.when active signal or ready signal are 0,data should be high-z 
always @(posedge clk) begin
assert ((active&ready)||($isunknown(data)==1)) else $error("Violate Rule 1");
end


    //2.if the active signal becomes 1 for 5 cycles without ready become 1,active should be 0 by the 6th cycle
    sequence active_for_5_cycles;
    active ##5 (!ready);
    endsequence
    
    property p2;
    @(posedge clk) active_for_5_cycles |->(active==0);
    endproperty

    a2: assert property(p2) 
    else $error("Violate Rule 2");
        
    //3.ready signal should never become 1 if active is 0
   always @(posedge clk) begin
    assert (active||!ready) 
    else $error("Violate Rule 3");
   end
   
    //4. when active becomes 0, ready should become 0 exactly in the next cycle
     property p4;
    @(posedge clk) !active |->##1 !ready;
    endproperty
    
    a4: assert property(p4)
    else $error("Violate Rule 4");
        

endmodule
