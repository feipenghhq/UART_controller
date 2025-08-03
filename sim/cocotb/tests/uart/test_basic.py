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

@cocotb.test()
async def test_transmit(dut):
    """
    Test transmit path. Takes about half minutes
    """
    bfm = UartBFM(115200)
    bfm.connect(dut.clk, dut.uart_txd, dut.uart_rxd)
    num = 32
    await init(dut)
    for i in range(num):
        value = random.randint(0, 255)
        rcv = cocotb.start_soon(bfm.receive())
        await axis_send(dut, value)
        data = await rcv
        assert(value == data)

@cocotb.test()
async def test_receive(dut):
    """
    Test receive path. Takes about half minutes
    """
    bfm = UartBFM(115200)
    bfm.connect(dut.clk, dut.uart_txd, dut.uart_rxd)
    num = 32
    await init(dut)
    for i in range(num):
        value = random.randint(0, 255)
        rcv = cocotb.start_soon(axis_receive(dut))
        await bfm.send(value)
        data = await rcv
        assert(value == data)
