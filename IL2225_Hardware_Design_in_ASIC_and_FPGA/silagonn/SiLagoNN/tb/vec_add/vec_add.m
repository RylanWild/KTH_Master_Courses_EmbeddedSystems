
% Memory testcase

% Features:
%  - Memory Read
%  - Reading one block of SRAM
%  - SRAM and Register File are in the same column.

M = [0 : 63]; 	  %! MEM<> [0,0]
A = zeros(1, 16); %! RFILE<> [0,0]
B = zeros(1, 16); %! RFILE<> [0,0]
C = zeros(1, 16); %! RFILE<> [0,0]

A(1:16) = M(1:16);
B(1:16) = M(17:32);
C = silago_dpu_add(A,B) %! DPU<> [0,0]
