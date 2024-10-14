
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

module ALU  #(parameter N = 8 ) (
    input logic clk,
    input logic rst_n,
    input logic s_rst,//from FSM
    input logic [2:0] OP, //from FSM
    input logic signed [N-1:0] A, //from RF
    input logic signed [N-1:0] B, //from RF
    input logic enable,//always 1
    /* --------------------------------- Outputs -------------------------------- */
    
    output logic  [2:0] ONZ,//to FSM
    output logic signed [N-1:0] Y//to RF
    );
  // Add your ALU description here
logic signed [N-1:0] Result_tmp;
logic signed [N:0] Result_Full;
logic signed [N:0] Result_Full_tmp;
logic  [2:0] ONZ_tmp1;
logic  [2:0] ONZ_tmp2;
logic  [2:0] ONZ_tmp;

//Asynchronous Reset
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ONZ<=0;
    end else if(s_rst) begin
        ONZ<=0;
    end else if(enable) begin
        ONZ<=ONZ_tmp;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Y<=0;
    end else begin
        Y<=Result_tmp;
    end    
end
//synchronous Reset

   
   always_comb
   begin
        case(OP)
              //signed add
               3'b000:
               begin
               Result_Full_tmp=A+B;
               Result_tmp=A+B;
               end
               
               //signed subtract
               3'b001:
               begin
               Result_Full_tmp=A-B;
               Result_tmp=A-B;
               end 
               
               3'b010:Result_tmp=A&B;  
               3'b011:Result_tmp=A|B;
               3'b100:Result_tmp=A^B;
               3'b101:Result_tmp=A+1;
               3'b110:Result_tmp=A;
               3'b111:Result_tmp=B;
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
