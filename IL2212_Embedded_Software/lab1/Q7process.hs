module SWITCH where

import ForSyDe.Shallow

-- Netlist
system s_in = (s_4,s_5) where
  s_4 = d_1 s_3
  s_1 = a_1 s_in s_4  
  s_2 = a_2 s_1
  s_5 = a_5 s_in
  s_3 = a_3 s_2 s_5

--process
a_1 s1 s2 = actor21SDF (1,1) 1 add s1 s2
add [x] [y] = [x + y]

a_2  = actor11SDF 1 1 f_1 where
 f_1 [x] = [2*x]

a_3 s1 s2 = actor21SDF (1,1) 1 add s1 s2

d_1 s = delaySDF [0] s

a_5  = actor11SDF 1 1 f_2 where
 f_2 [x] = [x+1]

