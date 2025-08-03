# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 08/02/2025
#
# -------------------------------------------------------------------
# Test uart2wb
# -------------------------------------------------------------------

import sys
sys.path.append('../../tb')

import random
import cocotb
from cocotb.regression import TestFactory

from Env import *
from UartBFM import *
from UartDebugBFM import *
from WbDeviceBFM import *


#@cocotb.test()
async def test_write(dut, baud=115200, period=20, stall=0):
    """
    Test Uart Host write (single)
    """
    wb = WbDeviceBFM(dut, 16, 16, default=True)
    uart = UartBFM(baud)
    uart.connect(dut.clk, dut.uart_txd, dut.uart_rxd)
    await init(dut, period)
    addr = random.randint(0, 65535)
    data = random.randint(0, 65535)
    wb_write = cocotb.start_soon(wb.single_write(stall))
    await UartDebugBFM.write_cmd(uart, addr, data)
    wb_data = await wb_write
    assert(data == wb_data)

wf = TestFactory(test_write)
wf.add_option("stall", [0, 1, 2])
wf.generate_tests()

#@cocotb.test()
async def test_read(dut, baud=115200, period=20, stall=0):
    """
    Test Uart Host read (single)
    """
    wb = WbDeviceBFM(dut, 16, 16, default=True)
    uart = UartBFM(baud)
    uart.connect(dut.clk, dut.uart_txd, dut.uart_rxd)
    await init(dut, period)
    addr = random.randint(0, 65535)
    data = random.randint(0, 65535)
    # write
    wb_write = cocotb.start_soon(wb.single_write(stall))
    await UartDebugBFM.write_cmd(uart, addr, data)
    await wb_write
    # read
    wb_read  = cocotb.start_soon(wb.single_read(stall))
    uart_data = await UartDebugBFM.read_cmd(uart, addr)
    assert(data == uart_data)

rf = TestFactory(test_read)
rf.add_option("stall", [0, 1, 2])
rf.generate_tests()