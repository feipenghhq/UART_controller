# UART Controller

- [UART Controller](#uart-controller)
  - [Introduction](#introduction)
  - [Features](#features)
    - [UART Core](#uart-core)
    - [UART Bridge](#uart-bridge)
  - [Quick Start](#quick-start)
    - [Run a Simulation](#run-a-simulation)
    - [Run on FPGA](#run-on-fpga)
  - [Repository Structure](#repository-structure)
  - [Examples](#examples)
    - [UART Loopback](#uart-loopback)
    - [UART-to-Wishbone RAM](#uart-to-wishbone-ram)
  - [Host Tool](#host-tool)
    - [Setup](#setup)
    - [Usage](#usage)
  - [Documentation](#documentation)
  - [License](#license)


## Introduction

This repository provides SystemVerilog UART controller modules for FPGA and SoC designs.

The main designs are listed below:

- UART Core: Basic UART transmitter and receiver modules for serial communication.
- UART Bridge: UART bridge for accessing memory-mapped registers and memory within an FPGA or SoC.
- UART16550 (*planned*): A 16550-compatible UART controller.

This repository also provides design examples with FPGA projects for supported boards.

## Features

### UART Core

- Separate UART TX and RX modules that can be used independently or combined into a complete UART Core.
- 16x receive oversampling and 2/3 majority voting for improved noise immunity.
- Simple valid/ready handshake interface on TX and a data-valid indication on RX.
- 16550-style line configuration:
  - Configurable data bits: 5, 6, 7, or 8 bits.
  - Configurable parity: no parity, even parity, odd parity or stick parity (fixed 0 or 1).
  - Configurable stop bits: 1 or 2 bits with 1.5 stop bits instead of 2 in 5-bit data mode.
  - Configurable baud rate through a programmable clock divider.
- TX break control.
- RX framing, parity and break error detection.

### UART Bridge

- Currently supports Wishbone B4 pipelined interface.
- Supports single read and write transactions.
- Configurable address and data widths through parameters.
- Supports reset control through UART commands.

## Quick Start

### Run a Simulation

Prerequisites: Python 3, Cocotb 2.x, Verilator, and Make. GTKWave is optional for viewing waveforms.

Run the UART test from the repository root:

```sh
# Example: run uart test
cd sim/cocotb/tests/uart
make
```

Cocotb should report that all the tests have passed.

### Run on FPGA

Prerequisites:

- DE2: Quartus II 13.0sp1
- Arty A7-35: Vivado

Run the loopback example from the repository root:

```sh
cd examples/uart_loopback/fpga/<board>  # board is arty or de2
make      # build the FPGA image
make pgm  # program the FPGA
```

Open a serial terminal and configure it for 115200 baud, 8 data bits, no parity, and 1 stop bit (8-N-1).
Send a character to the FPGA through the terminal and you should see the character echoed back.
Disable local echo in the terminal to verify that the character is echoed back by the FPGA.

## Repository Structure

```text
rtl/
├── uart/                 # UART TX, RX, core, and baud-rate generator
└── bridge/               # UART-to-bus bridges
examples/
├── uart_loopback/        # UART loopback example
└── uart2wbram/           # UART-to-Wishbone RAM access example
sim/
└── cocotb/               # Tests, bus functional models, and test environment
tools/
└── uart_bridge/          # Python host tool and configuration
scripts/
├── vivado/               # Vivado build and programming scripts
└── quartus/              # Quartus build and programming scripts
doc/                      # Design and protocol documentation
```

## Examples

### UART Loopback

This example echoes data received from the host back to the host. It demonstrates how to connect and use the UART core's transmitter and receiver modules.

See [the UART loopback example](examples/uart_loopback/) for the RTL and FPGA projects for Arty A7-35 and DE2 boards.

### UART-to-Wishbone RAM

This example uses the UART-to-Wishbone bridge to read and write on-chip FPGA RAM from a host PC. The [Python host tool](tools/uart_bridge/) can be used to read and write individual memory locations or load a data file into RAM.

See [the UART-to-Wishbone RAM example](examples/uart2wbram/) for the RTL, Cocotb integration test, and FPGA projects for Arty A7-35 and DE2 boards.

## Host Tool

The [Python host tool](tools/uart_bridge/uart_bridge.py) communicates with the target FPGA through the UART bridge. It provides an interactive shell for memory reads, memory writes, and loading data files into memory.

### Setup

Install the required Python package:

```sh
python3 -m pip install pyserial
```

Update [config.json](tools/uart_bridge/config.json) before running the tool:

- `com_port`: Serial device connected to the FPGA.
- `baud_rate`: UART baud rate.
- `addr_byte`: Address width in bytes.
- `data_byte`: Data width in bytes.

The baud rate, address width, and data width must match the FPGA design. These settings configure the host tool only.

### Usage

Start the interactive shell from the repository root:

```sh
cd tools/uart_bridge
python3 uart_bridge.py
```

The shell supports the following commands. Addresses and data can be entered in decimal or hexadecimal with a `0x` prefix.

```text
help                       # Show help
read <address>             # Read a memory location
write <address> <data>      # Write a memory location
program <address> <file>    # Load a data file into memory
exit                       # Close the serial port and exit
```

For example, with the UART-to-Wishbone RAM example:

```text
> write 0x0 0x1234
> read 0x0
Data returned from address 0x0 is 0x1234
```

A file can also be loaded directly from the command line. Run this from `tools/uart_bridge/`; the start address defaults to zero when omitted:

```sh
python3 uart_bridge.py <file> [address]
```

## Documentation

Detailed design and protocol descriptions are available in the following documents:

| Document | Description |
| --- | --- |
| [UART Core](doc/uart_core.md) | UART timing, module interfaces, and transmitter and receiver implementation. |
| [UART Bridge](doc/uart_bridge.md) | UART bridge architecture, command protocol, and host software usage. |
| [UART-to-Wishbone Bridge](doc/uart2wb.md) | Bridge parameters, Wishbone interface, and transaction state machine. |

## License

This project is licensed under the [MIT License](LICENSE).
