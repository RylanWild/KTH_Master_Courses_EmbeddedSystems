#Set the source directory
set SOURCE_DIR ../../rtl; 
set TB_DIR ../../tb/vec_add;                # testbench directory
vlib work
vlib dware

#Compile dware libraries into "dware"
set hierarchy_files [split [read [open ${SOURCE_DIR}/dware_hierarchy.txt r]] "\n"]
foreach filename [lrange ${hierarchy_files} 0 end-1] {
	vcom -2008 -work dware ${SOURCE_DIR}/${filename}
}
set hierarchy_files [split [read [open ${SOURCE_DIR}/dware_hierarchy_verilog.txt r]] "\n"]
foreach filename [lrange ${hierarchy_files} 0 end-1] {
    vlog -work dware ${SOURCE_DIR}/${filename}
}

#Compile silagonn design into "work"
set hierarchy_files [split [read [open ${SOURCE_DIR}/silagonn_hierarchy.txt r]] "\n"]
foreach filename [lrange ${hierarchy_files} 0 end-1] {
	vcom -2008 -work work ${SOURCE_DIR}/${filename}
}

#Compile ./const_package.vhd 
	vcom -2008 -work work ${TB_DIR}/const_package.vhd 

#Compile ./testbench.vhd 
	vcom -2008 -work work ${TB_DIR}/testbench.vhd 

#Open the simulation
vsim -voptargs=+acc work.testbench
add wave sim:/testbench/*

#Load the waveform. You may see some errrors in loading the waveform that it cannot find some of the signals mentioned in the wave.do file. This is okay.
do wave.do

#Run simulation for 1000ns
run 1000 ns;
