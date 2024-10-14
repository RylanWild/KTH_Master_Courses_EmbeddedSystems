module VendingMachine where

import ForSyDe.Shallow


data Coin = C5 | C10 deriving (Show, Eq, Ord)
data Bottle = B deriving (Show, Eq, Ord)
data Return = R deriving (Show, Eq, Ord)
type Coin_Event = AbstExt Coin
type Bottle_Event = AbstExt Bottle
type Return_Event = AbstExt Return
--vendingMachine  :: Signal Coin_Event-- Signal of Coins
  --              -> Signal (Bottle_Event, Return_Event)
    -- Signal of (Bottle, Ret


s_testLine = signal [Prst C10, Prst C5, Prst C10, Prst C5, Abst, Prst C5, Prst C10, Abst, Prst C10, Prst C5]
--s_test1 = signal [True, False, True, False, False, False, True, False, True, False]
--s_test2 = signal [False, True, False, True, False, True, False, False, False, True]

vendingMachine s_in = s_out where
    s_out = zipSY bottle_B return_R
    bottle_B = intToB bottle
    return_R = intToR return
    (bottle,return) = k_1 c_1 s_in5 s_in10
    c_1 = d_1 s_in5 s_in10
    s_in5 = boolToInt s_5
    s_in10 = boolToInt s_10
    s_5 = c5toInt s_in
    s_10 = c10toInt s_in

intToBool = mapSY (\x -> x /= 0)
intToR = mapSY (\x -> if x == 0 then Abst else Prst R)
intToB = mapSY (\x -> if x == 0 then Abst else Prst B)

boolToInt = mapSY (\x -> if x then 1 else 0)

c10toInt = mapSY (\x -> x == Prst C10)
c5toInt = mapSY (\x -> x == Prst C5)

k_1 = kernel22SADF
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
s_coin = signal [Prst C10, Prst C5, Prst C5, Prst C5, Prst C10, Abst]



