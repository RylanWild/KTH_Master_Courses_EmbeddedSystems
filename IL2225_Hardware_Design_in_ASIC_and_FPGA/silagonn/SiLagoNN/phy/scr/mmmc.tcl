create_library_set \
    -name LIBSET_TC \
    -timing [list /afs/it.kth.se/pkg/synopsys/extra_libraries/standard_cell/TSMC/tcbn90g_110a/Front_End/timing_power/tcbn90g_110a/tcbn90gtc.lib]
create_library_set \
    -name LIBSET_BC \
    -timing [list /afs/it.kth.se/pkg/synopsys/extra_libraries/standard_cell/TSMC/tcbn90g_110a/Front_End/timing_power/tcbn90g_110a/tcbn90gbc.lib]
create_library_set \
    -name LIBSET_WC \
    -timing [list /afs/it.kth.se/pkg/synopsys/extra_libraries/standard_cell/TSMC/tcbn90g_110a/Front_End/timing_power/tcbn90g_110a/tcbn90gwc.lib]

create_rc_corner \
    -name rc_best \
    -pre_route_res 1 \
    -post_route_res 1 \
    -pre_route_cap 1 \
    -post_route_cap 1 \
    -post_route_cross_cap 1 \
    -post_route_clock_res 0 \
    -post_route_clock_cap 0 

create_rc_corner \
    -name rc_worst \
    -pre_route_res 1 \
    -post_route_res 1 \
    -pre_route_cap 1 \
    -post_route_cap 1 \
    -post_route_cross_cap 1 \
    -post_route_clock_res 0 \
    -post_route_clock_cap 0 

create_timing_condition \
    -name cond_worst \
    -library_sets LIBSET_WC \
    -opcond_library "wc" 

create_timing_condition \
    -name cond_best \
    -library_sets LIBSET_BC \
    -opcond_library "bc" 

create_delay_corner \
    -name WC_dc \
    -timing_condition {cond_worst} \
    -rc_corner rc_worst
create_delay_corner \
    -name BC_dc \
    -timing_condition {cond_best} \
    -rc_corner rc_best
puts [pwd]
create_constraint_mode -name CM -sdc_files [list ../syn/constraints.sdc]
create_analysis_view -name AV_WC_RCWORST -constraint_mode CM -delay_corner WC_dc
create_analysis_view -name AV_BC_RCBEST -constraint_mode CM -delay_corner BC_dc
set_analysis_view -setup "AV_WC_RCWORST" -hold "AV_WC_RCWORST AV_BC_RCBEST"