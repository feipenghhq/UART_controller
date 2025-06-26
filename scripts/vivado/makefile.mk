############################################################
# makefile for vivado flow
############################################################

#########################################################
# Common variable
#########################################################

REPO_ROOT	?= $(shell git rev-parse --show-toplevel)
SCRIPT_DIR 	?= $(REPO_ROOT)/script/vivado

#########################################################
# Project specific variable
#########################################################

# device
DEVICE ?= xc7a35ticsg324-1L
# project name
PROJECT ?=
# top level name
TOP ?=
# verilog
VERILOG ?=
# verilog define
DEFINE ?=
# xdc
XDC ?=
# project output directory
OUT_DIR ?= outputs


export VIVADO_DEVICE 	= $(DEVICE)
export VIVADO_PRJ 		= $(PROJECT)
export VIVADO_TOP    	= $(TOP)
export VIVADO_VERILOG  	= $(VERILOG)
export VIVADO_DEFINE	= $(DEFINE)
export VIVADO_SEARCH   	= $(SEARCH)
export VIVADO_XDC		= $(XDC)

############################################################
# Commands
############################################################


build: $(OUT_DIR)/$(TOP).bit

$(OUT_DIR)/$(TOP).bit: clean $(OUT_DIR)
	cd $(OUT_DIR) && vivado -mode tcl -source $(SCRIPT_DIR)/vivado_build.tcl | tee build.log

pgm:
	cd $(OUT_DIR) && vivado -mode tcl -source $(SCRIPT_DIR)/vivado_program.tcl | tee program.log

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

clean:
	rm -rf $(OUT_DIR)