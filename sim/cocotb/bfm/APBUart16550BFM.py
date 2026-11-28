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


# LCR bits [5:3]: stick parity, even parity, parity enable.
PARITY_BITS = {
    "none":  0b000,
    "odd":   0b001,
    "even":  0b011,
    "mark":  0b101,
    "space": 0b111,
}


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

    def __init__(self, dut, config):
        self.dut = dut
        self.config = config
        self.apb = APB_Host(dut, bus_separator="")
        parity_bits = PARITY_BITS[self.config.parity]
        self.uart = UartBFM(
            baud=self.config.baud,
            word=self.config.data_bits - 5,
            stop=self.config.stop_bits - 1,
            parity=parity_bits & 1,
            even_parity=(parity_bits >> 1) & 1,
            stick_parity=(parity_bits >> 2) & 1,
            break_=self.config.break_enable,
        )
        self.uart.connect(dut.clk, dut.uart_txd, dut.uart_rxd)

    async def setup(self, period=10):
        """
        Setup the test environment
        """
        await generate_reset_and_clock(self.dut, period=period)
        await self.config_div(period)
        await self.config_lcr()

    async def config_div(self, period=10):
        # Set DLAB
        lcr, rsp = await self.apb.apb_read(Reg.LCR)
        assert rsp == 0
        assert await self.apb.apb_write(Reg.LCR, lcr | 0x80) == 0
        # Write DIV
        cfg_div = calculate_div(self.config.baud, period)
        assert await self.apb.apb_write(Reg.DLL, cfg_div & 0xFF) == 0
        assert await self.apb.apb_write(Reg.DLM, (cfg_div >> 8) & 0xFF) == 0
        # Clear DLAB
        assert await self.apb.apb_write(Reg.LCR, lcr) == 0

    async def config_lcr(self):
        lcr = (
            (self.config.data_bits - 5)
            | ((self.config.stop_bits - 1)  << 2)
            | (PARITY_BITS[self.config.parity] << 3)
            | (int(self.config.break_enable)   << 6)
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
