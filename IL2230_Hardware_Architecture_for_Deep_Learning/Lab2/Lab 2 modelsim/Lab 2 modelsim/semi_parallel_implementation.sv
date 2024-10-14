/*
@File    :   semi_parallel_implementation.s
@Time    :   2023/11/21 09:42:18
@Author  :   Kevin Pettersson 
@Version :   1.0
@Contact :   kevinpet@kth.se
@License :   (C)Copyright 2023, Kevin Pettersson
@Desc    :   
*/


module semi_parallel_implementation #(parameter N =4 , parameter precision =16)(
    input logic clk,
    input logic signed [precision-1:0] bias,
    input logic signed [precision-1:0] weights [N-1:0],
    input logic signed [precision-1:0] x [N-1:0],

    output logic signed [precision-1:0] output_result
);


 logic signed [precision-1:0] weight_1, weight_2;
 logic signed [precision-1:0] data_in_1, data_in_2;
 logic signed [precision-1:0] prev_result_1, prev_result_2;
 logic signed [precision-1:0] temp_MAC_data_1, temp_MAC_data_2;

 integer iteration_1 = 0;
 integer iteration_2 = N-1;

/* ------------------------- Instantiate the two MAC ------------------------ */

/*
Could be made more general but since lab only asks for K=2 i see no point in
doing so
*/

MAC #(.precision(precision)) MAC_module_1(
    .weight(weight_1),
    .data_in(data_in_1),
    .prev_result(prev_result_1),

    .MAC_output(temp_MAC_data_1)
);

MAC #(.precision(precision)) MAC_module_2(
    .weight(weight_2),
    .data_in(data_in_2),
    .prev_result(prev_result_2),

    .MAC_output(temp_MAC_data_2)
);

logic signed [precision-1:0] activated_MAC;
ReLU_activation #(precision) activation_fiunction((temp_MAC_data_1 + temp_MAC_data_2), activated_MAC);

assign output_result = (iteration_1 == 0) ? activated_MAC : output_result;


always @(posedge clk) begin

    weight_1 <= weights[iteration_1];
    weight_2 <= weights[iteration_2];
    data_in_1 <= x[iteration_1];
    data_in_2 <= x[iteration_2];

    if(iteration_1 == 0) begin
        prev_result_1 <= bias;
        prev_result_2 <= 'b0;
    end else begin
        prev_result_1 <= temp_MAC_data_1;
        prev_result_2 <= temp_MAC_data_2;
    end

    if(iteration_1+1 == iteration_2) begin
        iteration_1 = 0;
        iteration_2 = N-1;
        //output_result <= temp_MAC_data_1 + temp_MAC_data_2;
    end else begin
        iteration_1++;
        iteration_2--;
    end    

end

endmodule