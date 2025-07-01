# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: Hack on FPGA
# Author: Heqing Huang
# Date Created: 06/25/2025
#
# -------------------------------------------------------------------
# Loop back test for Uart
# -------------------------------------------------------------------

import cocotb
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.clock import Clock

async def generate_reset(dut):
    """
    Generate rst_n pulses.
    """
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

async def init(dut):
    """
    Initialize the environment: setup clock, and reset the design
    """
    # Set default signal value
    dut.tx_valid.value = 0
    dut.tx_data.value = 0
    dut.cfg_txen.value = 1
    dut.cfg_rxen.value = 1
    dut.cfg_nstop.value = 0
    dut.cfg_div.value = 432
    # clock and reset
    cocotb.start_soon(Clock(dut.clk, 10, units = 'ns').start()) # clock
    await generate_reset(dut)

async def loopback(dut):
    """
    Loop back the Uart TX to RX
    """
    while True:
        await FallingEdge(dut.clk)
        dut.uart_rxd.value = dut.uart_txd.value

async def drive_tx(dut, data):
    """
    Initiate an UART transaction
    """
    await FallingEdge(dut.clk)
    # wait till tx_ready is high
    while(dut.tx_ready.value == 0):
        await FallingEdge(dut.clk)
    # assert valid and data
    dut.tx_valid.value = 1
    dut.tx_data.value = data
    await FallingEdge(dut.clk)
    dut.tx_valid.value = 0
    dut.tx_data.value = 0

async def monitor_rx(dut):
    """
    monitor the rx data
    """
    await FallingEdge(dut.clk)
    # wait till rx_valid is high
    while(dut.rx_valid.value == 0):
        await FallingEdge(dut.clk)
    return dut.rx_data.value.integer

@cocotb.test()
async def loopback_test(dut):
    """
    Uart Loopback test
    """
    cocotb.start_soon(loopback(dut))
    await init(dut)
    for i in range(256):
        await drive_tx(dut, i)
        data = await monitor_rx(dut)
        assert(i == data)

