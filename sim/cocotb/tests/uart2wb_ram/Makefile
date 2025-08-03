# Makefile

REPO = $(shell git rev-parse --show-toplevel)

# defaults
SIM ?= icarus
SIM ?= verilator
TOPLEVEL_LANG ?= verilog
WAVES = 1

VERILOG_SOURCES += $(shell find $(REPO)/rtl/uart -name "*.sv")
VERILOG_SOURCES += $(shell find $(REPO)/rtl/uart_debug -name "*.sv")
VERILOG_SOURCES += $(REPO)/rtl/fpga_examples/wbram1rw.sv
VERILOG_SOURCES += $(REPO)/rtl/fpga_examples/fpga_uart2wb_ram.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = fpga_uart2wb_ram

# MODULE is the basename of the Python test file
MODULE = test_uart2wb_ram

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

waveform:
	gtkwave sim_build/$(TOPLEVEL).fst &
