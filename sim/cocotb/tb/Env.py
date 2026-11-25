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

def calculate_div(baud_rate, period):
    """
    Calculate the baud div based on clock period in ns
    """
    clock_freq = 1e9 / period
    divisor = round(clock_freq / (16 * baud_rate))
    return divisor

async def generate_reset(dut):
    """
    Generate rst_n pulses.
    """
    dut.rst_n.value = 0
    await Timer(20, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

async def init(dut, period=10, baud=115200, word=3, stop=0, parity=0, even_parity=0, stick_parity=0, break_=0):
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
    dut.tx_data.value  = 0
    dut.uart_rxd.value = 1

    dut.cfg_txen.value = 1
    dut.cfg_rxen.value = 1

    dut.cfg_word.value = word
    dut.cfg_stop.value = stop
    dut.cfg_parity.value = parity
    dut.cfg_even_parity.value = even_parity
    dut.cfg_stick_parity.value = stick_parity
    dut.cfg_break.value = break_

    dut.cfg_div.value = calculate_div(baud, period)

    # clock and reset
    cocotb.start_soon(Clock(dut.clk, period, unit = 'ns').start()) # clock
    await generate_reset(dut)
