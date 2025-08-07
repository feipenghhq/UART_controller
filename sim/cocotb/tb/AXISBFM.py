# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 06/26/2025
#
# -------------------------------------------------------------------
# Simple AXI Stream BFM for the Uart Design
# Not fully AXI Stream compatible, only compatible to Uart Design
# -------------------------------------------------------------------

from cocotb.triggers import FallingEdge, RisingEdge, ReadWrite

async def axis_send(dut, data, info=True):
    """
    Send a request to the bus
    """
    # wait till tx_ready is high
    await ReadWrite()
    while(dut.tx_ready.value == 0):
        await RisingEdge(dut.clk)
        await ReadWrite()
    if info:
        dut._log.info(f"[AXIS BFM] Send request to the bus. Write data: {hex(data)}")
    # assert valid and data
    dut.tx_valid.value = 1
    dut.tx_data.value = data
    # de-assert valid and data
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.tx_valid.value = 0
    dut.tx_data.value = 0

async def axis_receive(dut, info=True):
    """
    Receive a data from the bus
    """
    # wait till rx_valid is high
    await ReadWrite()
    while(dut.rx_valid.value == 0):
        await RisingEdge(dut.clk)
        await ReadWrite()
    data = dut.rx_data.value.integer
    if info:
        dut._log.info(f"[AXIS BFM] Receive data from bus. Read data: {hex(data)}")
    return data
