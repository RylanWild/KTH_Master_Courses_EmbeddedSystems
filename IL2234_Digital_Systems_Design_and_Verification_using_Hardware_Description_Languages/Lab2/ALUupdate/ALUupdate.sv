
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/07 22:31:16
// Design Name: 
// Module Name: ALU
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

module ALUupdate  #(parameter N = 8 ) (
    input logic [2:0] OP, 
    input logic signed [N-1:0] Port_A, 
    input logic signed [N-1:0] Port_B, 
    input logic clk,
    input logic rst,
    input logic rst_n,
    input logic enable,
    /* --------------------------------- Outputs -------------------------------- */
    
    output logic  [2:0] ONZ,
    output logic signed [N-1:0] Result
    );
  // Add your ALU description here
logic signed [N-1:0] Result_tmp;
logic signed [N:0] Result_Full;
logic signed [N:0] Result_Full_tmp;
logic  [2:0] ONZ_tmp1;
logic  [2:0] ONZ_tmp2;
logic  [2:0] ONZ_tmp;



//Asynchronous Reset
always_ff @(posedge clk, negedge rst_n) 
begin
        if (!rst_n)        
            begin
            ONZ_tmp1<=3'b0;
            Result<=0;
            Result_Full<=0;
            end
        else 
            begin
            ONZ_tmp1<=ONZ_tmp;
            Result<=Result_tmp;
            Result_Full<=Result_Full_tmp;
            end
end

//synchronous Reset

always_ff @(posedge clk) 
begin
    if(enable)
        begin
            if (rst==0)        
            begin
            ONZ_tmp2<=ONZ_tmp;
            end
            else if (rst==1)
            begin
            ONZ_tmp2<=3'b0;
            end
        end
     else
     ONZ_tmp2<=3'b0;
 end
 
   always_comb
   begin
   ONZ=ONZ_tmp1&ONZ_tmp2;
   end
   
   always_comb
   begin
        case(OP)
              //signed add
               3'b000:
               begin
               Result_Full_tmp=Port_A+Port_B;
               Result_tmp=Port_A+Port_B;
               end
               
               //signed subtract
               3'b001:
               begin
               Result_Full_tmp=Port_A-Port_B;
               Result_tmp=Port_A-Port_B;
               end 
               
               3'b010:Result_tmp=Port_A&Port_B;  
               3'b011:Result_tmp=Port_A|Port_B;
               3'b100:Result_tmp=Port_A^Port_B;
               3'b101:Result_tmp=Port_A+1;
               3'b110:Result_tmp=Port_A;
               3'b111:Result_tmp=Port_B;
               default:Result_tmp=8'b00000000;
       endcase
               //O
               if((OP==3'b000|OP==3'b001)&Result_tmp[N-1]!=Result_Full_tmp[N])
                   ONZ_tmp[2]=1;//wrong sign bit
                 else
                   ONZ_tmp[2]=0;//right sign bit
               //N
               if(Result_tmp[N-1]==1)
                   ONZ_tmp[1]=1;
                 else
                   ONZ_tmp[1]=0;
                   
                //Z
                if(Result_tmp=={N{1'b0}})
                   ONZ_tmp[0]=1;
                 else
                   ONZ_tmp[0]=0;

        
   end  
   
   
endmodule