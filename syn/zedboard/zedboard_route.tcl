# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
## Project TCL command file
# See UG834 and UG894 for details


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Read TCL script command-line arguments
set OUT_DIR      [ lindex $argv 0 ]
set SYNTH_DCP    [ lindex $argv 1 ]
set ROUTE_DCP    [ lindex $argv 2 ]
set PROJECT      [ lindex $argv 3 ]


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Open a design checkpoint in a new project
#   UG834 v2018.3, page 1038
#   Options used are:
#     (none)
open_checkpoint ${OUT_DIR}/${SYNTH_DCP}.dcp


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Optimize the current netlist. This will perform the retarget, propconst,
# sweep and bram_power_opt optimizations by default.
#   UG834 v2018.3, page 1068
#   Options used are:
#     (none)
opt_design


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Automatically place ports and leaf-level instances.
#   UG834 v2018.3, page 1085
#   Options used are:
#     (none)
place_design


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Route the current design
#   UG834 v2018.3, page 1483
#   Options used are:
#     (none)
route_design


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check the design for possible timing problems.
#   UG834 v2018.3, page 123
#   Options used are:
#     -file : Filename to output results to.
check_timing -file ${OUT_DIR}/${ROUTE_DCP}_timing.txt


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Write a checkpoint of the current design.
#   UG834 v2018.3, page 1771
#   Options used are:
#     -force : overwrite existing
write_checkpoint ${OUT_DIR}/${ROUTE_DCP}.dcp -force


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Write a bitstream for the current design.
#   UG834 v2018.3, page 1758
#   Options used are:
#     -force : Overwrite existing file
write_bitstream ${PROJECT}.bit -force
