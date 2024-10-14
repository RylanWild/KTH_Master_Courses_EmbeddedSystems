IL2230 Lab3A --instruction
/*********************parameters instruction*****************************/
TNEURONS: has value of 1 and N. 1 means the neuron use one neuron design, N means using the parallel neuron design.
MAC_form: choose the design of the neuron. One-Mac design, two-Mac design and fully parallel design.
NOLINEAR_FUNC:choose the activation function.
M: number of the layers in MLP.
N: number of the neurons per layer.
DW: bit width of data.
INT_D: bit width of the integer part of data.

/***********************files instruction************************************/
IL2230_lab3A_top.sv: top file of lab3A, control the input to IL2230_3A.sv.
IL2230_3A.sv: main file for lab 3A. In this file, we finish the design of task1 and task2. Using conter as thepointer to the state.
LAB2_top.sv: top file for lab2, which finished the implementation of one neuron.
FSM_1_MAC.sv: the design of one MAC design in lab2.
FSM_2_MAC.sv: the design of two MAC design in lab2.
sigmoid.sv, ReLu.sv, step.sv: implementation of activation function.