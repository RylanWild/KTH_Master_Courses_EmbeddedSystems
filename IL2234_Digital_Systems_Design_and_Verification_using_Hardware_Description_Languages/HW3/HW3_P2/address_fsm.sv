`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/03 13:35:42
// Design Name: 
// Module Name: address_fsm
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


module address_fsm  #(parameter A=3, parameter B=4, parameter C=6,parameter D=2,parameter E=1,parameter ADDR_WIDTH=3)
(
    input logic clk,
    input logic rstn,
    input logic start,
    input logic I,//i<C I=1
    input logic J,//j<B, J=1
    output logic idle,
    output logic iplus,//i=i+1
    output logic jplus,//j=j+1
    output logic ireset,//i=0
    output logic jreset//j=0
    );
    
    enum logic [2:0] 
    {S0=3'b000,
    S1=3'b001,
    S2=3'b010,
    Quit=3'b011,
    Start=3'b100
    } state,next;
    //--------state register-----------------
    always_ff @(posedge clk or negedge rstn)
    begin
        if(!rstn) state<=Start;
        else state<=next;
    end
    
    //--------next state logic---------------
    always_comb
    begin
        next=Start;
   
        case(state)
        Start:
        begin
            if(start) next=S0;
            else next=Start;
        end
        
        S0: 
        begin    
            if(I) next=S1;
            else next=Quit;
        end
        
        S1:
        begin
            if(J) next=S1;
            else next=S2;
        end
        
        S2:
        begin
            next=S0;
        end
        
        Quit:
        begin
            next=Start;
        end 
        
        default:
        begin
            next=S0;
        end
        
        endcase
    end
    
    //-------------------output logic--------------------------
    always_comb 
    begin
        case(state)
        Start: idle=1;
        S0:    idle=0;
        S1:    idle=0;
        S2:    idle=0;
        Quit:  idle=1; 
        endcase
    end
    
    always_comb 
    begin
        case(state)
        Start:
        begin 
            iplus=0;
            jplus=0;
            ireset=1;
            jreset=1;
        end
        
        S0:    
        begin 
            iplus=0;
            jplus=0;
            ireset=0;
            jreset=0;
        end
        
        S1:     
        begin 
            iplus=0;
            jplus=1;
            ireset=0;
            jreset=0;
        end
        
        S2:     
        begin 
            iplus=1;
            jplus=0;
            ireset=0;
            jreset=1;
        end
        
        Quit:  
        begin 
            iplus=0;
            jplus=0;
            ireset=0;
            jreset=0;
        end
        
        endcase
    end
        
endmodule
