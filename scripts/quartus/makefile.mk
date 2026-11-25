#########################################################
# Makefile for quartus flow
#########################################################

#########################################################
# Common variable
#########################################################

GIT_ROOT 	= $(shell git rev-parse --show-toplevel)
SCRIPT_DIR 	= $(GIT_ROOT)/scripts/quartus

#########################################################
# Project specific variable
#########################################################

# device part
PART ?= EP2C35F672C7
# device family
FAMILY ?= Cyclone II
# project name
PROJECT ?=
# top level name
TOP ?=
# verilog source files
VERILOG ?=
# verilog define
DEFINE ?=
# sdc files
SDC	?=
# pin assignment files
PIN ?=
# project output directory
OUT_DIR ?= outputs

# Quartus installations (override these for a different machine).
QUARTUS_13_ROOT ?= $(HOME)/altera/13.0sp1/quartus
QUARTUS_24_ROOT ?= $(HOME)/intelFPGA_lite/24.1std/quartus

# Cyclone II uses Quartus 13.0sp1. Override with QUARTUS_VERSION=13 or 24.
ifneq ($(filter EP2C%,$(PART)),)
QUARTUS_VERSION ?= 13
else
QUARTUS_VERSION ?= 24
endif

ifeq ($(QUARTUS_VERSION),13)
QUARTUS_ROOT := $(QUARTUS_13_ROOT)
# Avoid the parallel Fitter stall observed with 13.0sp1 on this host.
QUARTUS_PROCESSORS ?= 1
else ifeq ($(QUARTUS_VERSION),24)
QUARTUS_ROOT := $(QUARTUS_24_ROOT)
else
$(error Unsupported QUARTUS_VERSION '$(QUARTUS_VERSION)'; use 13 or 24)
endif

QUARTUS_BIN := $(QUARTUS_ROOT)/bin
export QUARTUS_PROCESSORS


export QUARTUS_PART 	= $(PART)
export QUARTUS_FAMILY 	= $(FAMILY)
export QUARTUS_PRJ 		= $(PROJECT)
export QUARTUS_TOP    	= $(TOP)
export QUARTUS_VERILOG  = $(VERILOG)
export QUARTUS_SEARCH   = $(SEARCH)
export QUARTUS_SDC		= $(SDC)
export QUARTUS_QIP		= $(QIP)
export QUARTUS_PIN		= $(PIN)
export QUARTUS_DEFINE	= $(DEFINE)

SOF = $(OUT_DIR)/$(PROJECT).sof

#########################################################
# Build process
#########################################################

build: sof
sof: $(SOF)

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(SOF): $(OUT_DIR)
	cd $(OUT_DIR) && "$(QUARTUS_BIN)/quartus_sh" --64bit -t $(SCRIPT_DIR)/quartus_build.tcl

sta: $(OUT_DIR)
	cd $(OUT_DIR) && "$(QUARTUS_BIN)/quartus_sta" --64bit -t $(SCRIPT_DIR)/quartus_sta.tcl

pgm: $(SOF)
	"$(QUARTUS_BIN)/quartus_pgm" --mode JTAG -o "p;$(SOF)"

pgmonly:
	"$(QUARTUS_BIN)/quartus_pgm" --mode JTAG -o "p;$(SOF)"

clean:
	rm -rf $(OUT_DIR)
