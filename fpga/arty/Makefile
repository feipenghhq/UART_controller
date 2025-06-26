
GIT_ROOT 	= $(shell git rev-parse --show-toplevel)
SCRIPT_DIR 	= $(GIT_ROOT)/scripts/vivado

# FPGA Device
DEVICE ?= xc7a35ticsg324-1L
# project name
PROJECT ?= demo
# top level name
TOP ?= top
# verilog source files
VERILOG += $(GIT_ROOT)/rtl/uart/uart_baud.sv
VERILOG += $(GIT_ROOT)/rtl/uart/uart_rx.sv
VERILOG += $(GIT_ROOT)/rtl/uart/uart_tx.sv
VERILOG += $(GIT_ROOT)/rtl/uart/uart_core.sv
VERILOG += $(GIT_ROOT)/fpga/arty/top.sv
# verilog include directory
SEARCH  ?=
# verilog define
DEFINE ?=
# sdc files
XDC += $(PWD)/timing.xdc
# pin assignment files
XDC += $(PWD)/pin.xdc
# project output directory
OUT_DIR ?= outputs

include $(GIT_ROOT)/scripts/vivado/makefile.mk