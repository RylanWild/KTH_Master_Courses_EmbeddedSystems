/*
@File    :   ReLu_activation.sv
@Time    :   2023/11/22 10:54:40
@Author  :   Kevin Pettersson 
@Version :   1.0
@Contact :   kevinpet@kth.se
@License :   (C)Copyright 2023, Kevin Pettersson
@Desc    :   
*/


module ReLU_activation #(parameter precision = 16)(
    input logic signed [precision-1:0] input_data,
    
    output logic signed [precision-1:0] output_data
);

always_comb begin
    if (input_data > 0) begin
        output_data = input_data;
    end else begin
        output_data = 0;
    end
end

endmodule