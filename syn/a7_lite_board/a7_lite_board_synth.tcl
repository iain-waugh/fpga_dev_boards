# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Project TCL command file
# See UG835 and UG894 for details


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Read TCL script command-line arguments
set OUT_DIR    [ lindex $argv 0 ]
set SYNTH_DCP  [ lindex $argv 1 ]
set DEVICE     [ lindex $argv 2 ]
set PROJECT    [ lindex $argv 3 ]

set IP_FOLDER  [ eval pwd ]/ip

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Create the Vivado project
#   UG835 v2018.3, page 331
#   Options used are:
#     -in_memory : Create an in-memory project
create_project -in_memory -part ${DEVICE}

set_property target_language VHDL [ current_project ]


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Build the IP cores
#   UG835 v2024.1, p1781, p1863, p1242, p1827
#   Options used are:
#     (none)

set_property target_language VHDL [ current_project ]
set_property IP_REPO_PATHS ${IP_FOLDER} [ current_project ]
update_ip_catalog
read_ip ip/mig_7series_0/mig_7series_0.xci
synth_ip [ get_ips ]


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Load the project's source files
#   UG835 v2018.3, page 1146
#   Options used are:
#     (none)

# Project HDL files
read_vhdl "../../src/common/pkg/util_pkg.vhd"
read_vhdl "../../src/common/delay_sl/delay_sl.vhd"
read_vhdl "../../src/common/sync_sl/sync_sl.vhd"
read_vhdl "../../src/common/pulse_gen/pulse_gen.vhd"
read_vhdl "../../src/common/clk_gen/clk_gen_z7.vhd"
read_vhdl "../../src/hello_world/hello_world.vhd"

# Load IP
read_checkpoint "./ip/mig_7series_0/mig_7series_0.dcp"

# Top-level file
read_vhdl "../../src/${PROJECT}.vhd"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Read physical and timing constraints from one of more files
#   UG835 v2018.3, page 1148
#   Options used are:
#     (none)
read_xdc ${DEVICE}_pins.xdc
read_xdc ${DEVICE}_timing.xdc


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Synthesize a design using Vivado Synthesis and open that design
# synth_design [-generic G_BLAHBLAH] -top <TOP_LEVEL> -part <PART>
#   UG835 v2018.3, page 1675
#   Options used are:
#     -top  : Specify the top module name
#     -part : Target part
synth_design -top ${PROJECT} -part ${DEVICE}

report_utilization -file ${OUT_DIR}/${PROJECT}_synth_util.txt


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Write a checkpoint of the current design.
#   UG835 v2018.3, page 1771
#   Options used are:
#     -force : overwrite existing
write_checkpoint ${OUT_DIR}/${SYNTH_DCP}.dcp -force
