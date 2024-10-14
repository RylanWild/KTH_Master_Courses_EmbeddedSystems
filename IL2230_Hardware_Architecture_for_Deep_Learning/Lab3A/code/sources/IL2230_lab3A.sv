
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/29 09:09:28
// Design Name: 
// Module Name: IL2230_lab2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module IL2230_lab3A #(
    parameter   TNEURONS = 1, //others: N total neurons used
    parameter   MAC_form = "N_MACs", //others: "ONE_MAC" and "Two_MACs"
    parameter   NONLINEAR_FUNC = "ReLu" ,//others: "sigmoid" and "Step"
    parameter   M  = 3, //number of layers
    parameter   N  = 2, //number of neurons per layer
    parameter   DW = 8, //Data width
    parameter   INT_D = 3 //integer point of data
) (
    input logic clk,
    input logic rst_n,
    (* dont_touch = "yes" *)input  [DW-1:0]  data_in[N-1:0],
    (* dont_touch = "yes" *)input  [DW-1:0]  weight_in[N*N*(M-1)-1:0],
                                             //N neurons per layer, every neuron has N input data,
                                             //weights of input layer are all 1
    (* dont_touch = "yes" *)input  [DW-1:0]  bias[M-2:0], //output layer has no bias
    output logic     data_vld,
    output logic[DW-1:0]  data_out[N-1:0]
);

logic[DW-1:0]    layer_din[N-1:0];//data input per layer
logic[DW-1:0]    neuron_win[N-1:0];//weight input per neuron
logic[DW-1:0]    layer_win[N*N-1:0];//weight input per layer
logic[DW-1:0]    layer_bias;
logic[DW-1:0]    layer_dout[N-1:0], layer_reg[N-1:0]; //data output per layer
logic[N-1:0]     neuron_assign;
logic[DW-1:0]    neuron_dout;// data output per neuron

logic[7:0]       neuron_cnt, layer_cnt, MAC_cnt;
logic[7:0]       neuron_cnt_next, layer_cnt_next, MAC_cnt_next;

//FSM
generate if(TNEURONS==1) begin
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            neuron_cnt <= 0;
        end else begin
            neuron_cnt <= neuron_cnt_next;
        end
    end
end else begin
    assign neuron_cnt = N-1;
end
endgenerate

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        layer_cnt <= 0;
    end else begin
        layer_cnt <= layer_cnt_next;
    end
end

generate if((MAC_form=="ONE_MAC")||(MAC_form=="Two_MACs")) begin
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            MAC_cnt <= 0;
        end else begin
            MAC_cnt <= MAC_cnt_next;
        end
    end
end else begin
    assign MAC_cnt = N;
end
endgenerate

//count mac time first
generate if(MAC_form=="ONE_MAC") begin
    always_comb begin
        if(MAC_cnt==N) begin
            MAC_cnt_next = 0;
        end else begin
            MAC_cnt_next = MAC_cnt + 1'b1;
        end
    end
end else if(MAC_form=="Two_MACs") begin
    always_comb begin
        if((MAC_cnt>=N)||(!rst_n)) begin
            MAC_cnt_next = 0;
        end else begin
            MAC_cnt_next = MAC_cnt + 2; //Add 2 every time because of two MACs
        end
    end
end else begin
    assign MAC_cnt_next = N;
end
endgenerate

generate if(TNEURONS==1) begin
    always_comb begin //neurons count: 0 to N-1 per layer
        if(MAC_cnt>=N) begin//only if MACs completed the calculation
            if(neuron_cnt == (N-1)) begin
                neuron_cnt_next = 0;
            end else begin
                neuron_cnt_next = neuron_cnt + 1'b1;
            end
        end else begin
            neuron_cnt_next = neuron_cnt;
        end
    end
end else begin
    assign neuron_cnt_next = N-1;
end
endgenerate

always_comb begin
    if((MAC_cnt==N)&&(neuron_cnt == (N-1))) begin
        if((layer_cnt==(M-2))||(!rst_n)) begin//only hidden layers and output layer
            layer_cnt_next <= 0;
        end else begin
            layer_cnt_next <= layer_cnt + 1;
        end
    end else begin
        layer_cnt_next <= layer_cnt;
    end
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        data_vld <= 1'b0;
    end else begin
        if((MAC_cnt>=N)&&(layer_cnt==(M-2))&&(neuron_cnt == (N-1))) begin
            data_vld <= 1'b1;
        end else begin
            data_vld <= 1'b0;
        end
    end
end

//////////////////////////////////////////////////////////////
//assign data and weight
always_comb begin
    for(int i=0; i<N; i=i+1) begin
        layer_din[i] = (layer_cnt==0)?data_in[i]:layer_reg[i];
    end
end

always_comb begin
    layer_bias = bias[layer_cnt];
    for(int j=0; j<N*N; j=j+1) begin
       layer_win[j] = weight_in[N*N*layer_cnt+j];
    end
end

//genvar p;
//generate for(p=0;p<M-1;p=p+1) begin //input layer doesn't count
//    assign layer_bias = (layer_cnt==p)?bias[p]:{DW{1'bz}};
//    for(i=0; i<(N*N); i=i+1) begin
//        assign layer_win[i] = (layer_cnt==p)?weight_in[N*N*p+i]:{DW{1'bz}};
//    end 
//end endgenerate

always_comb begin
    for(int i=0; i<N; i=i+1) begin
        neuron_win[i] = layer_win[N*neuron_cnt+i];
    end
end

genvar q, i;
//generate for(q=0;q<N;q=q+1) begin
    //for(i=0; i<N; i=i+1) begin
    //    assign neuron_win[i] = (neuron_cnt==q)?layer_win[N*q+i]:{DW{1'bz}};
    //end

generate if(TNEURONS==1) begin
    for(q=0;q<N;q=q+1) begin
        always_ff @(posedge clk, negedge rst_n) begin
            if(!rst_n) begin
                neuron_assign[q] <= 1'b0;
            end else begin
                neuron_assign[q] <= (neuron_cnt==q)&&(MAC_cnt>=N);
            end
        end
        assign layer_reg[q] = neuron_assign[q]?neuron_dout:layer_reg[q];
    end
end else begin
    for(i=0; i<N; i=i+1) begin
        assign layer_reg[i] = layer_dout[i];
    end
end endgenerate

always_comb begin
    for(int i=0; i<N; i=i+1) begin
        data_out[i] = layer_reg[i];
    end
end
//////////////////////////////////////////////////////////////
//Neurons instalation
//////////////////////////////////////////////////////////////
genvar j;
generate if(TNEURONS==1) begin
    IL2230_lab2 #(
        .MAC_form       (MAC_form      ),
        .NONLINEAR_FUNC (NONLINEAR_FUNC),
        .N              (N             ), //input number
        .DW             (DW            ), //Data input width
        .INT_D          (INT_D         ), //integer point of data input
        .WW             (DW            ), //Weight width
        .INT_W          (INT_D         ), //integer point of weights
        .OW             (DW            ), //output width
        .INT_O          (INT_D         )  //integer point of data output
    )neuron_inst(
        .clk            (clk           ),
        .rst_n          (rst_n         ),
        .data_in        (layer_din     ),
        .weight_in      (neuron_win    ),
        .bias           (layer_bias    ),
        .data_out       (neuron_dout   )
    );
end else begin
    for(j=0; j<N; j=j+1)
        IL2230_lab2 #(
            .MAC_form       (MAC_form      ),
            .NONLINEAR_FUNC (NONLINEAR_FUNC),
            .N              (N             ), //input number
            .DW             (DW            ), //Data input width
            .INT_D          (INT_D         ), //integer point of data input
            .WW             (DW            ), //Weight width
            .INT_W          (INT_D         ), //integer point of weights
            .OW             (DW            ), //output width
            .INT_O          (INT_D         )  //integer point of data output
        )neuron_inst(
            .clk            (clk           ),
            .rst_n          (rst_n         ),
            .data_in        (layer_din     ),
            .weight_in      (layer_win[N*(j+1)-1:N*j]),
            .bias           (layer_bias    ),
            .data_out       (layer_dout[j] )
        );
end
endgenerate

endmodule


