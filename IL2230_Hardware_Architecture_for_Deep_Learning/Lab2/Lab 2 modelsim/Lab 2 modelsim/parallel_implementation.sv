/*
@File    :   parallel.sv
@Time    :   2023/11/20 15:22:47
@Author  :   Kevin Pettersson 
@Version :   1.0
@Contact :   kevinpet@kth.se
@License :   (C)Copyright 2023, Kevin Pettersson
@Desc    :   
*/


module parallel_implementation #(parameter N = 64, parameter precision = 16)(
    input logic clk,
    input logic signed [precision-1:0] bias,
    input logic signed [precision-1:0] weights [N-1:0],
    input logic signed [precision-1:0] x [N-1:0],

    output logic signed [precision-1:0] output_result
);

    //logic signed [precision-1:0] temp_output_result;
    //logic signed [precision-1:0] prev_result [N-1:0];
    logic signed [precision-1:0] temp_MAC_data [N:0];

    assign temp_MAC_data[0] = bias; // assign bias


    logic signed [precision-1:0] activated_MAC;
    ReLU_activation #(precision) activation_fiunction(temp_MAC_data[N], activated_MAC);

    // Connect the output of one instance to the input of the next instance
    generate
        genvar i;
        for (i = 0; i <= N-1; i = i + 1) begin
            MAC #(.precision(precision)) MAC_instance (
                .weight(weights[i]),
                .data_in(x[i]),
                .prev_result(temp_MAC_data[i]), // take previous output as input
                .MAC_output(temp_MAC_data[i+1]) // will go over N-1 therfore temp is N and last value is result
            );
        end
    endgenerate

    // at positive edge update output 
    always @(posedge clk) begin
        //temp_output_result <= temp_MAC_data[N];
        output_result <= activated_MAC;
    end


endmodule


