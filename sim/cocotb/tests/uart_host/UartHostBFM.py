# -------------------------------------------------------------------
# Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
# -------------------------------------------------------------------
#
# Project: Hack on FPGA
# Author: Heqing Huang
# Date Created: 07/03/2025
#
# -------------------------------------------------------------------
# Uart Host BFM
# -------------------------------------------------------------------

import cocotb

class UartHostBFM:

    async def write_cmd(uart_bfm, addr, data, abyte=2, dbyte=2, debug=False):
        """
        Perform write command.

        Args:
            addr: address of the write request
            data: write data
            abyte: number of address byte
            dbyte: number of data byte
        """
        if debug:
            uart_bfm.rxd._log.info(f"[UartHost] Write Cmd: Write to address {hex(addr)} with data {hex(data)}")
        # send command
        await uart_bfm.send(0x2)
        # send address, LSB send first
        for _ in range(abyte):
            # LSB send first
            byte = addr & 0xFF
            await uart_bfm.send(byte)
            addr = addr >> 8
        # send data, LSB send first
        for _ in range(dbyte):
            byte = data & 0xFF
            await uart_bfm.send(byte)
            data = data >> 8

    async def read_cmd(uart_bfm, addr, abyte=2, dbyte=2, debug=False):
        """
        Perform read command.
        Args:
            addr: address of the write request
            abyte: number of address byte
            dbyte: number of data byte
        """
        if debug:
            uart_bfm.txd._log.info(f"[UartHost] Read Cmd: Read address {hex(addr)}")
        # start parallel process to receive the data from Uart TX
        # as there are some time mismatch for the uart transaction between the testbench and the RTL
        receive_proc = cocotb.start_soon(uart_bfm.receive())
        # send command
        await uart_bfm.send(0x1)
        # send address, LSB send first
        for _ in range(abyte):
            # LSB send first
            byte = addr & 0xFF
            await uart_bfm.send(byte)
            addr = addr >> 8
        data = 0
        for i in range(dbyte):
            _data = await receive_proc
            data = data | (_data << (8*i))
            receive_proc = cocotb.start_soon(uart_bfm.receive())
        if debug:
            uart_bfm.txd._log.info(f"[UartHost] Read Cmd: Read complete. Got data {hex(data)}")
        return data

    async def rst_cmd(uart_bfm, rst=True, debug=False):
        """
        Reset Command
        Args:
            rst: True = assert the reset. False = de-assert the reset
        """
        if debug:
            uart_bfm.rxd._log.info(f"[UartHost] {'Assert' if rst else 'De-assert'} the reset")
        cmd = 0xFE if rst else 0xFF
        await uart_bfm.send(cmd)