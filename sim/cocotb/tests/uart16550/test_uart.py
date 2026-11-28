# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 11/26/2026
#
# -------------------------------------------------------------------
# Test the UART module correctness including:
# - Data width
# - Parity bit
# - Stop bit
# -------------------------------------------------------------------

import random
import sys
from pathlib import Path

COCOTB_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(COCOTB_ROOT / "tb"))
sys.path.insert(0, str(COCOTB_ROOT / "bfm"))

import cocotb
from APBUart16550BFM import APBUart16550BFM
from UartConfig import UartConfig

#--------------------------------------
# Common function
#--------------------------------------

async def test_tx(dut, config):
    uart16550 = APBUart16550BFM(dut, config)
    await uart16550.setup()
    receive = cocotb.start_soon(uart16550.uart.receive())
    data = random.randint(0, 0xFF)
    data &= (1 << config.data_bits) - 1
    await uart16550.write(data)
    rdata = await receive
    assert rdata == data

async def test_rx(dut, config):
    uart16550 = APBUart16550BFM(dut, config)
    await uart16550.setup()
    await uart16550.config_lcr()
    data = random.randint(0, 0xFF)
    data &= (1 << config.data_bits) - 1
    # Send from uart
    send = cocotb.start_soon(uart16550.uart.send(data))
    # Start read pulling
    read = cocotb.start_soon(uart16550.read())
    await send
    rdata = await read
    assert rdata == data

#--------------------------------------
# Test data width
#--------------------------------------

@cocotb.test()
@cocotb.parametrize(config=[cocotb.Param(UartConfig(data_bits=width), name=f"{width}-bits") for width in range(5,9)])
async def test_tx_data_with(dut, config):
    await test_tx(dut, config)

@cocotb.test()
@cocotb.parametrize(config=[cocotb.Param(UartConfig(data_bits=width), name=f"{width}-bits") for width in range(5,9)])
async def test_rx_data_with(dut, config):
    await test_rx(dut, config)

#--------------------------------------
# Test parity
#--------------------------------------

PARITY = ("odd", "even", "mark", "space")

@cocotb.test()
@cocotb.parametrize(config=[cocotb.Param(UartConfig(parity=parity), name=f"{parity}-parity") for parity in PARITY])
async def test_tx_parity(dut, config):
    await test_tx(dut, config)

@cocotb.test()
@cocotb.parametrize(config=[cocotb.Param(UartConfig(parity=parity), name=f"{parity}-parity") for parity in PARITY])
async def test_rx_parity(dut, config):
    await test_rx(dut, config)

#--------------------------------------
# Test Stop
#--------------------------------------

@cocotb.test()
@cocotb.parametrize(config=[cocotb.Param(UartConfig(stop_bits=stop), name=f"{stop}-stop") for stop in (1, 2)])
async def test_tx_stop(dut, config):
    await test_tx(dut, config)

@cocotb.test()
@cocotb.parametrize(config=[cocotb.Param(UartConfig(stop_bits=stop), name=f"{stop}-stop") for stop in (1, 2)])
async def test_rx_stop(dut, config):
    await test_rx(dut, config)

@cocotb.test()
@cocotb.parametrize(config=[cocotb.Param(UartConfig(data_bits=5, stop_bits=2))])
async def test_tx_1p5stop(dut, config):
    await test_tx(dut, config)

@cocotb.test()
@cocotb.parametrize(config=[cocotb.Param(UartConfig(data_bits=5, stop_bits=2))])
async def test_rx_1p5stop(dut, config):
    await test_rx(dut, config)
