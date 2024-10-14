


module MAC_tb();

    parameter precision = 8;
    logic signed [precision-1:0] weight;
    logic signed [precision-1:0] data_in;
    logic signed [precision-1:0] prev_result;

    logic signed [precision-1:0] MAC_output;

    MAC #(precision) DUT (.*);


    initial begin
        //Q5.3 -> Q10.6 [15:6] [5:0]
        /* --------------------------------- 8-bits --------------------------------- */
        if(precision == 8) begin
            weight = 8'b00011_100; //3.5
            data_in = 8'b00001_010; //1.25
            //excpected 00100_011
        end
        /* --------------------------------- 16-bits -------------------------------- */
        //Q10.6
        if(precision == 16) begin
            weight =  16'b00000_00011_100_000;
            data_in = 16'b00000_00001_010_000;
            //excpected 16'b00000_00100_011_000
        end
        prev_result = 0;
        #10ns;
        $display("Ouptut %b", MAC_output);
    end
endmodule


//1111_1110_1000_0000