`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/07 23:58:39
// Design Name: 
// Module Name: RF
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



module RF  #(parameter N = 8, parameter addressBits = 2) ( 
    /* --------------------------------- Inputs --------------------------------- */
    input logic clk,
    input logic rst_n,
    input logic selectDestinationA,
    input logic selectDestinationB,
    
    input logic [1:0] selectSource,
    input logic [addressBits-1:0] writeAddress,
    input logic write_en,
    input logic [addressBits-1:0] readAddressA,
    input logic [addressBits-1:0] readAddressB,

    input logic [N-1:0] A, 
    input logic [N-1:0] B, 
    input logic [N-1:0] C, 
    /* --------------------------------- Outputs -------------------------------- */
    output logic [N-1:0] destination1A,
    output logic [N-1:0] destination2A,
    output logic [N-1:0] destination1B,
    output logic [N-1:0] destination2B,
    output logic [N-1:0] Q [(2<<addressBits-1)-1:0]
);
    
    // Add your description here
   
    logic [(2<<addressBits-1)-1:0] en;
    logic [N-1:0] data;
    logic [N-1:0] outA;
    logic [N-1:0] outB;
    //regfile
    genvar      i ;
    generate
    for (i = 0; i<(2<<addressBits-1) ;i=i+1 ) 
    begin
      always_ff @(posedge clk, negedge rst_n) 
      begin  
        if (!rst_n)         
        begin
            if(i==1)//second address set to all ones
            Q[i] <= {N{1'b1}};
            else//other addresses set to all zeros
            Q[i] <= {N{1'b0}};
        end
        else if (en[i])     Q[i] <= data;
      end
    end
  endgenerate
  //select source
  always_comb 
  begin
    case (selectSource)
      (2'b00): data = A;
      (2'b01): data = B;
      (2'b10): data = C;  
      default : data = {N{1'b0}};
    endcase
  end
  
  //write data (need loop)
  always_comb 
  begin
    for(int i=0;i<(2<<addressBits-1);i++)
        en[i]=1'b0;
    if(write_en)
    begin
         /*
        case (writeAddress)
        (2'b00): en[0] = 1'b1;
        (2'b01): en[1] = 1'b1;
        (2'b10): en[2] = 1'b1;
        (2'b11): en[3] = 1'b1;
        default : en = 4'b0000;
        endcase
        */   
        for(int i=0;i<(2<<addressBits-1);i++)
        begin
            if(writeAddress==i)
            en[i]=1'b1;
        end
    end
 
    else
    begin
        for(int i=0;i<(2<<addressBits-1);i++)
        en[i]=1'b0;
    end
  end
  //Read Address A B
 always_comb begin
    /*
    case (readAddressA)
      (2'b00): outA = Q[0];
      (2'b01): outA = Q[1];
      (2'b10): outA = Q[2];
      (2'b11): outA = Q[3];
      default : outA ={N{1'b0}};
    endcase
    */
    for(int i=0;i<(2<<addressBits-1);i++)
        begin
            if(readAddressA==i)
            outA = Q[i];
        end
  end
  
 always_comb begin
    /*
    case (readAddressB)
      (2'b00): outB = Q[0];
      (2'b01): outB = Q[1];
      (2'b10): outB = Q[2];
      (2'b11): outB = Q[3];
      default : outB ={N{1'b0}};
    endcase
    */
    for(int i=0;i<(2<<addressBits-1);i++)
        begin
            if(readAddressB==i)
            outB = Q[i];
        end
  end
  //select destination A B
   always_comb begin
    case (selectDestinationA)
      (1'b0): 
      begin
      destination1A = outA;
      destination2A = {N{1'b0}};//destination2A got nothing
      end
      (1'b1): 
      begin
      destination2A= outA;
      destination1A = {N{1'b0}};//destination1A got nothing
      end
      default : 
      begin
      destination1A = {N{1'b0}};
      destination2A = {N{1'b0}};
      end
    endcase
  end
  
  always_comb begin
    case (selectDestinationB)
      (1'b0): 
      begin
      destination1B = outB;
      destination2B = {N{1'b0}};//destination2B got nothing
      end
      (1'b1): 
      begin
      destination2B= outB;
      destination1B = {N{1'b0}};//destination1A got nothing
      end
      default : 
      begin
      destination1B = {N{1'b0}};
      destination2B = {N{1'b0}};
      end
    endcase
  end
  
endmodule

