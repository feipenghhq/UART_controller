#!/usr/bin/python3

"""
Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)

Project: Uart Controller
Author: Heqing Huang
Date Created: 06/30/2025
"""

Usage = \
"""
------------------------------------------------------------------------------------------------------------------------
UartDebug(1)

NAME
    UartDebug.py - Interactive shell to communicate with target FPGA

SYNOPSIS
    UartDebug.py
    UartDebug.py file [addr]

DESCRIPTION
    This python script communicates with the target FPGA using UART debug
    interface. It provides an interactive shell for debugging, memory
    access, and programming memory via UART

PREREQUISITES:
    This script requires the 'pyserial' Python package.
    Install it using:
        pip install pyserial

USAGE
    UartDebug.py
        Start an interactive shell.

    UartDebug.py file.hex [addr]
        Program the file to FPGA RAM starting at optional addr (default is 0).

SUPPORTED COMMANDS IN INTERACTIVE SHELL
    help
        Print help message.

    exit
        Exit the command shell.

    read <addr>
        Read data at the specified <addr>.

    write <addr> <data>
        Write <data> to the specified <addr>.

    program <addr> <file>
        Program a RAM or continuous memory space starting at <addr> using the
        contents of <file>. The address of subsequent data is automatically
        calculated.

CONFIG FILE
    The script uses a configuration file to define FPGA target parameters:

    com_port
        COM port for the UART

    baud_rate
        UART Baud rate

    addr_byte
        Number of address byte (e.g., 2).

    data_byte
        Number of data byte (e.g., 2).

AUTHOR
    Heqing Huang

------------------------------------------------------------------------------------------------------------------------
"""

import serial
import json
import argparse
import sys

class UartHost:
    """
    Class to interact with the Uart module in target FPGA
    """

    def __init__(self, config_file='config.json'):
        self.config_file=config_file
        self._get_config()
        self._open_serial()

    def _get_config(self):
        """
        Get the config from config file
        """
        with open(self.config_file, 'r') as file:
            config = json.load(file)
            self.com_port  = config['com_port']
            self.baud_rate = config['baud_rate']
            self.addr_byte = config['addr_byte']
            self.data_byte = config['data_byte']

    def _open_serial(self):
        """
        Open the serial port
        """
        self.ser = serial.Serial(port=self.com_port, baudrate=self.baud_rate, timeout=1)

    def write_cmd(self, addr, data, msg=False):
        """
        Process write command
        """
        cmd = 2 # WRITE CMD = 2
        self.ser.write(cmd.to_bytes(1, byteorder='little'))
        self.ser.write(addr.to_bytes(self.addr_byte, byteorder='little'))
        self.ser.write(data.to_bytes(self.data_byte, byteorder='little'))
        if msg:
            print("[Write] Address = {hex(addr)}, Write data = {hex(data)}")

    def read_cmd(self, addr, msg=False):
        """
        Process read command
        """
        cmd = 1 # READ CMD = 1
        self.ser.write(cmd.to_bytes(1, byteorder='little'))
        self.ser.write(addr.to_bytes(self.addr_byte, byteorder='little'))
        rdata_bytes = self.ser.read(self.data_byte)
        rdata = int.from_bytes(rdata_bytes, byteorder='little')
        if msg:
            print(f"[Read] Address = {hex(addr)}, read data = {hex(rdata)}")
        return rdata

    def rst_cmd(self, rst=True, msg=False):
        """
        Reset Command
        Args:
            rst: True = assert the reset. False = de-assert the reset
        """
        if msg:
            print(f"[RST] {'Assert' if rst else 'De-assert'} the reset")
        cmd = 0xFE if rst else 0xFF
        self.ser.write(cmd.to_bytes(1, byteorder='little'))

    def get_addr_byte(self):
        return self.addr_byte

    def close(self):
        self.ser.close()

class Interpreter():
    """
    Interpreter logic. Entering a infinite loop to process incoming command or process a single command.
    """
    def __init__(self, uart):
        self.uart = uart

    def run(self):
        task = {
            'help':    lambda args: print(Usage),
            'exit':    lambda args: self.proc_exit(*args),
            'read':    lambda args: self.proc_read(*args),
            'write':   lambda args: self.proc_write(*args),
            'program': lambda args: self.proc_program(*args),
        }
        while True:
            cmd, args = self.parse_cmd()
            try:
                task[cmd](args)
            except KeyError:
                print("Unsupported command. You can type help to see all the available commands")

    def parse_cmd(self):
        line = input("> ").strip()
        field = line.split(' ')
        return field[0], tuple(field[1:])

    def proc_write(self, addr, data):
        addr = self._str2int(addr)
        data = self._str2int(data)
        self.uart.write_cmd(addr, data)

    def proc_read(self, addr):
        addr = self._str2int(addr)
        data = self.uart.read_cmd(addr)
        print(f"Data returned from address {hex(addr)} is {hex(data)}")

    def proc_program(self, addr, file):
        # keep the design under reset
        print(f"Assert reset")
        self.uart.rst_cmd(True, False)
        # convert addr string to value. Only support hex or dec value
        addr = self._str2int(addr)
        print(f"Program file to target FPGA. Starting address {addr}. File: {file}")
        addr_byte = self.uart.get_addr_byte()
        with open(file, 'r') as FH:
            lines = FH.readlines()
            # check if the the line is using binary or hex
            for line in lines:
                data = line.strip()
                is_binary = self._is_binary(data)
                if is_binary:
                    data = int(data, 2)
                self.proc_write(addr, data)
                # update addr, the addr here is byte address
                addr = addr + addr_byte
        print(f"De-assert reset")
        self.uart.rst_cmd(False, False)

    def proc_exit(self):
        self.uart.close()
        exit(0)

    def _str2int(self, s):
        """
        Convert string to integer. Support decimal or hexadecimal
        """
        if isinstance(s, str):
            if s.lower().startswith("0x"):
                return int(s, 16)
            else:
                return int(s)
        elif isinstance(s, int): # is already a integer
            return s
        else:
            raise ValueError

    def _is_binary(self, s):
        """
        Check if a string represent binary number
        """
        return set(s).issubset({'0', '1'})

def parse_args():
    parser = argparse.ArgumentParser(prog='UartDebug.py', description=Usage, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('file', nargs='?',
        help='Hex file to be programmed to the target (optional in interactive mode)'
    )
    parser.add_argument('addr', nargs='?', type=lambda x: int(x, 0), default=0,
        help='Start address (hex or dec). Defaults to 0.'
    )
    args = parser.parse_args()
    return args

def main():
    args = parse_args()
    try:
        if args.help:
            return
    except AttributeError:
        pass
    uart_host = UartHost('config.json')
    interpreter = Interpreter(uart_host)
    if args.file:
        file = args.file
        addr = args.addr
        interpreter.proc_program(addr, file)
    else:
        interpreter.run()
    interpreter.proc_exit()

if __name__ == '__main__':
    main()

