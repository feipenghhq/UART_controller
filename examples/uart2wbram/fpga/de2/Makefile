
GIT_ROOT 	= $(shell git rev-parse --show-toplevel)
SCRIPT_DIR 	= $(GIT_ROOT)/scripts/quartus

# project name
PROJECT ?= fpga_uart2wb_ram
# top level name
TOP ?= top
# verilog source files
VERILOG += $(GIT_ROOT)/rtl/uart/uart_baud.sv
VERILOG += $(GIT_ROOT)/rtl/uart/uart_rx.sv
VERILOG += $(GIT_ROOT)/rtl/uart/uart_tx.sv
VERILOG += $(GIT_ROOT)/rtl/uart/uart_core.sv
VERILOG += $(GIT_ROOT)/rtl/bridge/uart2wb.sv
VERILOG += $(GIT_ROOT)/examples/uart2wbram/rtl/uart2wbram.sv
VERILOG += $(GIT_ROOT)/examples/uart2wbram/rtl/wbram1rw.sv
VERILOG += $(GIT_ROOT)/examples/uart2wbram/fpga/de2/top.sv
# verilog include directory
SEARCH  ?=
# verilog define
DEFINE ?=
# sdc files
SDC	?= $(PWD)/timing.sdc
# pin assignment files
PIN ?= $(PWD)/pin.tcl
# project output directory
OUT_DIR ?= outputs

include $(GIT_ROOT)/scripts/quartus/makefile.mk
