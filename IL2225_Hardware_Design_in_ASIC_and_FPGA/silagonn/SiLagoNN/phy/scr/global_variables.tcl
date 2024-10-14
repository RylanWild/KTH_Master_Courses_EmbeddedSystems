#This file has info about global variables used during implementation. Ensure that the directories are defined for your current directory and that the path of sdc is correct.

set NUM_CPUS 8
set TOP_NAME drra_wrapper

# Directories
set OUTPUT_DIR "../phy/db"
set RPT_DIR    "../phy/rpt"
set SCR_DIR    "../phy/scr"
set PART_DIR   "../phy/db/part/"
set SRC_DIR    "../syn/db/"

set LEF_FILE "/afs/kth.se/pkg/synopsys/extra_libraries/standard_cell/TSMCHOME/digital/Back_End/lef/tcbn90g_110a/lef/tcbn90g_9lm.lef"
set MMMC_FILE         "${SCR_DIR}/mmmc.tcl"
set NETLIST_FILE       "${SRC_DIR}/${TOP_NAME}.v"
set SDC_FILES          "${SRC_DIR}/${TOP_NAME}.sdc"