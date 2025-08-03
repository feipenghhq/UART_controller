# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 06/26/2025
#
# -------------------------------------------------------------------
# UART BFM: act as a UART Host device
# -------------------------------------------------------------------

from cocotb.triggers import FallingEdge, Timer

class UartBFM:

    def __init__(self, baud, nstop=1, info=True):
        """
        Args:
            baud : baud rate
            nstop: number of stop bit. 1 - 1 bit, 2 - 2 bit
        """
        self.baud = baud
        self.nstop = nstop
        self.info = info
        # time interval for each uart transfer bit (in ns)
        self.interval = int(1000000000 / baud)

    def connect(self, clk, txd, rxd):
        """
        Connect the Uart signal to RTL
        """
        self.clk = clk
        self.txd = txd
        self.rxd = rxd

    async def send(self, byte):
        """
        Send a byte through Uart
        """
        if self.info:
            self.txd._log.info(f"[UART BFM] Start sending byte {hex(byte)}")
        # start condition
        await FallingEdge(self.clk)
        self.rxd.value = 0
        await Timer(self.interval, units="ns")
        # send data, LSb is send first
        for _ in range(8):
            self.rxd.value = byte & 0x1
            byte = byte >> 1
            await Timer(self.interval, units="ns")
        # stop condition
        for _ in range(self.nstop):
            self.rxd.value = 1
            await Timer(self.interval, units="ns")
        if self.info:
            self.txd._log.info("[UART BFM] Complete sending byte")

    async def receive(self, data_list=None, debug=False):
        """
        Receive a byte through Uart

        Args:
            data_list (list, optional): List to store received data. Defaults to None.
        """
        data = 0
        # wait for start condition
        await FallingEdge(self.txd)
        if self.info:
            self.rxd._log.info(f"[UartBFM] Start receiving data")
        # move the sample point to the center of a transfer
        await Timer(self.interval/2, units='ns')
        # Receive the data, LSb is received first
        for _ in range(8):
            await Timer(self.interval, units='ns')
            bit = self.txd.value.integer
            data = (data >> 1) | (bit << 7)
            if debug:
                self.txd._log.info(f"[UartBFM] Received bit {_}: {bit}")
        # stop condition
        for _ in range(self.nstop):
            await Timer(self.interval, units='ns')
            assert(self.txd.value.integer)
        if data_list != None:
            data_list.append(data)
        if self.info:
            self.rxd._log.info(f"[UartBFM] Finished receiving data: {hex(data)}")
        return data
