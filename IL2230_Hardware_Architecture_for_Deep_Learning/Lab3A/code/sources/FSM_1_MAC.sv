// N = number of inputs ( keep in mind that with the bias is N+1)
// M = number of bits on which each value is stored
module FSM_1_MAC #(
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

logic [             7:0] counter;
logic [             7:0] next_counter;
logic [           M-1:0] MAC_data, MAC_weight;
logic [O_INT+O_FRAC-1:0] MAC_add, MAC_out, MAC_reg, result_w;

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
        MAC_reg <= 0;
    else
        MAC_reg <= MAC_out;
end

//Combinational Logic
always_comb begin
    if(counter==N)
        next_counter <= 0;
    else
        next_counter <= counter + 1'b1;
end

genvar i;
generate for(i=0;i<N+1;i=i+1) begin
    if(i==0) begin
        assign MAC_data   = (counter==i)?bias:{M{1'bz}};
        assign MAC_weight = (counter==i)?{{(IN_INT-1){1'b0}}, 1'b1, {(IN_FRAC){1'b0}}}:{M{1'bz}};
    end else begin
        assign MAC_data   = (counter==i)?data[i-1]:{M{1'bz}};
        assign MAC_weight = (counter==i)?weight[i-1]:{M{1'bz}};
    end
end
endgenerate

assign MAC_add  = (counter==0)?0:MAC_out;
assign result_w = (counter==N)?MAC_out:result;

MAC #(
    .M         (M),
    .Q         (M),
    .x_integer (IN_INT),
    .x_fraction(IN_FRAC),
    .w_integer (O_INT), 
    .w_fraction(O_FRAC)
)MAC_inst(
    .x         (MAC_data),
    .w         (MAC_weight),
    .adder     (MAC_add),
    .result    (MAC_out)
);


endmodule