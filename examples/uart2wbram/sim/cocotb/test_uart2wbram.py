# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 08/02/2025
#
# -------------------------------------------------------------------
# Test uart2wbram
# -------------------------------------------------------------------

import sys

sys.path.append('../../../../sim/cocotb/tb')
sys.path.append('../../../../sim/cocotb/bfm')

import random

import cocotb
from cocotb.clock import Clock
from Env import generate_reset
from UartBFM import UartBFM
from UartBridgeBFM import UartBridgeBFM


@cocotb.parametrize(stall=[0, 1, 2])
async def test_read(dut, baud=115200, stall=0):
    """
    Test Uart Host read (single)
    """
    period=10 # Fix to 10 as RTL use 100MHz clock
    uart = UartBFM(baud)
    uart.connect(dut.clk, dut.uart_txd, dut.uart_rxd)
    cocotb.start_soon(Clock(dut.clk, period, units = 'ns').start()) # clock
    await generate_reset(dut)
    addr = random.randint(0, 255)
    data = random.randint(0, 65535)
    # write
    await UartBridgeBFM.write_cmd(uart, addr, data, abyte=1)
    # read
    uart_data = await UartBridgeBFM.read_cmd(uart, addr, abyte=1)
    assert(data == uart_data)
