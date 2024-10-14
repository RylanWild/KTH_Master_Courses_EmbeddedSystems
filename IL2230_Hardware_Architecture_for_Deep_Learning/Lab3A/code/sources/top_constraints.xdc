
create_clock -period 10.000 -name clk -waveform {0 5.000} [get_ports -filter { NAME =~  "*clk*" && DIRECTION == "IN" }]

set_false_path -from [get_ports rst_n]
