/*
@File    :   serial_implementation.sv
@Time    :   2023/11/20 15:30:57
@Author  :   Kevin Pettersson 
@Version :   1.0
@Contact :   kevinpet@kth.se
@License :   (C)Copyright 2023, Kevin Pettersson
@Desc    :   
*/


module serial_implementation #(parameter N = 64, parameter precision = 16)(
    input logic clk,
    input logic signed [precision-1:0] bias,
    input logic signed [precision-1:0] weights [N-1:0],
    input logic signed [precision-1:0] x [N-1:0],

    output logic signed [precision-1:0] output_result
);


 logic signed [precision-1:0] weight;
 logic signed [precision-1:0] data_in;
 logic signed [precision-1:0] prev_result;
 logic signed [precision-1:0] temp_MAC_data;

integer iteration = 0;

/* ------------------------- Instantiate the one MAC ------------------------ */

MAC #(.precision(precision)) MAC_module(
    .weight(weight),
    .data_in(data_in),
    .prev_result(prev_result),

    .MAC_output(temp_MAC_data)
);

logic signed [precision-1:0] activated_MAC;
ReLU_activation #(precision) activation_function((temp_MAC_data), activated_MAC);


assign output_result = (iteration == 0) ? activated_MAC : output_result;

always @(posedge clk) begin
    weight <= weights[iteration];
    data_in <= x[iteration];
    if(iteration == 0) begin
        prev_result <= bias;
    end else begin
        prev_result <= temp_MAC_data;
    end

    if(iteration == N-1) begin
        iteration = 0;
    end else begin
        iteration++;
    end    

end


endmodule