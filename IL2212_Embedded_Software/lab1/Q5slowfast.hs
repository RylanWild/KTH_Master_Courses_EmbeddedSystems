module Q5slowfast where

import ForSyDe.Shallow

-- Netlist
system s_in = s_out where
    s_out = k_1 c_1 s_in
    c_1 = d_1 s_3
    s_3 = d_2 s_2
    s_2 = a_1 s_out

-- Process
k_1 = kernel11SADF
a_1 = actor11SDF 1 1 f_compare 

-- Adjust the signature of f_compare
f_compare :: [Int] -> [Int]
f_compare = map compareValue
  where
    compareValue x
      | x < 10    = 0
      | x < 20    = 1
      | otherwise = 2

d_2 s = delaySDF [0] s
d_1 :: Signal Int -> Signal (Int, Int, [Int] -> [Int])
d_1 = detector11SADF consume_rate next_state select_scenario initial_state where
    consume_rate = 1
    initial_state = 0 
    k_1_scenario_0 = (3,1, \[x1,x2,x3] -> [x1+x2+x3])
    k_1_scenario_1 = (2,1, \[x1,x2] -> [x1+x2])
    select_scenario 0 = (1, [k_1_scenario_0])
    select_scenario 1 = (1, [k_1_scenario_1])
    -- State transition rules
    next_state 0 [0] = 0 -- Slow: less than 10
    next_state 0 [1] = 0 -- Slow: less than 20
    next_state 0 [2] = 1 -- Slow: 20 or more, change to fast
    next_state 1 [0] = 0 -- Fast: less than 10, change to slow
    next_state 1 [1] = 1 -- Fast: less than 20
    next_state 1 [2] = 1 -- Fast: 20 or more
    next_state _ _   = 0 -- Default case

-- Test signal
s_test :: Signal Int
s_test = signal [4,5,6,8,8,9,9,8,2,4,8,5,2]