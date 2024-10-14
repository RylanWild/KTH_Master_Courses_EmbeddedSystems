
//------------1.SET TIMESCALE---------------
`timescale 1ns/1ns
//------------2.DEFINE INPUT & OUTPUT---------------
module ALUupdate_tb  #(parameter N = 8)();
    logic [2:0] OP;
    logic signed [N-1:0] Port_A;
    logic signed [N-1:0] Port_B;
    logic clk;
    logic rst;
    logic rst_n;
    logic enable;
    /* --------------------------------- Outputs -------------------------------- */
    logic  [2:0] ONZ;
    logic signed [N-1:0] Result; 
    
    logic [2:0] ONZ_tmp1;
    logic [2:0] ONZ_tmp2;
    logic signed [N:0] Result_Full;
    logic [2:0] ONZ_tmp;
    logic signed [N-1:0] Result_tmp;
    logic signed [N:0] Result_Full_tmp;


ALUupdate DUT (   
            OP, 
            Port_A, 
            Port_B, 
            clk,
            rst,
            rst_n,
            enable,
    /* --------------------------------- Outputs -------------------------------- */
            ONZ,
            Result
            );

 initial 
    begin
        clk=1'b0;
    end
    
always #5  clk = ~clk;//generate the clock

initial
begin
    rst=1'b0;
    rst_n=1'b1;
    enable=1'b1;
#10;

    rst=1'b1;
    rst_n=1'b1;
    enable=1'b1;
#20;

    rst=1'b0;
    rst_n=1'b1;
    enable=1'b1;
#20;

    rst=1'b0;
    rst_n=1'b0;
    enable=1'b1;
#20;

    rst=1'b0;
    rst_n=1'b1;
    enable=1'b1;
#10;

    rst=1'b0;
    rst_n=1'b1;
    enable=1'b0;
#20;

    rst=1'b1;
    rst_n=1'b1;
    enable=1'b1;
#20;

    rst=1'b0;
    rst_n=1'b1;
    enable=1'b1;
#20;

end
 
 initial
 begin
 for(int i=0;i<35;i++)
    begin
    Port_A=$random;
    Port_B=$random;
    #10;
    end
 end
 
 initial
 begin
    OP=3'b000;
    #10;
    for(int i=0;i<35;i++)
        begin
        OP=OP+1;
        #10;
    end
    $finish;
 end


endmodule