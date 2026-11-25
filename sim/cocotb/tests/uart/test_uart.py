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
sys.path.append('../../bfm')

import random

import cocotb
from Env import init
from UartBFM import UartBFM
from UartCoreBFM import uart_core_receive, uart_core_send


@cocotb.test()
async def test_transmit(dut, num=8):
    """
    Test transmit path.
    """
    bfm = UartBFM(115200)
    bfm.connect(dut.clk, dut.uart_txd, dut.uart_rxd)
    await init(dut)
    for i in range(num):
        value = random.randint(0, 255)
        rcv = cocotb.start_soon(bfm.receive())
        await uart_core_send(dut, value)
        data = await rcv
        assert(value == data)

@cocotb.test()
async def test_receive(dut, num=8):
    """
    Test receive path.
    """
    bfm = UartBFM(115200)
    bfm.connect(dut.clk, dut.uart_txd, dut.uart_rxd)

    await init(dut)
    for i in range(num):
        value = random.randint(0, 255)
        receive = cocotb.start_soon(uart_core_receive(dut))
        await bfm.send(value)
        data, _, _, _ = await receive
        assert(value == data)

@cocotb.test()
async def loopback(dut, num=8):
    """
    Uart Loopback test.
    """
    bfm = UartBFM(115200)
    bfm.connect(dut.clk, dut.uart_txd, dut.uart_rxd)
    await init(dut)
    cocotb.start_soon(bfm.loopback(dut))
    for i in range(num):
        value = random.randint(0, 255)
        await uart_core_send(dut, value)
        data, _, _, _ = await uart_core_receive(dut)
        assert(value == data)
