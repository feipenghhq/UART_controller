# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: Hack on FPGA
# Author: Heqing Huang
# Date Created: 06/25/2025
#
# -------------------------------------------------------------------
# Loop back test for Uart Host
# -------------------------------------------------------------------

import cocotb
from cocotb.triggers import FallingEdge, RisingEdge, Timer
from cocotb.clock import Clock
from UartBFM import UartBFM
from UartHostBFM import UartHostBFM

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
    # set default signals value
    dut.uart_rxd.value = 1
    dut.wready.value = 1
    dut.rready.value = 1
    dut.rrvalid.value = 0
    dut.rdata.value = 0
    dut.enable.value = 1
    # clock and reset
    cocotb.start_soon(Clock(dut.clk, 10, units = 'ns').start()) # clock
    await generate_reset(dut)

async def bus_bfm_write(dut, memory):
    """
    BFM for the bus write
    """
    while True:
        await RisingEdge(dut.wvalid)
        await FallingEdge(dut.clk)
        addr = dut.address.value.integer
        data = dut.wdata.value.integer
        memory[addr] = data
        dut._log.info(f"[BusBFM] Memory Write request from Uart Host. Address = {hex(addr)}, Data = {hex(data)}")


async def bus_bfm_read(dut, memory):
    """
    BFM for the bus read
    """
    while True:
        await RisingEdge(dut.rvalid)
        await FallingEdge(dut.clk)
        addr = dut.address.value.integer
        data = memory[addr]
        dut._log.info(f"[BusBFM] Memory Read request from Uart Host. Address = {hex(addr)}. Expected Data = {hex(data)}")
        await FallingEdge(dut.clk)
        dut.rrvalid.value = 1
        dut.rdata.value = data
        await FallingEdge(dut.clk)
        dut.rrvalid.value = 0
        dut.rdata.value = 0

#@cocotb.test()
async def test_write(dut, freq=100, baud=115200):
    """
    Test Uart Host write (single)
    """
    memory = {}
    await init(dut)
    cocotb.start_soon(bus_bfm_write(dut, memory))
    cocotb.start_soon(bus_bfm_read(dut, memory))
    uart_bfm = UartBFM(baud)
    uart_bfm.set_uart_signal(clk=dut.clk, txd=dut.uart_txd, rxd=dut.uart_rxd)
    await UartHostBFM.write_cmd(uart_bfm, 5555, 1234)
    assert(memory[5555] == 1234)

#@cocotb.test()
async def test_read(dut, freq=100, baud=115200):
    """
    Test Uart Host read (single)
    """
    memory = {}
    memory[0x5555] = 0x1234
    await init(dut)
    cocotb.start_soon(bus_bfm_write(dut, memory))
    cocotb.start_soon(bus_bfm_read(dut, memory))
    uart_bfm = UartBFM(baud)
    uart_bfm.set_uart_signal(clk=dut.clk, txd=dut.uart_txd, rxd=dut.uart_rxd)
    data = await UartHostBFM.read_cmd(uart_bfm, 0x5555)
    assert data == 0x1234

@cocotb.test()
async def test_rst_out(dut, freq=100, baud=115200):
    """
    Test Uart Host rst_out_n
    """
    await init(dut)
    uart_bfm = UartBFM(baud)
    uart_bfm.set_uart_signal(clk=dut.clk, txd=dut.uart_txd, rxd=dut.uart_rxd)
    await UartHostBFM.rst_cmd(uart_bfm, rst=False, debug=True)
    await FallingEdge(dut.clk)
    assert(dut.rst_n_out.value.integer == 1)
    await UartHostBFM.rst_cmd(uart_bfm, rst=True, debug=True)
    await FallingEdge(dut.clk)
    assert(dut.rst_n_out.value.integer == 0)
