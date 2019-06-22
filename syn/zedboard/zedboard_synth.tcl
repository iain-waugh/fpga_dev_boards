# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Project TCL command file
# See UG834 and UG894 for details


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Read TCL script command-line arguments
set OUT_DIR      [ lindex $argv 0 ]
set SYNTH_DCP    [ lindex $argv 1 ]
set DEVICE       [ lindex $argv 2 ]
set PROJECT      [ lindex $argv 3 ]


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Create the Vivado project
#   UG834 v2018.3, page 331
#   Options used are:
#     -in_memory : Create an in-memory project
create_project -in_memory -part ${DEVICE}

set_property target_language VHDL [ current_project ]


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Load the project's source files
#   UG834 v2018.3, page 1146
#   Options used are:
#     (none)

# Common project files
#   Note: The Spartan 6 "BASE_PLL" in clk_gen_s6 works in a Zynq, too
read_vhdl "../../src/common/pkg/util_pkg.vhd"
read_vhdl "../../src/common/sync_sl/sync_sl.vhd"
read_vhdl "../../src/common/delay_sl/delay_sl.vhd"
read_vhdl "../../src/common/clk_gen/clk_gen_s6.vhd"
read_vhdl "../../src/common/pulse_gen/pulse_gen.vhd"
read_vhdl "../../src/common/debounce/debounce.vhd"
read_vhdl "../../src/common/fifo/fifo_sync.vhd"

# Hello World
read_vhdl "../../src/hello_world/hello_world.vhd"

# VGA Output
read_vhdl "../../src/vga_driver/vga_driver.vhd"

# Main file
read_vhdl "../../src/zedboard.vhd"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Read physical and timing constraints from one of more files
#   UG834 v2018.3, page 1148
#   Options used are:
#     (none)
read_xdc ${DEVICE}.xdc


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Synthesize a design using Vivado Synthesis and open that design
# synth_design [-generic G_BLAHBLAH] -top <TOP_LEVEL> -part <PART>
#   UG834 v2018.3, page 1675
#   Options used are:
#     -top  : Specify the top module name
#     -part : Target part
synth_design -top ${PROJECT} -part ${DEVICE}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Write a checkpoint of the current design.
#   UG834 v2018.3, page 1771
#   Options used are:
#     -force : overwrite existing
write_checkpoint ${OUT_DIR}/${SYNTH_DCP}.dcp -force
