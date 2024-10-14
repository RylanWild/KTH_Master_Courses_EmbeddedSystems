

`timescale 10ns/1ns

module sigmoid_tb();

    logic signed [7:0] input_data;
    logic signed [7:0] output_data;

    sigmoid_activation DUT(.*);



initial begin

    $display("Testbench starting");

    input_data <= 8'b10000011;
    //excpected output 0
    #10ns;
    assert (output_data == 0) 
    else   $error("Excpected 8'b00000000, got %b", output_data);

    #10ns;
    input_data <= 8'b11111111;
    // excpect 8'b00001111
    #10ns;
    assert (output_data == 8'b00001111) 
    else   $error("Excpected 8'b00001111, got %b", output_data);
    
    #10ns;
    input_data <= 8'b00000000;
    // excpect 8'b00010000;
    #10ns;
    assert (output_data == 8'b00010000) 
    else   $error("Excpected 8'b00010000, got %b", output_data);
    
    #10ns;
    input_data <= 8'b01111001;
    // excpect 8'b00011111
    #10ns;
    assert (output_data == 8'b00011111) 
    else   $error("Excpected 8'b00011111, got %b", output_data);

    $display("Testbench complete");
    end
endmodule