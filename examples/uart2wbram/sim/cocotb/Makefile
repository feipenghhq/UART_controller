# Makefile

REPO = $(shell git rev-parse --show-toplevel)

# defaults
SIM ?= icarus
SIM ?= verilator
TOPLEVEL_LANG ?= verilog
WAVES = 1

VERILOG_SOURCES += $(shell find $(REPO)/rtl/uart -name "*.sv")
VERILOG_SOURCES += $(shell find $(REPO)/rtl/bridge -name "*.sv")
VERILOG_SOURCES += $(REPO)/examples/uart2wbram/rtl/uart2wbram.sv
VERILOG_SOURCES += $(REPO)/examples/uart2wbram/rtl/wbram1rw.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = uart2wbram

# MODULE is the basename of the Python test file
MODULE = test_uart2wbram

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

waveform:
	gtkwave sim_build/$(TOPLEVEL).fst &
