# UART Bridge

- [UART Bridge](#uart-bridge)
  - [Introduction](#introduction)
  - [System Architecture](#system-architecture)
  - [Command Transactions](#command-transactions)
    - [Commands](#commands)
    - [Byte Order and Responses](#byte-order-and-responses)
    - [Transaction Examples](#transaction-examples)
  - [Host Software](#host-software)
    - [Prerequisites](#prerequisites)
    - [Configuration](#configuration)
    - [Interactive Usage](#interactive-usage)
    - [Loading a File](#loading-a-file)
  - [Implementations](#implementations)

## Introduction

The UART bridge provides access to memory-mapped resources, such as RAM and registers, within an FPGA or SoC. A host PC sends commands over UART, and the bridge converts them into bus transactions. This can be used to configure a design, inspect registers, or load data into memory.

## System Architecture

```text
+---------+     UART     +---------------------+     Bus     +-----------------+
| Host PC | <----------> | UART Core + Bridge  | <---------> | RAM / Registers |
+---------+             +---------------------+             +-----------------+
```

The UART core handles serial transmission and reception. The bridge decodes commands, issues bus accesses, and returns read data to the host. A separate active-low reset output can be controlled through UART commands.

## Command Transactions

A transaction starts with a one-byte command, followed by address and data bytes when required:

```text
Write: Command - Address - Write Data
Read:  Command - Address -> Read Data
Reset: Command
```

`ADDR_BYTE` and `DATA_BYTE` specify the number of address and data bytes in the FPGA design. The host must use matching values for `addr_byte` and `data_byte` in the `config.json` file.

### Commands

| Command            | ID     | Host Request                  | Response                                   |
| ------------------ | ------ | ----------------------------- | ------------------------------------------ |
| Single Read        | `0x01` | `0x01 - Address`              | `DATA_BYTE` bytes of read data.            |
| Single Write       | `0x02` | `0x02 - Address - Write Data` | No UART response.                          |
| Reset Assertion    | `0xFE` | `0xFE`                        | No UART response; drives `rst_n_out` low.  |
| Reset De-assertion | `0xFF` | `0xFF`                        | No UART response; drives `rst_n_out` high. |

The reset output affects only the logic connected to it. It does not reset the bridge itself. The bridge initializes `rst_n_out` high when its own reset is asserted.

### Byte Order and Responses

- Addresses, write data, and read data use little-endian byte order: the least significant byte is transferred first.
- Read responses contain raw data only, with no command echo or status byte.
- Writes and reset commands do not return an acknowledgment over UART.
- Transactions are processed sequentially. Wait for the complete read response before issuing the next command.
- The protocol has no packet length field, checksum, or error response. Use the documented commands with the configured address and data widths.

The bridge forwards the address to the target bus without scaling it. Address interpretation depends on the connected target.

### Transaction Examples

For `ADDR_BYTE = 2` and `DATA_BYTE = 2`, writing `0x1234` to address `0x0010` uses the following bytes:

```text
Host -> FPGA: 02 10 00 34 12
```

Reading the same location uses:

```text
Host -> FPGA: 01 10 00
FPGA -> Host: 34 12
```

Reset commands are single-byte requests:

```text
Host -> FPGA: FE    # Assert reset
Host -> FPGA: FF    # De-assert reset
```

## Host Software

The [uart_bridge.py](../tools/uart_bridge/uart_bridge.py) script provides an interactive shell and a command-line file-loading mode.

### Prerequisites

Install Python 3 and the `pyserial` package:

```sh
python3 -m pip install pyserial
```

### Configuration

Edit [config.json](../tools/uart_bridge/config.json) before running the script. The following configuration matches the default address and data widths of the UART-to-Wishbone RAM example:

```json
{
    "com_port": "/dev/ttyUSB0",
    "baud_rate": 115200,
    "addr_byte": 1,
    "data_byte": 2
}
```

| Setting     | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `com_port`  | Serial device connected to the FPGA; update it for your system. |
| `baud_rate` | Baud rate matching the FPGA bridge.                             |
| `addr_byte` | Address width in bytes, matching `ADDR_BYTE`.                   |
| `data_byte` | Data width in bytes, matching `DATA_BYTE`.                      |

These settings configure the host tool only. The script opens the serial port with 8 data bits, no parity, and 1 stop bit by default.

### Interactive Usage

Run the script from its directory so that it can find `config.json`. From the repository root:

```sh
cd tools/uart_bridge
python3 uart_bridge.py
```

The shell accepts these commands:

```text
help                       # Show help
read <address>             # Read a memory location
write <address> <data>      # Write a memory location
program <address> <file>    # Load a data file into memory
exit                       # Close the serial port and exit
```

Addresses and data accept decimal values or hexadecimal values with a `0x` prefix. Values must fit within the configured widths.

For example, with the RAM example:

```text
> write 0x0 0x1234
> read 0x0
Data returned from address 0x0 is 0x1234
```

### Loading a File

Load a file from the interactive shell:

```text
> program 0x0 test.hex
```

Alternatively, run the following from `tools/uart_bridge/`:

```sh
python3 uart_bridge.py test.hex 0x0
```

The start address is optional in command-line mode and defaults to zero. To display command-line help:

```sh
python3 uart_bridge.py -h
```

The current loader reads one value per line. Lines containing only `0` and `1` are interpreted as binary; other values are parsed as decimal or hexadecimal with a `0x` prefix. Use hexadecimal prefixes for unambiguous input. Each value must fit within `data_byte` bytes.

The loader asserts `rst_n_out` before loading and de-asserts it after loading. It currently increments the address by `addr_byte` after each value; confirm that this stride matches the target memory's address layout before using file-loading mode.

## Implementations

| Module                                 | Description                                                     | Design Documentation                          |
| -------------------------------------- | --------------------------------------------------------------- | --------------------------------------------- |
| [uart2wb.sv](../rtl/bridge/uart2wb.sv) | UART-to-Wishbone bridge with a Wishbone B4 pipelined interface. | [UART-to-Wishbone implementation](uart2wb.md) |
