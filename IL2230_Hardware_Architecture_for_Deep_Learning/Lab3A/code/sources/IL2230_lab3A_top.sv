
module LAB3A_top #(
    parameter   TNEURONS = 3,//"N", //others: 1 total neurons used
    parameter   MAC_form = "N_MACs", //others: "ONE_MAC" and "Two_MACs"
    parameter   NONLINEAR_FUNC = "ReLu" ,//others: "sigmoid" and "Step"
    parameter   M  = 3, //number of layers
    parameter   N  = 3, //number of neurons per layer
    parameter   DW = 8, //Data width
    parameter   INT_D = 3 //integer point of data
)(
    input            clk,
    input            rst_n,
    input  [DW-1:0]  data,
    input  [DW-1:0]  weight,
    input  [DW-1:0]  bias_in,
    output           data_valid,
    output [DW-1:0]  data_o
);

    logic [DW-1:0]  data_in[N-1:0];
    logic [DW-1:0]  weight_in[N*N*(M-1)-1:0];
    logic [DW-1:0]  bias[M-2:0];
    logic [DW-1:0]  data_out[N-1:0];
    logic           data_vld;

genvar i, j, p;
generate for (i=0;i<N;i=i+1) begin
    assign data_in[i] = data + i;
    assign weight_in[i] = weight - i;
end
endgenerate

generate for (j=0;j<N*N*(M-1);j=j+1) begin
    assign weight_in[j] = weight - j;
end
endgenerate

generate for (p=0;p<M-1;p=p+1) begin
    assign bias[p] = bias_in - p;
end
endgenerate

    assign data_o = data_out[0];
    assign data_valid = data_vld;

IL2230_lab3A #(
    .TNEURONS      (TNEURONS      ),
    .MAC_form      (MAC_form      ),
    .NONLINEAR_FUNC(NONLINEAR_FUNC),
    .M             (M             ),
    .N             (N             ),
    .DW            (DW            ),
    .INT_D         (INT_D         )
) DUT(.*);



endmodule