module Q2CSDF where

import ForSyDe.Shallow

-- Netlist
system s_in = (s_out1, s_out2) where
 (s_1,s_2) = a_1 s_in
 --s_4 = d_1 s_3
 --s_count = a_4 s_4
 s_out1 = a_2 s_1
 s_out2 = a_3 s_2

-- SDF actor 'a_1' that when the signal comes with the counter 0 goes to a2,comes with 1 goes to a3
a_1  = actor12SDF 2 (1, 1) f_1 where
 f_1 [x1,x2] = ([x1], [x2])

-- SDF actor 'a_2' that implements identity function
a_2 = actor11SDF 1 1 f_2 where
 f_2 [x] = [x]

-- SDF actor 'a_3' that implements negation function
a_3 = actor11SDF 1 1 f_3 where
 f_3 [x] = [-x]

-- SDF actor 'd_1' that implements delay function
--d_1 s = delaySDF [0] s

-- SDF actor 'a_4' that implements 0to1,1to0 function
--a_4 = actor11SDF 1 1 f_count where
 --f_count [0] = [1]
 --f_count [1] = [0]
