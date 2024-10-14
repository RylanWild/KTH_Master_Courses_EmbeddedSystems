`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/29 09:52:05
// Design Name: 
// Module Name: IL2230_lab2_tb
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


module IL2230_lab3A_tb( );

    parameter   TNEURONS = "N"; //others: N total neurons used
    parameter   MAC_form = "N_MACs"; //others: "ONE_MAC" and "Two_MACs"
    parameter   NONLINEAR_FUNC = "ReLu" ;//others: "sigmoid" and "Step"
    parameter   M  = 3; //number of layers
    parameter   N  = 2; //number of neurons per layer
    parameter   DW = 8; //Data width
    parameter   INT_D = 3; //integer point of data

    localparam clk_edge = 5; //ns clock cycle = 2*clk_edge

    logic           clk;
    logic           rst_n;
    logic [DW-1:0]  data_in[N-1:0];
    logic [DW-1:0]  weight_in[N*N*(M-1)-1:0];
    logic [DW-1:0]  bias[M-2:0];
    logic           data_vld;
    logic [DW-1:0]  data_out[N-1:0];

IL2230_lab3A #(
    .TNEURONS      (TNEURONS      ),
    .MAC_form      (MAC_form      ),
    .NONLINEAR_FUNC(NONLINEAR_FUNC),
    .M             (M             ),
    .N             (N             ),
    .DW            (DW            ),
    .INT_D         (INT_D         )
) DUT(.*);

IL2230_lab3A_tb_prog #(
    .TNEURONS      (TNEURONS      ),
    .MAC_form      (MAC_form      ),
    .NONLINEAR_FUNC(NONLINEAR_FUNC),
    .M             (M             ),
    .N             (N             ),
    .DW            (DW            ),
    .INT_D         (INT_D         )
) TB(.*);

  initial begin
    clk = 0;
    rst_n = 0;
    #(clk_edge*3);
    rst_n = 1;
    forever begin
      clk = ~clk;
      #clk_edge;
    end
  end


endmodule

program IL2230_lab3A_tb_prog #(
    parameter   TNEURONS = 1, //others: N total neurons used
    parameter   MAC_form = "Two_MACs", //others: "ONE_MAC" and "N_MACs"
    parameter   NONLINEAR_FUNC = "ReLu" ,//others: "sigmoid" and "Step"
    parameter   M  = 3, //number of layers
    parameter   N  = 2, //number of neurons per layer
    parameter   DW = 8, //Data width
    parameter   INT_D = 3 //integer point of data
) (
    input                 clk,
    input                 rst_n,
    output logic [DW-1:0] data_in[N-1:0],
    output logic [DW-1:0] weight_in[N*N*(M-1)-1:0],
    output logic [DW-1:0] bias[M-2:0],
    input  [DW-1:0]       data_out[N-1:0]
);

    logic [15:0]        count, cnt;
    int j;
//    logic [DW+DW-1:0]   multi[N-1:0];
//    logic [DW+DW+N-1:0] add[N-1:0], add_out;
//    logic [DW-1:0]      result;

    initial begin
        for(int i=0; i<(M-1); i++) begin
//            data_in[i] = 0;
//            weight_in[i] = 0;
//            multi[i] = 0;
//            add[i] = 0;
            bias[i] = {1'b0,{(INT_D-1){1'b0}},{(DW-INT_D){1'b0}}};
        end
//        count = 0;
//        result = 0;
//        add_out = 0;
//
//        @(posedge rst_n);
//        forever begin
//            @(posedge clk);
//            for(int i=0; i<N; i++) begin
//                multi[i] = data_in[i]*weight_in[i];
//                if(i==0) begin
//                    add[i] = {bias, {(DW-INT_D+DW-INT_D-(DW-INT_D)){1'b0}}}+multi[i];
//                end else begin
//                    add[i] = add[i-1]+multi[i];
//                end
//            end
//            add_out = add[N-1];
//            result[DW-1:DW-INT_D] = add_out[DW-INT_D+DW-INT_D+INT_D-1:DW-INT_D+DW-INT_D];
//            result[DW-INT_D-1:0]  = add_out[DW-INT_D+DW-INT_D-1:DW-INT_D+DW-INT_D-(DW-INT_D)];
//        end
    end

generate if(MAC_form == "ONE_MAC") begin
    initial begin
        @(posedge rst_n);
        forever begin
            @(posedge clk);
            if(count<N)
                count = count + 1;
            else 
                count = 0;
        end
    end
end else if(MAC_form == "Two_MACs") begin
    initial begin
        @(posedge rst_n);
        forever begin
            @(posedge clk);
            if(count<N)
                count = count + 2;
            else 
                count = 0;
        end
    end
end else begin
    initial begin
        count = N;
    end
end
endgenerate

generate if(TNEURONS==1)
    initial begin
        cnt = 0;
        @(posedge rst_n);
        forever begin
            @(posedge clk);
            if(count>=N)
                if(cnt<N*(M-1)-1)
                    cnt = cnt + 1;
                else
                    cnt = 0;
            else
                cnt = cnt;
        end
    end
else
    initial begin
        cnt = 0;
        @(posedge rst_n);
        forever begin
            @(posedge clk);
            if(count>=N)
                if(cnt<M-2)
                    cnt = cnt + 1;
                else
                    cnt = 0;
            else
                cnt = cnt;
        end
    end
endgenerate

    initial begin
        j=0;
        for(int i=0; i<N; i++) begin
            data_in[i] = 0;
        end
        for(int i=0; i<N*N*(M-1); i++) begin
            weight_in[i] = 0;
        end
        @(posedge rst_n);
        forever begin
            @(posedge clk);
            for(int i=0; i<N; i++) begin
                if((cnt==0)&&(count>=N)) begin
                    data_in[i]   = $random;
                end else begin
                    data_in[i]   = data_in[i];
                end
            end
            for(int i=0; i<N*N*(M-1); i++) begin
                if((cnt==0)&&(count>=N)) begin
                    weight_in[i] = {i+j, {(DW-INT_D){1'b0}}};
                end else begin
                    weight_in[i] = weight_in[i];
                end
            end
            j=j+1;
        end
    end

endprogram
