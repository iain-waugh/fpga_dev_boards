PROJECT ?= a7_lite_board
DEVICE  ?= xc7a35tfgg484-1
OUT_DIR  = ${PROJECT}/${DEVICE}

SYNTH_NAME = ${PROJECT}_synth
ROUTE_NAME = ${PROJECT}_route

# =========================================================================
# Xilinx Vivado build flags are in the respective '.tcl' files
# See UG894 for details


# =========================================================================
# Build recipes
# 00 - Miscellaneous 'make' recipes
#
# 01a - Load design/cores: read_vhdl xxx.vhd  read_checkpoint xxx.dcp
# 01b - Synthesis: synth_design
#
# 02a - Optimisation: opt_design -verbose
# 02b - Place: place_design
# 02c - Route: route_design
#
# 03 - BitGen (Bitstream Generation): write_bitstream


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 00a - Make everything
# Typing 'make' by itself runs the first target entry in the makefile
all: synth route

clean:
	rm -fR .Xil ${OUT_DIR}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 00b - Preprocess the environment to be sure files are in place
${DEVICE}.xdc:
	touch ${DEVICE}.xdc


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 01 - Synthesis
.PHONY: synth
synth: ${OUT_DIR}/${SYNTH_NAME}.dcp
${OUT_DIR}/${SYNTH_NAME}.dcp : ../../src/${PROJECT}.vhd ${SYNTH_NAME}.tcl ${DEVICE}.xdc

# Invoke the synthesis script
	@echo
	@echo
	@echo '## ---  Running Synthesis  --- ##'
	@echo
	mkdir -p ${OUT_DIR}
	vivado -mode batch -source ${SYNTH_NAME}.tcl \
		-log ${OUT_DIR}/${SYNTH_NAME}.log -nojournal \
		-tclargs ${OUT_DIR} ${SYNTH_NAME} ${DEVICE} ${PROJECT}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 02 - Optimise, Place and Route: route_design
.PHONY: route
route: ${OUT_DIR}/${ROUTE_NAME}.dcp
${OUT_DIR}/${ROUTE_NAME}.dcp : ${OUT_DIR}/${SYNTH_NAME}.dcp ${ROUTE_NAME}.tcl

# Invoke the opt, place and route script
	@echo
	@echo
	@echo '## ---  Running Place and Route  --- ##'
	@echo
	vivado -mode batch -source ${ROUTE_NAME}.tcl \
		-log ${OUT_DIR}/${ROUTE_NAME}.log -nojournal \
		-tclargs ${OUT_DIR} ${SYNTH_NAME} ${ROUTE_NAME} ${PROJECT}

# The route TCL file generates file of part usage per cell
# Parse them into something simpler
#	python parse_usage.py ${OUT_DIR}
