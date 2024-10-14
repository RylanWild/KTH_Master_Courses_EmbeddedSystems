module Q4SDFG where
import ForSyDe.Shallow
import SELECTOR
import SWITCHER

-- Netlist
system s_in s_ctrl= s_out where
    (s_1,s_3)= system_switch s_in s_ctrl
    s_2 = c s_1
    s_4 = d s_3
    s_out = system_select s_2 s_4 s_ctrl  

c = actor11SDF 1 1 f_2 where
    f_2 [x] = [x]

-- negation 
d = actor11SDF 1 1 f_3 where
    f_3 [x] = [-x]

    --s_test_1=signal [1,2,3,4,5]
    --s_control_1=signal [1,0,1,0,1]
