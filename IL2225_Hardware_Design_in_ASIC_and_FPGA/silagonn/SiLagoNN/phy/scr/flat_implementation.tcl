source ../phy/scr/read_design.tcl
place_design
ccopt_design
assign_io_pins
route_design
write_db ../phy/db/silagonn.dat
write_netlist ../phy/db/silagonn.v
write_sdf ../phy/db/silagonn.sdf
write_sdc ../phy/db/silagonn.sdc