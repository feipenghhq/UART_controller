# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 06/26/2025
#
# -------------------------------------------------------------------
# Uart Core BFM
# -------------------------------------------------------------------

from cocotb.triggers import ReadOnly, ReadWrite, RisingEdge


async def uart_core_send(dut, data, info=False):
    """
    Send a request to the uart core
    """
    rising_edge =  RisingEdge(dut.clk)
    read_write = ReadWrite()

    # wait till tx_ready is high
    await read_write
    while(int(dut.tx_ready.value) == 0):
        await rising_edge
        await read_write
    if info:
        dut._log.info(f"[UartCoreBFM] Send TX request to the uart core. Data: {hex(data)}")

    # assert valid and data
    await read_write
    dut.tx_valid.value = 1
    dut.tx_data.value = data

    # de-assert valid and data
    await rising_edge
    await read_write
    dut.tx_valid.value = 0
    dut.tx_data.value = 0

async def uart_core_receive(dut, info=False):
    """
    Receive a data from the bus
    """
    rising_edge = RisingEdge(dut.clk)
    read_write = ReadWrite()

    # wait till rx_valid is high
    await read_write
    while(int(dut.rx_valid.value) == 0):
        await rising_edge
        await read_write

    # read the data
    data = dut.rx_data.value.to_unsigned()
    frame_error = int(dut.frame_error.value)
    parity_error = int(dut.parity_error.value)
    break_error = int(dut.break_error.value)

    if info:
        dut._log.info(f"[UartCoreBFM] Receive data from bus. Read data: {hex(data)}")
    return (data, frame_error, parity_error, break_error)
