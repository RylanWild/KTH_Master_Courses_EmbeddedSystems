`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/02 18:28:03
// Design Name: 
// Module Name: lock
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


module lock(
    input logic clk,
    input logic rstn,
    input logic [3:0]key,//4'ha表示4位十六进制数字a(二进制1010)
    output logic valid_key,
    output logic state_out
    );
    
    logic [3:0] pass1;
    logic [3:0] pass2;
    logic [3:0] pass3;
    logic [3:0] pass4;
   
    logic [3:0] state,next;
    
    parameter logic[3:0] 
    S0=4'b0000,
    S1=4'b0001,
    t1=4'b0010,
    t2=4'b0011,
    t3=4'b0100,
    t4=4'b0101,
    C1=4'b0110,
    C2=4'b0111,
    C3=4'b1000,
    C4=4'b1001,
    Start=4'b1010;
    
    //---------------state register--------------------
    always_ff @(posedge clk or negedge rstn)
    begin
        if(!rstn) state<=Start;
        else 
        begin
        state<=next;  
        end
    end
  
   always_ff @(posedge key[0],posedge key[1],posedge key[2],posedge key[3],posedge clk,negedge key[0],negedge key[1],negedge key[2],negedge key[3])
   begin
        if(clk)
        valid_key=1'b0;
        else
        valid_key=1'b1;
   end
    //--------------next state logic-----------------
   
   
    always_comb
    begin
        next=Start;
       
        case(state)
            Start://reset password
            begin
            pass1=4'h1;
            pass2=4'h2;
            pass3=4'h3;
            pass4=4'h4;
            next=S0;
            end
            
            S0:
            begin   
                if(key==4'hB) next=S1;
                else if(key==4'hA)  next=C1;
                else next=S0; 
            end
            
            S1:
            begin 
                if(key==pass1) next=t1;
                else  next=S1;
            end
            
            t1:
            begin 
           
                if(key==pass2)  next=t2; 
                else  next=S1; 
            end
            
            t2:
            begin
                if(key==pass3) next=t3; 
                else  next=S1; 
            end
            
            t3:
            begin
                if(key==pass4)  next=t4;
                else  next=S1; 
            end
            
            t4:
            begin
                if(key==4'hC)  next=S0;
                else  next=S1; 
            end
            
            C1:
            begin
                pass1=key;
                next=C2;
            end
            
            C2:
            begin
                pass2=key;
                next=C3;
            end
            
            C3:
            begin
                pass3=key;
                next=C4;
            end
            
            C4:
            begin
                pass4=key;
                next=S0;
            end
            
            default: next=S0;
         endcase
    end
    
    //-------------------output logic--------------------
    always_comb 
    begin
       case(state)
       S0:state_out=1'b0;
       S1:state_out=1'b1;
       t1:state_out=1'b1;
       t2:state_out=1'b1;
       t3:state_out=1'b1;
       t4:state_out=1'b1;
       C1:state_out=1'b0;
       C2:state_out=1'b0;
       C3:state_out=1'b0;
       C4:state_out=1'b0;
       endcase
    end
    
endmodule
