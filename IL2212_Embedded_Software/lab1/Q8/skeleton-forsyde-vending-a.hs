module VendingMachine where

import ForSyDe.Shallow

--vendingMachine :: Signal Bool -- Signal of 5 SEK coins
--               -> Signal Bool -- Signal of 10 SEK coins
--               -> Signal (Bool, Bool) -- Signal of (Bottle, Return)

-- Your code
--netlist
system s_in5 s_in10 = (bottle,money) where
 (bottle,money)= k_1 c_1 s_in5 s_in10
 c_1 =d_1 s_in5 s_in10

k_1 = kernel22SADF
--a_1 = actor12SDF 1 1 f_1 where
-- f_1 [1] = ([False],[False])
-- f_1 [] = ([],[])

--a_2 = actor12SDF 1 1 f_2 where
-- f_2 [1] = ([True],[False])
-- f_2 [] = ([],[])

--a_3 = actor12SDF 1 1 f_2 where
-- f_2 [1] = ([True],[True])
-- f_2 [] = ([],[])


d_1 = detector21SADF consume_rate next_state select_scenario initial_state where
 consume_rate = (1,1)

--state0:start
--state1:give a bottle,no change
--state2:give nothing,no change
--state3:give a bottle,give change
 next_state 0 [0] [0] = 0
 next_state 0 [0] [1] = 1
 next_state 0 [1] [0] = 2
 next_state 1 [0] [0] = 0
 next_state 1 [0] [1] = 1
 next_state 1 [1] [0] = 2
 next_state 2 [0] [0] = 2
 next_state 2 [0] [1] = 3
 next_state 2 [1] [0] = 1
 next_state 3 [0] [0] = 0
 next_state 3 [0] [1] = 1
 next_state 3 [1] [0] = 2

 select_scenario 0 = (1, [k_1_scenario_0])
 select_scenario 1 = (1, [k_1_scenario_1])
 select_scenario 2 = (1, [k_1_scenario_2])
 select_scenario 3 = (1, [k_1_scenario_3])
--scenario 0: no water,no money
--scenario 1:water,no money
--scenario 2: water,money
 k_1_scenario_0 = ((1,1),(1,1), \[_][_] -> ([0],[0]))
 k_1_scenario_1 = ((1,1),(1,1), \[_][_] -> ([1],[0]))
 k_1_scenario_2 = ((1,1),(1,1), \[_][_] -> ([0],[0]))
 k_1_scenario_3 = ((1,1),(1,1), \[_][_] -> ([1],[1]))
 initial_state = 0

s_coin5 =  signal [0,1,1,1,0,0]
s_coin10 = signal [1,0,0,0,1,0]
