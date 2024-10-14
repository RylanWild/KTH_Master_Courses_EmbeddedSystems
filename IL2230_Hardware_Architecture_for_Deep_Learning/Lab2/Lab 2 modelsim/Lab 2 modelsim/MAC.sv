/*
@File    :   MAC.sv
@Time    :   2023/11/20 15:21:27
@Author  :   Kevin Pettersson 
@Version :   1.0
@Contact :   kevinpet@kth.se
@License :   (C)Copyright 2023, Kevin Pettersson
@Desc    :   
*/



module MAC #(parameter precision = 16)(
    input logic signed [precision-1:0] weight,
    input logic signed [precision-1:0] data_in,
    input logic signed [precision-1:0] prev_result,

    output logic signed [precision-1:0] MAC_output
);

    logic signed [(precision*2)-1:0] intermediate_mult; 
    logic signed [precision-1:0] temp;
    logic signed [precision-1:0] temp2;
    logic signed [(precision*2)-1:0] MAC_output2;

always_comb begin
  
     //Q3.5     8-bits
     //Q6.10    16-bits
     //Q12.20   32-bits

     intermediate_mult = weight * data_in;
     MAC_output2 = intermediate_mult + prev_result;
     if(precision == 8) begin
        temp = intermediate_mult[12:5];
     end else if(precision == 16) begin
        temp = intermediate_mult[24:10];
     end else if(precision == 32) begin
        temp = intermediate_mult[48:20];
     end

    
    MAC_output = temp + prev_result;
    //MAC_output = (weight * data_in) + prev_result;
    // For 32-bit/16-bit/8-bit fixed point number, use 12/6/3 bits
    
    //MAC_output = intermediate_mult[(precision)] 
end

endmodule

//