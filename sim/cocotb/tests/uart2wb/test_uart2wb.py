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
sys.path.append('../../bfm')

import random

import cocotb
from Env import init
from UartBFM import UartBFM
from UartBridgeBFM import UartBridgeBFM
from WbDeviceBFM import WbDeviceBFM


@cocotb.parametrize(stall=[0, 1, 2])
async def test_write(dut, baud=115200, period=10, stall=0):
    """
    Test Uart Host write (single)
    """
    wb = WbDeviceBFM(dut, 16, 16, default=True)
    uart = UartBFM(baud)
    uart.connect(dut.clk, dut.uart_txd, dut.uart_rxd)
    await init(dut, period)
    write_resp = cocotb.start_soon(wb.write_resp(stall))
    addr = random.randint(0, 65535)
    data = random.randint(0, 65535)
    await UartBridgeBFM.write_cmd(uart, addr, data)
    wb_data = await write_resp
    assert(data == wb_data)

@cocotb.parametrize(stall=[0, 1, 2])
async def test_read(dut, baud=115200, period=20, stall=0):
    """
    Test Uart Host read (single)
    """
    wb = WbDeviceBFM(dut, 16, 16, default=True)
    uart = UartBFM(baud)
    uart.connect(dut.clk, dut.uart_txd, dut.uart_rxd)
    await init(dut, period)

    # write
    wb_write = cocotb.start_soon(wb.write_resp(stall))
    addr = random.randint(0, 65535)
    data = random.randint(0, 65535)
    await UartBridgeBFM.write_cmd(uart, addr, data)
    await wb_write

    # read
    wb_read = cocotb.start_soon(wb.read_resp(stall))
    uart_data = await UartBridgeBFM.read_cmd(uart, addr)
    assert(data == uart_data)
    await wb_read
