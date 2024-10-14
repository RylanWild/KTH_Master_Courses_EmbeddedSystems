/*
@File    :   sigmoid_activation.sv
@Time    :   2023/11/24 10:05:57
@Author  :   Kevin Pettersson 
@Version :   1.0
@Contact :   kevinpet@kth.se
@License :   (C)Copyright 2023, Kevin Pettersson
@Desc    :   
*/


module sigmoid_activation2 (    
    input logic signed [7:0] input_data,
    
    output logic signed [7:0] output_data
);

// i treat the numbers as non fixed point for simplicity 

always_comb begin
    if(input_data > 60) begin
        output_data = 8'b01111110; 
    end else if(input_data < -60) begin
        output_data = 8'b00000000; 
    end else begin
        case(input_data)
            8'b11000100 : output_data = 8'b00000000;
            8'b11000101 : output_data = 8'b00000000;
            8'b11000110 : output_data = 8'b00000000;
            8'b11000111 : output_data = 8'b00000000;
            8'b11001000 : output_data = 8'b00000000;
            8'b11001001 : output_data = 8'b00000000;
            8'b11001010 : output_data = 8'b00000000;
            8'b11001011 : output_data = 8'b00000000;
            8'b11001100 : output_data = 8'b00000000;
            8'b11001101 : output_data = 8'b00000000;
            8'b11001110 : output_data = 8'b00000000;
            8'b11001111 : output_data = 8'b00000000;
            8'b11010000 : output_data = 8'b00000001;
            8'b11010001 : output_data = 8'b00000001;
            8'b11010010 : output_data = 8'b00000001;
            8'b11010011 : output_data = 8'b00000001;
            8'b11010100 : output_data = 8'b00000001;
            8'b11010101 : output_data = 8'b00000001;
            8'b11010110 : output_data = 8'b00000001;
            8'b11010111 : output_data = 8'b00000010;
            8'b11011000 : output_data = 8'b00000010;
            8'b11011001 : output_data = 8'b00000010;
            8'b11011010 : output_data = 8'b00000010;
            8'b11011011 : output_data = 8'b00000011;
            8'b11011100 : output_data = 8'b00000011;
            8'b11011101 : output_data = 8'b00000011;
            8'b11011110 : output_data = 8'b00000100;
            8'b11011111 : output_data = 8'b00000100;
            8'b11100000 : output_data = 8'b00000100;
            8'b11100001 : output_data = 8'b00000101;
            8'b11100010 : output_data = 8'b00000110;
            8'b11100011 : output_data = 8'b00000110;
            8'b11100100 : output_data = 8'b00000111;
            8'b11100101 : output_data = 8'b00000111;
            8'b11100110 : output_data = 8'b00001000;
            8'b11100111 : output_data = 8'b00001001;
            8'b11101000 : output_data = 8'b00001010;
            8'b11101001 : output_data = 8'b00001011;
            8'b11101010 : output_data = 8'b00001100;
            8'b11101011 : output_data = 8'b00001101;
            8'b11101100 : output_data = 8'b00001111;
            8'b11101101 : output_data = 8'b00010000;
            8'b11101110 : output_data = 8'b00010010;
            8'b11101111 : output_data = 8'b00010011;
            8'b11110000 : output_data = 8'b00010101;
            8'b11110001 : output_data = 8'b00010111;
            8'b11110010 : output_data = 8'b00011001;
            8'b11110011 : output_data = 8'b00011011;
            8'b11110100 : output_data = 8'b00011101;
            8'b11110101 : output_data = 8'b00011111;
            8'b11110110 : output_data = 8'b00100010;
            8'b11110111 : output_data = 8'b00100100;
            8'b11111000 : output_data = 8'b00100111;
            8'b11111001 : output_data = 8'b00101010;
            8'b11111010 : output_data = 8'b00101101;
            8'b11111011 : output_data = 8'b00101111;
            8'b11111100 : output_data = 8'b00110010;
            8'b11111101 : output_data = 8'b00110110;
            8'b11111110 : output_data = 8'b00111001;
            8'b11111111 : output_data = 8'b00111100;
            8'b00000000 : output_data = 8'b00111111;
            8'b00000001 : output_data = 8'b01000010;
            8'b00000010 : output_data = 8'b01000101;
            8'b00000011 : output_data = 8'b01001000;
            8'b00000100 : output_data = 8'b01001100;
            8'b00000101 : output_data = 8'b01001111;
            8'b00000110 : output_data = 8'b01010001;
            8'b00000111 : output_data = 8'b01010100;
            8'b00001000 : output_data = 8'b01010111;
            8'b00001001 : output_data = 8'b01011010;
            8'b00001010 : output_data = 8'b01011100;
            8'b00001011 : output_data = 8'b01011111;
            8'b00001100 : output_data = 8'b01100001;
            8'b00001101 : output_data = 8'b01100011;
            8'b00001110 : output_data = 8'b01100101;
            8'b00001111 : output_data = 8'b01100111;
            8'b00010000 : output_data = 8'b01101001;
            8'b00010001 : output_data = 8'b01101011;
            8'b00010010 : output_data = 8'b01101100;
            8'b00010011 : output_data = 8'b01101110;
            8'b00010100 : output_data = 8'b01101111;
            8'b00010101 : output_data = 8'b01110001;
            8'b00010110 : output_data = 8'b01110010;
            8'b00010111 : output_data = 8'b01110011;
            8'b00011000 : output_data = 8'b01110100;
            8'b00011001 : output_data = 8'b01110101;
            8'b00011010 : output_data = 8'b01110110;
            8'b00011011 : output_data = 8'b01110111;
            8'b00011100 : output_data = 8'b01110111;
            8'b00011101 : output_data = 8'b01111000;
            8'b00011110 : output_data = 8'b01111000;
            8'b00011111 : output_data = 8'b01111001;
            8'b00100000 : output_data = 8'b01111010;
            8'b00100001 : output_data = 8'b01111010;
            8'b00100010 : output_data = 8'b01111010;
            8'b00100011 : output_data = 8'b01111011;
            8'b00100100 : output_data = 8'b01111011;
            8'b00100101 : output_data = 8'b01111011;
            8'b00100110 : output_data = 8'b01111100;
            8'b00100111 : output_data = 8'b01111100;
            8'b00101000 : output_data = 8'b01111100;
            8'b00101001 : output_data = 8'b01111100;
            8'b00101010 : output_data = 8'b01111101;
            8'b00101011 : output_data = 8'b01111101;
            8'b00101100 : output_data = 8'b01111101;
            8'b00101101 : output_data = 8'b01111101;
            8'b00101110 : output_data = 8'b01111101;
            8'b00101111 : output_data = 8'b01111101;
            8'b00110000 : output_data = 8'b01111101;
            8'b00110001 : output_data = 8'b01111110;
            8'b00110010 : output_data = 8'b01111110;
            8'b00110011 : output_data = 8'b01111110;
            8'b00110100 : output_data = 8'b01111110;
            8'b00110101 : output_data = 8'b01111110;
            8'b00110110 : output_data = 8'b01111110;
            8'b00110111 : output_data = 8'b01111110;
            8'b00111000 : output_data = 8'b01111110;
            8'b00111001 : output_data = 8'b01111110;
            8'b00111010 : output_data = 8'b01111110;
            8'b00111011 : output_data = 8'b01111110;
            default : output_data = 8'b01111110;
        endcase
    end
end




endmodule