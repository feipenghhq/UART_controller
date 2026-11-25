# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: UART Controller
# Author: Heqing Huang
# Date Created: 06/26/2025
#
# -------------------------------------------------------------------
# UART BFM: Act as a UART Host device
# -------------------------------------------------------------------

from cocotb.triggers import FallingEdge, ReadWrite, RisingEdge, Timer


class UartBFM:

    def __init__(self, baud=115200, word=3, stop=0, parity=0, even_parity=0, stick_parity=0, break_=0, info=False):
        self.baud = baud
        self.stop = stop
        self.parity = parity
        self.even_parity = even_parity
        self.stick_parity = stick_parity
        self.break_ = break_
        self.info = info

        # time interval for each uart transfer bit (in ns)
        self.interval = round(1e9 / baud)

        # data count
        self.data_cnt = 5 + word

        # stop count
        self.stop_cnt = 1 + stop
        if word == 0 and stop == 1:
            self.stop_cnt = 1.5

    def connect(self, clk, txd, rxd):
        """
        Connect the Uart signal to RTL
        """
        self.clk = clk
        self.txd = txd
        self.rxd = rxd

    async def send(self, data):
        """
        Send a data through Uart
        """
        parity = (data.bit_count() & 1) ^ self.even_parity

        timer_one_baud = Timer(self.interval, unit="ns")
        read_write = ReadWrite()

        if self.info:
            self.txd._log.info(f"[UART BFM] Start sending byte {hex(data)}")

        # start condition
        await read_write
        self.rxd.value = 0
        await timer_one_baud

        # send data, lsb is send first
        for _ in range(self.data_cnt):
            self.rxd.value = data & 0x1
            data = data >> 1
            await timer_one_baud

        # send parity
        if self.parity:
            if self.stick_parity:
                self.rxd.value = 1 - self.even_parity
            else:
                self.rxd.value = parity
            await timer_one_baud

        # send stop
        self.rxd.value = 1
        await Timer(self.interval * self.stop_cnt, unit="ns")

        if self.info:
            self.txd._log.info("[UART BFM] Complete sending byte")

    async def receive(self, data_list=None, debug=False):
        """
        Receive a byte through Uart
        """
        timer_one_baud = Timer(self.interval, unit="ns")

        data = 0
        parity_bit = 0
        stop = 0

        # wait for start condition
        await FallingEdge(self.txd)
        if self.info:
            self.rxd._log.info("[UartBFM] Start receiving data")

        # move the sample point to the center of a bit
        await Timer(self.interval/2, unit='ns')

        # Receive the data, lsb is received first
        for _ in range(8):
            await timer_one_baud
            bit = int(self.txd.value)
            data = (data >> 1) | (bit << 7)
            if debug:
                self.txd._log.info(f"[UartBFM] Received bit {_}: {bit}")

        # send parity
        if self.parity:
            await timer_one_baud
            parity_bit = int(self.txd.value)
            # Calculate expected parity
            expected_parity = (
                1 - self.even_parity if self.stick_parity
                else (data.bit_count() & 1) ^ (1 - self.even_parity)
            )
            # Check parity error
            assert parity_bit == expected_parity, "Parity Error"

        # Receive stop condition
        await timer_one_baud
        stop = int(self.txd.value)
        if (self.stop_cnt > 1):
            await Timer(self.interval * (self.stop_cnt - 1), unit='ns')
        assert stop, "Frame Error"

        # Check break error
        if parity_bit == 0 and stop == 0 and data == 0:
            assert False, "Frame Error"

        if self.info:
            self.rxd._log.info(f"[UartBFM] Finished receiving data: {hex(data)}")

        if data_list != None:
            data_list.append(data)

        return data


    async def loopback(self, dut):
        """
        Loop back the Uart TX to RX
        """
        while True:
            await RisingEdge(dut.clk)
            self.rxd.value = self.txd.value
