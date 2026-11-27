# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 11/26/2026
#
# -------------------------------------------------------------------
# Uart 16550 BFM
# -------------------------------------------------------------------

from enum import IntEnum

from APBBFM import APB_Host
from Env import calculate_div, generate_reset_and_clock
from UartBFM import UartBFM

class Reg(IntEnum):
    RHR = 0
    THR = 0
    IER = 1
    ISR = 2
    FCR = 2
    LCR = 3
    MCR = 4
    LSR = 5
    MSR = 6
    SPR = 7
    DLL = 0
    DLM = 1


class APBUart16550BFM:

    def __init__(self, dut):
        self.dut = dut
        self.apb = APB_Host(dut, bus_separator="")
        self.uart = UartBFM(115200)
        self.uart.connect(dut.clk, dut.uart_txd, dut.uart_rxd)

    async def setup(self, baud=115200, period=10):
        """
        Setup the test environment
        """
        await generate_reset_and_clock(self.dut, period=period)
        await self.config_div(baud, period)

    async def config_div(self, baud=115200, period=10):
        # Set DLAB
        lcr, rsp = await self.apb.apb_read(Reg.LCR)
        assert rsp == 0
        assert await self.apb.apb_write(Reg.LCR, lcr | 0x80) == 0
        # Write DIV
        cfg_div = calculate_div(baud, period)
        assert await self.apb.apb_write(Reg.DLL, cfg_div & 0xFF) == 0
        assert await self.apb.apb_write(Reg.DLM, (cfg_div >> 8) & 0xFF) == 0
        # Clear DLAB
        assert await self.apb.apb_write(Reg.LCR, lcr) == 0

    async def config_lcr(self, *, data_bits=8, stop_bits=1, parity="none", break_enable=False):
        if data_bits not in (5, 6, 7, 8):
            assert ValueError("data_bits must be 5, 6, 7, or 8")
        if stop_bits not in (1, 2):
            assert ValueError("stop_bits must be 1 or 2")
        # LCR bits [5:3]: stick parity, even parity, parity enable
        parity_bits = {
            "none":  0b000,
            "odd":   0b001,
            "even":  0b011,
            "mark":  0b101,
            "space": 0b111,
        }
        if parity not in parity_bits:
            raise ValueError(f"unsupported parity: {parity}")
        lcr = (
            (data_bits - 5)
            | (int(stop_bits - 1)  << 2)
            | (parity_bits[parity] << 3)
            | (int(break_enable)   << 6)
        )
        assert await self.apb.apb_write(Reg.LCR, lcr) == 0

    async def write(self, data):
        """
        Write a data to UART
        FIXME: Need to check if we have space or not?
        """
        assert await self.apb.apb_write(Reg.THR, data) == 0

    async def read(self):
        """
        read a data from UART. Block and wait if there is no data available
        """
        # read LSR
        while True:
            data, rsp = await self.apb.apb_read(Reg.LSR)
            assert rsp == 0
            # check data ready
            if data & 0x1:
                break

        # read RHR
        data, rsp = await self.apb.apb_read(Reg.RHR)
        assert rsp == 0
        return data
