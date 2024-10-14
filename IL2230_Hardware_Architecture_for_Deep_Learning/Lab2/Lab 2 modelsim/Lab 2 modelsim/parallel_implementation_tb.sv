/*
@File    :   parallel_implementation_tb.sv
@Time    :   2023/11/22 10:36:32
@Author  :   Kevin Pettersson 
@Version :   1.0
@Contact :   kevinpet@kth.se
@License :   (C)Copyright 2023, Kevin Pettersson
@Desc    :   
*/

`timescale 10ns/1ns

module parallel_implementation_tb();

    parameter N = 4;
    parameter precision = 16;

    logic clk = 1;
    logic signed [precision-1:0] bias;
    logic signed [precision-1:0] weights [N-1:0];
    logic signed [precision-1:0] x [N-1:0];
    logic signed [precision-1:0] output_result;

    parallel_implementation #(N, precision) DUT(.*);

always #5ns clk = ~clk; // generate clock signal

initial begin
    #5ns;
    $display("Testbench starting");
    weights[0] = 16'b000_001_00000_00000; // 1
    weights[1] = 16'b000_010_00000_00000; // 2 
    weights[2] = 16'b000_001_00000_00000; // 1
    weights[3] = 16'b000_001_00000_00000; // 1

    x[0] = 16'b000_001_00000_00000; // 1
    x[1] = 16'b000_001_00000_00000; // 1
    x[2] = 16'b000_001_00000_00000; // 1
    x[3] = 16'b000_010_00000_00000; // 2

    bias = 16'b0000_0000_0000_0001; //2^-10
    #10ns;
    assert(output_result == 16'b000110_0000000001)
    else $error("Excpected 16'b000110_0000000001, got %b", output_result);

    weights[0] = 16'b000_001_11000_00000; // 1.75
    weights[1] = 16'b000_010_00000_00000; // 2 
    weights[2] = 16'b000_001_00000_00000; // 1
    weights[3] = 16'b000_001_00000_00000; // 1

    x[0] = 16'b000_001_00000_00000; // 1
    x[1] = 16'b000_000_10000_00000; // 0.5
    x[2] = 16'b000_001_00000_00000; // 1
    x[3] = 16'b000_010_00000_00000; // 2

    // 1.75 + 1 + 1 +2 +2^-9 + 2^-10 = 5.75 + 2^-9 + 2^-10

    bias = 16'b0000_0000_0000_0011; //2^-9 + 2^-10
    #10ns;
    assert(output_result == 16'b000101_1100000011)
    else $error("Excpected 16'b000101_1100000011, got %b", output_result);

    $display("Testbench complete");
end


endmodule