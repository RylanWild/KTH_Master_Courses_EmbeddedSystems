`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/02 16:34:23
// Design Name: 
// Module Name: main
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


module main(
 input logic clk,
 input logic rstn,
 input logic in,
 output logic detected
    );
    parameter logic [2:0] S0=3'b000,
    S1=3'b001,
    S2=3'b010,
    S3=3'b011,
    S4=3'b100;
    logic [2:0] state,next;
    // //-------------------------state register---------------------------
    always_ff @(posedge clk or negedge rstn)
    begin
        if(!rstn) state<=S0;
        else state<=next;
    end
    //-------------------------next state logic---------------------------
    always_comb 
    begin
        next=S0;
        case (state)
        S0:
        begin
            if (in) next=S1;
            else next=S0;
        end
         
         S1:
         begin
            if (in) next=S2;
            else next=S0;
         end
        
         S2:
         begin
            if (in) next=S3;
            else next=S0;
         end
         
         S3:
         begin
            if (in) next=S4;
            else next=S0;
         end
         
         S4:
         begin
            if (in) next=S4;
            else next=S0;
         end
         
         default: next=S0;
         
       endcase
    end
     //-------------------------output logic---------------------------
    /*always_comb 
    begin
        detected=1'b0;
        case(state)
            S0: detected=1'b0;
            S1: detected=1'b0;
            S2: detected=1'b0;
            S3: detected=1'b0;
            S4:
            begin
            if(next==S4)
             detected=1'b1;
             else
             detected=1'b0;
            end
            default:
            detected=1'b0;
        endcase
    end
    */
    always_ff @(posedge clk or negedge rstn)
    if(!rstn)
        detected <= 0;
    else if(state == S4 && in)
        detected <= 1;
    else
        detected <= 0;

endmodule
