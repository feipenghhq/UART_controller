# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 07/31/2025
#
# -------------------------------------------------------------------
# Environment
# -------------------------------------------------------------------

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock

async def generate_reset(dut):
    """
    Generate rst_n pulses.
    """
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

async def init(dut, period=10, baud=115200):
    """
    Initialize the environment:
        - setup clock, and reset the design
        - setup uart config.
            - baud rate: 115200
    Parameter:
        - period (int): Clock Period in ns
        - baud (int): Baud rate
    """
    # Set default signal value
    dut.tx_valid.value = 0
    dut.tx_data.value = 0
    dut.cfg_txen.value = 1
    dut.cfg_rxen.value = 1
    dut.cfg_nstop.value = 0
    dut.cfg_div.value = int(1000000000 / (baud * period))
    # clock and reset
    cocotb.start_soon(Clock(dut.clk, period, units = 'ns').start()) # clock
    await generate_reset(dut)
