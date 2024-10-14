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



module RF  #(parameter N = 8, parameter addressBits = 4) ( 
    /* --------------------------------- Inputs --------------------------------- */
    input logic clk,
    input logic rst_n,
    input logic select_destination_A,//from FSM
    input logic select_destination_B,//from FSM
    
    input logic [1:0] select_source,//from FSM
    input logic [addressBits-1:0] write_address,//from FSM
    input logic write_en_RF,//from FSM
    input logic [addressBits-1:0] read_address_A,//from FSM
    input logic [addressBits-1:0] read_address_B,//from FSM
    
    input logic [N-1:0] source_A, //from ALU
    input logic [N-1:0] source_B, //from SRAM
    input logic [N-1:0] source_C, //from FSM
    /* --------------------------------- Outputs -------------------------------- */
    output logic [N-1:0] destination1A,
    output logic [N-1:0] destination2A,
    output logic [N-1:0] destination1B,
    output logic [N-1:0] destination2B
);
    logic [N-1:0] Q [(2<<addressBits-1)-1:0];
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
    case (select_source)
      (2'b00): data = source_A;
      (2'b01): data = source_B;
      (2'b10): data = source_C;  
      default : data = {N{1'b0}};
    endcase
  end
  
  //write data (need loop)
  always_comb 
  begin
    for(int i=0;i<(2<<addressBits-1);i++)
        en[i]=1'b0;
    if(write_en_RF)//write
    begin
        for(int i=0;i<(2<<addressBits-1);i++)
        begin
            if(write_address==i)
            en[i]=1'b1;
        end
    end
 
    else//read
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
            if(read_address_A==i)
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
            if(read_address_B==i)
            outB = Q[i];
        end
  end
  //select destination A B
   always_comb begin
    case (select_destination_A)
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
    case (select_destination_B)
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


