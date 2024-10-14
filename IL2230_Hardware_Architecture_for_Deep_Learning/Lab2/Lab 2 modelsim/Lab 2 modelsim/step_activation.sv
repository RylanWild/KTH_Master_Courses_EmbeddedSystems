/*
@File    :   step_activation.sv
@Time    :   2023/11/22 10:55:55
@Author  :   Kevin Pettersson 
@Version :   1.0
@Contact :   kevinpet@kth.se
@License :   (C)Copyright 2023, Kevin Pettersson
@Desc    :   
*/


module Step_activation #(parameter precision = 8, parameter threshold = 0)(
    input logic signed [precision-1:0] input_data,
    
    output logic output_data
);

always_comb begin
    if (input_data >= threshold) begin
        output_data = 1'b1;
    end else begin
        output_data = 1'b0;
    end
end

endmodule