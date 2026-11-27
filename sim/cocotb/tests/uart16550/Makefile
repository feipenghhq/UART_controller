# Makefile

REPO = $(shell git rev-parse --show-toplevel)

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog


VERILOG_SOURCES += $(shell find $(REPO)/rtl/uart -name "*.sv")
VERILOG_SOURCES += $(shell find $(REPO)/rtl/uart16550 -name "*.sv")

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = apb_uart16550

# MODULE is the basename of the Python test file
MODULE = "test_basic"

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

# Enable waveform generation.
ifeq ($(SIM), verilator)
ifeq ($(WAVES),1)
EXTRA_ARGS += --trace --trace-fst --trace-structs
endif
endif

waveform:
	gtkwave dump.fst &
