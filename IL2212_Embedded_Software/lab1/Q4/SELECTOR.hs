module SELECTOR where
import ForSyDe.Shallow

-- Netlist
system_select s_inT s_inF s_select = s_out where
    s_out = k_1 c_1 s_inT s_inF 
    c_1 = d_1 s_select

-- Process
k_1 = kernel21SADF

d_1 = detector11SADF consume_rate next_state select_scenario initial_state where
    consume_rate = 1
    -- Next State Function 'next_state' 
    next_state _ [0] = 1
    next_state _ [1] = 0

    -- Definition of scenarios
    -- - Scenario 0: true
    k_1_scenario_0 = ((1,0), 1, \[x][] -> [x])
    -- - Scenario 1: false
    k_1_scenario_1 = ((0,1), 1, \[][x] -> [x])
    -- Function for Selection of scenarios
    select_scenario 0 = (1, [k_1_scenario_0])
    select_scenario 1 = (1, [k_1_scenario_1])
    -- Initial State
    initial_state = 0
