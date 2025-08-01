# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 06/25/2025
#
# -------------------------------------------------------------------
# Loop back test for Uart
# -------------------------------------------------------------------

import sys
sys.path.append('../../tb')

import random
import cocotb
from cocotb.triggers import FallingEdge

from Env import *
from AXISBFM import *
from UartBFM import *


async def loopback(dut):
    """
    Loop back the Uart TX to RX
    """
    while True:
        await FallingEdge(dut.clk)
        dut.uart_rxd.value = dut.uart_txd.value

@cocotb.test()
async def loopback_test(dut):
    """
    Uart Loopback test. Takes about half minutes
    """
    num = 32
    cocotb.start_soon(loopback(dut))
    await init(dut)
    for i in range(num):
        value = random.randint(0, 255)
        await axis_send(dut, value)
        data = await axis_receive(dut)
        assert(value == data)
