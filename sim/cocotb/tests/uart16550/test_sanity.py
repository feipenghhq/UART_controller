# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 11/26/2026
#
# -------------------------------------------------------------------
# Basic sanity check
# - Register Access
# - Basic UART send and receive
# -------------------------------------------------------------------

import random
import sys
from pathlib import Path

COCOTB_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(COCOTB_ROOT / "tb"))
sys.path.insert(0, str(COCOTB_ROOT / "bfm"))

import cocotb
from APBBFM import APB_Host
from APBUart16550BFM import APBUart16550BFM, Reg
from Env import calculate_div, generate_reset_and_clock
from UartBFM import UartBFM
from UartConfig import UartConfig

config = UartConfig

@cocotb.test()
async def test_register(dut):
    PERIOD = 10
    apb = APB_Host(dut, bus_separator="")
    bfm = UartBFM(115200)
    bfm.connect(dut.clk, dut.uart_txd, dut.uart_rxd)
    await generate_reset_and_clock(dut, period=PERIOD)
    # Set DLAB
    assert await apb.apb_write(Reg.LCR, 0x80) == 0
    # Write DIV
    cfg_div = calculate_div(115200, PERIOD)
    assert await apb.apb_write(Reg.DLL, cfg_div & 0xFF) == 0
    assert await apb.apb_write(Reg.DLM, (cfg_div >> 8) & 0xFF) == 0
    # Read DIV
    assert await apb.apb_read(Reg.DLL) == ((cfg_div & 0xFF), 0)
    assert await apb.apb_read(Reg.DLM) == ((cfg_div >> 8) & 0xFF, 0)
    # IER
    data = random.randint(0, 0xFF)
    assert await apb.apb_write(Reg.IER, data) == 0
    assert await apb.apb_read(Reg.IER) == (data, 0)
    # ISR
    assert await apb.apb_write(Reg.IER, 0) == 0     # Clear IER to disable all interrupt
    assert await apb.apb_read(Reg.ISR) == (0x1, 0)
    # FCR
    data = random.randint(0, 0xFF)
    assert await apb.apb_write(Reg.FCR, data) == 0
    # LCR
    data = random.randint(0, 0xFF)
    assert await apb.apb_write(Reg.LCR, data) == 0
    assert await apb.apb_read(Reg.LCR) == (data, 0)
    # MCR
    data = random.randint(0, 0xFF)
    assert await apb.apb_write(Reg.MCR, data) == 0
    assert await apb.apb_read(Reg.MCR) == (data, 0)
    # LSR
    assert await apb.apb_read(Reg.LSR) == (0x60, 0)
    # MSR
    assert await apb.apb_read(Reg.MSR) == (0, 0)
    # SPR
    data = random.randint(0, 0xFF)
    assert await apb.apb_write(Reg.SPR, data) == 0
    assert await apb.apb_read(Reg.SPR) == (data, 0)

@cocotb.test()
async def test_tx_nonfifo(dut):
    uart16550 = APBUart16550BFM(dut, config)
    await uart16550.setup()
    receive = cocotb.start_soon(uart16550.uart.receive())
    await uart16550.write(0xbf)
    data = await receive
    assert data == 0xbf

@cocotb.test()
async def test_rx_nonfifo(dut):
    uart16550 = APBUart16550BFM(dut, config)
    await uart16550.setup()
    await uart16550.config_lcr()
    # Send from uart
    send = cocotb.start_soon(uart16550.uart.send(0xfb))
    # Start read pulling
    read = cocotb.start_soon(uart16550.read())
    await send
    data = await read
    assert data == 0xfb

