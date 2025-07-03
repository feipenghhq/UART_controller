
GIT_ROOT 	= $(shell git rev-parse --show-toplevel)
SCRIPT_DIR 	= $(GIT_ROOT)/scripts/quartus

# project name
PROJECT ?= demo
# top level name
TOP ?= top
# verilog source files
VERILOG += $(GIT_ROOT)/rtl/uart/uart_baud.sv
VERILOG += $(GIT_ROOT)/rtl/uart/uart_rx.sv
VERILOG += $(GIT_ROOT)/rtl/uart/uart_tx.sv
VERILOG += $(GIT_ROOT)/rtl/uart/uart_core.sv
VERILOG += $(GIT_ROOT)/fpga/de2/top.sv
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