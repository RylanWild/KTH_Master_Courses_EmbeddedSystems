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


module IL2230_lab2 #( 
    parameter MAC_form = "Two_MACs", //others: "N_MACs" and "N_MACs"
    parameter NONLINEAR_FUNC = "ReLu" ,//others: "sigmoid" and "ReLu"
    parameter N = 4, //neuron number
    parameter M = 4, //neuron number
    parameter K=3,  //number of layer
    parameter DW = 8, //Data input width
    parameter INT_D = 3, //integer point of data input
    parameter WW = 8, //Weight width
    parameter INT_W = 3, //integer point of weights
    parameter OW = 8,   //output width
    parameter INT_O = 3 //integer point of data output
)(
    input            clk,
    input            rst_n,
    (* dont_touch = "yes" *)input  [DW-1:0]  data_in[N-1:0],
    (* dont_touch = "yes" *)input  [WW-1:0]  weight_in[N*M*K-1:0],
    (* dont_touch = "yes" *)input  [DW-1:0]  bias,
    output [OW-1:0]  data_out [M-1:0]
);

    localparam M_FRAC = DW-INT_D;
    localparam M_INT  = INT_D;

    (* dont_touch = "yes" *)logic [DW+WW+N-1:0] neuron_out;
    (* dont_touch = "yes" *)logic [        7:0] sigmoid_out;
    (* dont_touch = "yes" *)logic [     OW-1:0] ReLu_out, step_out;

    logic [DW-1:0]  data_reg[M-1:0];//after calculating one layer, save the output as the input for next layer
    logic [DW-1:0]  data_sigmoid_output_reg[M-1:0];//register for every neuron's output in one layer
    logic [DW-1:0]  output_reg[N-1:0];
    //logic [WW-1:0] weight_in_per_neuron [N-1];
    int counter; //to count the number of layer

    enum logic [1:0] {idle = 2'b00, calculate = 2'b01, shift_data=2'b10, finish=2'b11} state,state_next;//FSM state

    always_ff @(posedge clk, negedge rst_n)begin
        if(!rst_n)state<=idle;
        else state<=state_next;
    end

    always_comb begin
        case(state)
            idle:begin
                counter=0;
                state_next=calculate;
                data_reg=data_in;
                for(int j=0;j<M;j++)begin
                    output_reg[j]='b0;
                end
            end
            calculate:begin
                for(int i=0;i<M;i++)begin
                    parallel_fully #(
                        .M(DW),
                        .Q(WW),
                        .integer_input(INT_D),
                        .fraction_input(DW-INT_D),
                        .W_integer(INT_W),
                        .W_fraction(WW-INT_W),
                        .N(N)
                        )para_inst(
                        .W(weight_in[(i+counter*M+1)*N-1:(i+counter*M)*N]),
                        .X(data_reg),
                        .rst_n(rst_n),
                        .clk(clk),
                        .b(bias),
                        .out_real(neuron_out)
                        );
                    data_sigmoid_output_reg[i]=sigmoid_out;//we should get the result of the activation function
                end
                state_next=shift_data;
                counter++;
            end
            shift_data:begin
                data_reg=data_sigmoid_output_reg;
                if(counter==K) state_next=finish;
                else state_next=calculate; 
            end
            finish:begin
                output_reg=data_reg;
                counter=0;
            end  //one problem exist: the output now is just a DW-bits data, it should be a two dimentional data array
        endcase   
    end
    assign data_out=output_reg;


//////////////////////////////////////////////////////////////
//Nonlinear functions implementation
//////////////////////////////////////////////////////////////

//sigmoid function
sigmoid #(             
    .M         (M_FRAC+M_INT),
    .X_INT     (M_INT),
    .X_FRACTION(M_FRAC)
)sigmoid_inst(
    .x         (neuron_out),
    .y         (sigmoid_out)
);

//ReLu function
ReLU #(
    .M         (M_FRAC+M_INT),
    .N         (N),
    .X_INTEGER (M_INT), 
    .X_FRACTION(M_FRAC),
    .y_integer (INT_O),
    .y_fraction(OW-INT_O)
)ReLu_inst(
    .x         (neuron_out),
    .y         (ReLu_out)
);

//step function
step #(
    .M         (M_FRAC+M_INT),
    .N         (N), 
    .y_integer (INT_O),
    .y_fraction(OW-INT_O)
)step_inst(
    .x         (neuron_out),
    .y         (step_out)
);

///////////////////////////////////////////////
//final result according to the selected nonlinear function
//generate if(NONLINEAR_FUNC=="sigmoid") begin
//    assign data_out[7:0] = sigmoid_out;
//    assign data_out[OW-1:8] = 0;
//end else if(NONLINEAR_FUNC=="ReLu") begin
//    assign data_out = ReLu_out;
//end else begin
//    assign data_out = step_out;
//end
//endgenerate




endmodule
