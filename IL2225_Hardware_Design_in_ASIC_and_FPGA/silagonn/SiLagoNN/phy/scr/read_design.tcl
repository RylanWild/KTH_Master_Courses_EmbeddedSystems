source ../phy/scr/global_variables.tcl
set_multi_cpu_usage -local_cpu ${NUM_CPUS} -cpu_per_remote_host 1 -remote_host 0 -keep_license true
set_distributed_hosts -local

set_db init_power_nets {VDD}
set_db init_ground_nets {VSS}
read_mmmc ${MMMC_FILE}
read_physical -lef ${LEF_FILE}
read_netlist ${NETLIST_FILE}
init_design