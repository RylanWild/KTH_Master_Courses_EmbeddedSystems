#Set the source directory
set SOURCE_DIR ../../rtl; 

vlib work
vlib dware

#Compile dware libraries into "dware"
set hierarchy_files [split [read [open ${SOURCE_DIR}/dware_hierarchy.txt r]] "\n"]
foreach filename [lrange ${hierarchy_files} 0 end-1] {
	vcom -2008 -work dware ${SOURCE_DIR}/${filename}
}
set hierarchy_files [split [read [open ${SOURCE_DIR}/dware_hierarchy_verilog.txt r]] "\n"]
foreach filename [lrange ${hierarchy_files} 0 end-1] {
    vlog -v2001 -work dware ${SOURCE_DIR}/${filename}
}


#Compile silagonn design into "work"

#Compile const_package.vhd in the current directory

#Compile testbench.vhd in the current directory

#Open the simulation

run 0 ns;
#Load the waveform 
do wave.do
#Run simulation
run 735ns;
