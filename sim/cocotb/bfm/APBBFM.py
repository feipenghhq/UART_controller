# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 11/26/2026
#
# -------------------------------------------------------------------
# APB BFM
# -------------------------------------------------------------------

from cocotb.triggers import ReadWrite, RisingEdge
from cocotb_bus.bus import Bus


class APB(Bus):

    _SIGNALS = ('psel', 'penable', 'pwrite', 'paddr', 'pwdata', 'prdata', 'pslverr', 'pready')

    def __init__(self, dut, signals=_SIGNALS, bus_separator='_'):
        super().__init__(dut, "", signals, bus_separator=bus_separator)
        self.dut = dut

class APB_Host(APB):

    def __init__(self, dut, signals=APB._SIGNALS, bus_separator='_'):
        super().__init__(dut,signals, bus_separator)
        self.init_bus()

    def init_bus(self):
        self.psel.value    = 0
        self.penable.value = 0
        self.pwrite.value  = 0
        self.paddr.value   = 0
        self.pwdata.value  = 0

    async def apb_write(self, addr, data, info=False):
        """
        Send a request to the uart core
        """
        rising_edge =  RisingEdge(self.dut.clk)
        read_write = ReadWrite()

        # Setup Phase
        await rising_edge;
        await read_write;
        self.psel.value = 1
        self.penable.value = 0
        self.pwrite.value = 1
        self.paddr.value = addr
        self.pwdata.value = data

        # Access Phase
        await rising_edge;
        await read_write;
        self.psel.value = 1
        self.penable.value = 1
        self.pwrite.value = 1
        self.paddr.value = addr
        self.pwdata.value = data

        # Check wait state
        while(int(self.pready.value) == 0):
            await rising_edge
            await read_write

        resp = int(self.pslverr.value)
        if info:
            self.dut._log.info(f"[ABP] Write to Addr: {hex(addr)}. Data: {hex(data)}. Resp: {resp}")
        return resp


    async def apb_read(self, addr, info=False):
        """
        Send a request to the uart core
        """
        rising_edge =  RisingEdge(self.dut.clk)
        read_write = ReadWrite()

        # Setup Phase
        await rising_edge;
        await read_write;
        self.psel.value = 1
        self.penable.value = 0
        self.pwrite.value = 0
        self.paddr.value = addr
        self.pwdata.value = 0

        # Access Phase
        await rising_edge;
        await read_write;
        self.psel.value = 1
        self.penable.value = 1
        self.pwrite.value = 0
        self.paddr.value = addr
        self.pwdata.value = 0

        # Check wait state
        while(int(self.pready.value) == 0):
            await rising_edge
            await read_write

        rdata = self.prdata.value.to_unsigned()
        resp = int(self.pslverr.value)
        if info:
            self.dut._log.info(f"[ABP] Read from Addr: {hex(addr)}. Data: {hex(rdata)}. Resp: {resp}")
        return rdata, resp
