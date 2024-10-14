// N = number of inputs ( keep in mind that with the bias is N+1)
// M = number of bits on which each value is stored
module FSM_2_MAC #(
    parameter N = 2, 
    parameter M = 32,
    parameter IN_INT = 12,
    parameter IN_FRAC = 20,
    parameter O_INT =  26,
    parameter O_FRAC = 40
) ( 
    input logic clk,
    input logic rst_n,
    input logic [M-1:0] data [N-1:0],
    input logic [M-1:0] weight [N-1:0], 
    input logic [M-1:0] bias,
    output logic[O_INT+O_FRAC-1:0] result
);

localparam C = (N+1)>>1;
localparam logic[M-1:0] ONE = {{(IN_INT-1){1'b0}}, 1'b1, {(IN_FRAC){1'b0}}};

logic [             7:0] counter;
logic [             7:0] next_counter;
logic [           M-1:0] MAC1_data, MAC1_weight;
logic [O_INT+O_FRAC-1:0] MAC1_add, MAC1_out, MAC1_reg, result_w;
logic [           M-1:0] MAC2_data, MAC2_weight;
logic [O_INT+O_FRAC-1:0] MAC2_add, MAC2_out, MAC2_reg;

always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
    end 
    else begin
        counter <= next_counter;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        result <= 0;
    end else begin
        result <= result_w;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        MAC1_reg <= 0;
    else
        MAC1_reg <= MAC1_out;
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        MAC2_reg <= 0;
    else
        MAC2_reg <= MAC2_out;
end

//Combinational Logic
always_comb begin
    if(counter==C)
        next_counter <= 0;
    else
        next_counter <= counter + 1'b1;
end

genvar i;
generate for(i=0;i<=C;i=i+1) begin
    if(i==0) begin
        assign MAC1_data   = (counter==i)?bias:{M{1'bz}};
        assign MAC1_weight = (counter==i)?ONE:{M{1'bz}};
        assign MAC2_data   = (counter==i)?data[i+C]:{M{1'bz}};
        assign MAC2_weight = (counter==i)?weight[i+C]:{M{1'bz}};
    end else if(i==C) begin
        if(N[0]) begin //ODD number
            assign MAC1_data   = (counter==i)?MAC1_reg:{M{1'bz}};
            assign MAC1_weight = (counter==i)?ONE:{M{1'bz}};
            assign MAC2_data   = (counter==i)?MAC2_reg:{M{1'bz}};
            assign MAC2_weight = (counter==i)?ONE:{M{1'bz}};
        end else begin //EVEN number
            assign MAC1_data   = (counter==i)?data[i-1]:{M{1'bz}};
            assign MAC1_weight = (counter==i)?weight[i-1]:{M{1'bz}};
            assign MAC2_data   = (counter==i)?MAC2_reg[i+C-1]:{M{1'bz}};
            assign MAC2_weight = (counter==i)?ONE:{M{1'bz}};
        end
    end else begin
        assign MAC1_data   = (counter==i)?data[i-1]:{M{1'bz}};
        assign MAC1_weight = (counter==i)?weight[i-1]:{M{1'bz}};
        assign MAC2_data   = (counter==i)?data[i+C]:{M{1'bz}};
        assign MAC2_weight = (counter==i)?weight[i+C]:{M{1'bz}};
    end
end
endgenerate

generate if(N[0]) begin
    assign MAC1_add  = (counter==0)?0:(counter==C)?MAC2_reg:MAC1_out;
    assign MAC2_add  = (counter==0)?0:(counter==C)?MAC1_reg:MAC2_out;
end else begin
    assign MAC1_add  = (counter==0)?0:(counter==C)?MAC2_reg:MAC1_out;
    assign MAC2_add  = (counter==0)?0:(counter==C)?MAC1_reg:MAC2_out;
end
endgenerate

assign result_w = (counter==C)?MAC1_out:result;

MAC #(
    .M         (M),
    .Q         (M),
    .x_integer (IN_INT),
    .x_fraction(IN_FRAC),
    .w_integer (O_INT), 
    .w_fraction(O_FRAC)
)MAC1_inst(
    .x         (MAC1_data),
    .w         (MAC1_weight),
    .adder     (MAC1_add),
    .result    (MAC1_out)
);

MAC #(
    .M         (M),
    .Q         (M),
    .x_integer (IN_INT),
    .x_fraction(IN_FRAC),
    .w_integer (O_INT), 
    .w_fraction(O_FRAC)
)MAC2_inst(
    .x         (MAC2_data),
    .w         (MAC2_weight),
    .adder     (MAC2_add),
    .result    (MAC2_out)
);


endmodule