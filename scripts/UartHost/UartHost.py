"""
Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)

Project: Uart Controller
Author: Heqing Huang
Date Created: 06/30/2025
"""

Usage = \
"""
-------------------------------------------------------------------------------------------------------------------------------------------
Script to use uart_host module to communicate with the target chip from the host machine

Usage:
    python3 UartHost.py # Entering interactive mode. Enter command you want to execute in the interactive shell

Supported commands:
    help                            # print help message
    exit                            # exit the command
    read    <address>               # read date at <address>
    write   <address> <data>        # write <data> to <address>
    program <address> <file>        # program a RAM or continuous memory space starting at <address> using content in the <file>.
                                    # the address of the subsequence data will be calculated automatically

Config file:
    A config file is used to provide information about the target device for the script.
    The config file is written in yaml with the following parameters:

    com_port: '/dev/ttyUSB1'     # The serial com port
    baud_rate: 115200            # baud rate of the uart_host module
    addr_byte: 2                 # number of addr byte
    data_byte: 2                 # number of data byte

    The cfg file must be put at the same directory as the UartHost.py script
-------------------------------------------------------------------------------------------------------------------------------------------
"""

import serial
import yaml

class UartHost:
    """
    Class to interact with the Uart module in target FPGA
    """

    def __init__(self, config_file='config.yaml'):
        self.config_file=config_file
        self._get_config()
        self._open_serial()

    def _get_config(self):
        """
        Get the config from config file
        """
        with open(self.config_file, 'r') as file:
            config_yaml = yaml.safe_load(file)
            self.com_port = config_yaml['com_port']
            self.baud_rate = config_yaml['baud_rate']
            self.addr_byte = config_yaml['addr_byte']
            self.data_byte = config_yaml['data_byte']

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
            # check if the ram file is using binary or hex
            is_binary = self._is_binary(lines[0].strip())
            for line in lines:
                data = line.strip()
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

def main():
    uart_host = UartHost('config.yaml')
    uart_host._get_config()
    interpreter = Interpreter(uart_host)
    interpreter.run()

if __name__ == '__main__':
    main()

