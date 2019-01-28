# =========================================================================
# Makefile syntax:
# variable = value
# variable ?= value (if value isn't already set, such as an environment variable)
#
# target:  dependency1 dependency2 ...
#    <tab> command

# =========================================================================
# Key project names and directories
PROJECT = ax309_board
DEVICE  = xc6slx9-2ftg256


# =========================================================================
# Xilinx ISE flags - see UG628 v14.7
NGD_FLAGS = -intstyle xflow -dd ./__ngo -aul -aut -verbose
MAP_FLAGS = -intstyle xflow -ol high -detail
PAR_FLAGS = -intstyle xflow -ol high
BIT_FLAGS = -intstyle xflow -w


# =========================================================================
# Build recipes
# 00 - Make everything
# 01 - Synthesis
# 02 - NGD (Xillinx Native Generic Database)
# 03 - MAP
# 04 - P&R (Place and Route)
# 05 - BitGen (Bitstream Generation)


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 00 - Make everything
all: synth ngd map ngd bit

clean: clean_bit

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 01 - Synthesis
.PHONY: synth
synth: ${PROJECT}.ngc ${PROJECT}.prj
${PROJECT}.ngc : ../../src/${PROJECT}.vhd
	@echo
	@echo
	@echo '## --- Synthesis --- ##'
	@echo
	xst -intstyle ise -ifn ${PROJECT}.xst -ofn ${PROJECT}.srp

clean_synth:
	@rm -fR xst _xmsgs
	@rm -f ${PROJECT}.srp ${PROJECT}.ngc
	@rm -f ${PROJECT}.lso ${PROJECT}_xst.xrpt

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 02 - NGD (Xillinx Native Generic Database)
.PHONY: ngd
ngd: ${PROJECT}.ngd
${PROJECT}.ngd : ${PROJECT}.ngc ${DEVICE}.ucf

# Commands to build the '.ngd'
	@echo
	@echo
	@echo '## --- NGD Build --- ##'
	@echo
	# ngdbuild [options] design_name [ngd_file[.ngd]]
	# UG628 v14.7, page 74
	ngdbuild ${NGD_FLAGS} -p ${DEVICE} -uc ${DEVICE}.ucf ${PROJECT}.ngc ${PROJECT}.ngd

clean_ngd: clean_synth
	@rm -fR __ngo xlnx_auto_0_xdb
	@rm -f ${PROJECT}.bld ${PROJECT}.ngd ${PROJECT}_ngdbuild.xrpt

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 03 - MAP
.PHONY: map
map: ${PROJECT}_map.ncd
${PROJECT}_map.ncd : ${PROJECT}.ngd

# Commands to build the '.map'
	@echo
	@echo
	@echo '## --- Device Mapping --- ##'
	@echo
	# map [options] infile[.ngd] [pcf_file.pcf]
	# UG628 v14.7, page 84
	map ${MAP_FLAGS} -p ${DEVICE} -o ${PROJECT}_map.ncd ${PROJECT}.ngd ${PROJECT}.pcf

clean_map: clean_ngd
	@rm -f ${PROJECT}.pcf ${PROJECT}_map.map ${PROJECT}_map.mrp
	@rm -f ${PROJECT}_map.ncd ${PROJECT}_map.ngm ${PROJECT}_map.xrpt
	@rm -f ${PROJECT}_summary.xml ${PROJECT}_usage.xml

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 04 - P&R (Place and Route)
.PHONY: par
par: ${PROJECT}.ncd
${PROJECT}.ncd : ${PROJECT}_map.ncd

# Commands to build the '.par'
	@echo
	@echo
	@echo '## --- Place and Route --- ##'
	@echo
	# par [options] infile[.ncd] outfile [pcf_file[.pcf]]
	# UG628 v14.7, page 116
	par ${PAR_FLAGS} ${PROJECT}_map.ncd ${PROJECT}.ncd ${PROJECT}.pcf

	@echo
	@echo
	@echo '## --- Analyse Timing --- ##'
	@echo
	# trce [options] design[.ncd] [constraint[.pcf]]
	# UG628 v14.7, page 180
	trce ${TRCE_FLAGS} ${PROJECT}.ncd -o ${PROJECT}.twr ${PROJECT}.pcf

clean_par: clean_map
	@rm -f ${PROJECT}.ncd ${PROJECT}.pad ${PROJECT}.par ${PROJECT}.ptwx
	@rm -f ${PROJECT}.twr ${PROJECT}.twx ${PROJECT}.unroutes ${PROJECT}.xpi
	@rm -f ${PROJECT}_pad.csv ${PROJECT}_pad.txt ${PROJECT}_par.xrpt
	@rm -f par_usage_statistics.html


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 05 - BitGen (Bitstream Generation)
.PHONY: bit
bit: ${PROJECT}.bit
${PROJECT}.bit : ${PROJECT}.ncd

# Commands to build the '.bit'
	@echo
	@echo
	@echo '## --- BitGen --- ##'
	@echo
	# bitgen [options] infile[.ncd] [outfile] [pcf_file.pcf]
	# UG628 v14.7, page 223
	bitgen -f ${PROJECT}_impact.cmd ${PROJECT}.ncd ${PROJECT}.bit

clean_bit: clean_par
	@rm -f ${PROJECT}.bgn ${PROJECT}.bit ${PROJECT}.drc
	@rm -f ${PROJECT}_bitgen.xwbt webtalk.log
