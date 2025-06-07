# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Project TCL command file
# See UG834 and UG894 for details


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Read TCL script command-line arguments
set OUT_DIR    [ lindex $argv 0 ]
set SYNTH_DCP  [ lindex $argv 1 ]
set PART       [ lindex $argv 2 ]
set PROJECT    [ lindex $argv 3 ]


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Create the Vivado project
#   UG834 v2018.3, page 331
#   Options used are:
#     -in_memory : Create an in-memory project
create_project -in_memory -part ${PART}

set_property target_language VHDL [ current_project ]


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Load the project's source files
#   UG834 v2018.3, page 1146
#   Options used are:
#     (none)

# Supporting file
read_vhdl "../../src/common/pkg/util_pkg.vhd"

# Main file
read_vhdl "../../src/${PROJECT}.vhd"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Read physical and timing constraints from one of more files
#   UG834 v2018.3, page 1148
#   Options used are:
#     (none)
read_xdc ${PART}.xdc
# read_xdc ${PART}_timing.xdc


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Synthesize a design using Vivado Synthesis and open that design
# synth_design [-generic G_BLAHBLAH] -top <TOP_LEVEL> -part <PART>
#   UG834 v2018.3, page 1675
#   Options used are:
#     -top  : Specify the top module name
#     -part : Target part
synth_design -top ${PROJECT} -part ${PART}

report_utilization -file ${OUT_DIR}/${PROJECT}_synth_util.txt


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Write a checkpoint of the current design.
#   UG834 v2018.3, page 1771
#   Options used are:
#     -force : overwrite existing
write_checkpoint ${OUT_DIR}/${SYNTH_DCP}.dcp -force
