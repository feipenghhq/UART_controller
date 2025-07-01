# Makefile

REPO = $(shell git rev-parse --show-toplevel)

# defaults
#SIM ?= icarus
SIM ?= verilator
TOPLEVEL_LANG ?= verilog
#WAVES = 1

VERILOG_SOURCES += $(shell find $(REPO)/rtl/uart -name "*.sv")

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = uart_core

# MODULE is the basename of the Python test file
MODULE = test_uart

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim