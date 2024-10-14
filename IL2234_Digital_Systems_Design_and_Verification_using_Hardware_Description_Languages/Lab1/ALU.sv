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


//N=1-32
module ALU  #(parameter N = 8 ) (
    input logic [2:0] OP, 
    input logic signed [N-1:0] A, 
    input logic signed [N-1:0] B, 
    input clk,
    
    /* --------------------------------- Outputs -------------------------------- */
    output logic  [2:0] ONZ,
    output logic signed [N-1:0] Result,
    output logic signed [N:0] Result_Full,
    output logic flag1
);
  // Add your ALU description here
  always_comb//combination circuit,doesn't need a clock
   begin
        case(OP)
              //signed add
               3'b000:
               begin
               Result_Full=A+B;
               Result=A+B;
               
               end
               
               //signed subtract
               3'b001:
               begin
               Result_Full=A-B;
               Result=A-B;
               end 
               
               3'b010:Result=A&B;  
               3'b011:Result=A|B;
               3'b100:Result=A^B;
               3'b101:Result=A+1;
               3'b110:Result=A;
               3'b111:Result=B;
               default:Result=8'b00000000;
       endcase
               //O
               if((OP==3'b000|OP==3'b001)&Result[N-1]!=Result_Full[N])
                   ONZ[2]=1;//wrong sign bit
                 else
                   ONZ[2]=0;//right sign bit
               //N
               if(Result[N-1]==1)
                   ONZ[1]=1;
                 else
                   ONZ[1]=0;
                   
                //Z
                if(Result=={N{1'b0}})
                   ONZ[0]=1;
                 else
                   ONZ[0]=0;

            //-------------flag1-------------------
            case(OP)
              //signed add
               3'b000:
               begin
                if(ONZ[2]==0)//right sigh bit
                    flag1=1;
                else
                    flag1=0;
               end
               
               //signed subtract
               3'b001:
               begin
               if(ONZ[2]==0)//right sigh bit
                    flag1=1;
                else
                    flag1=0;  
               end 
               
               //A AND B
               3'b010:
               begin
                  for(int i=0;i<N;i++)
                    begin
                        if(Result[i]==(A[i]&B[i]))
                            begin
                            flag1=1;
                            end
                        flag1=flag1&flag1;
                    end
               end
               // A OR B    
               3'b011:
               begin
                  for(int i=0;i<N;i++)
                    begin
                        if(Result[i]==(A[i]|B[i]))
                            begin
                            flag1=1;
                            end
                        flag1=flag1&flag1;
                    end
               end
               //A XOR B
               3'b100:
               begin
               for(int i=0;i<N;i++)
                    begin
                        if(Result[i]==(A[i]^B[i]))
                            begin
                            flag1=1;
                            end
                        flag1=flag1&flag1;
                    end
               end
               // A+1
               3'b101:
                begin
                    Result_Full=A+1;//when A = 8'b01111111, overflow
                    if(Result==Result_Full)
                        flag1=1;
                     else
                        flag1=0;   
                end
               //A
               3'b110:flag1=1;
               //B
               3'b111:flag1=1;
               
               default:Result=8'b00000000;
       endcase
            
          
   end  
   
   
endmodule