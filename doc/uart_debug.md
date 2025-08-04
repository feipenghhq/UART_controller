# Uart Debug

Use UART as a debug interface to access on-chip memory (e.g., BRAM, registers, etc.).

- [Uart Debug](#uart-debug)
  - [System Architecture](#system-architecture)
  - [Command](#command)
    - [List of Commands](#list-of-commands)
    - [Command details](#command-details)
  - [Software](#software)
    - [Prerequisites](#prerequisites)
    - [Usage](#usage)
  - [Implementation](#implementation)
    - [uart2wb.sv](#uart2wbsv)


## System Architecture

```
              +------------+       +-----------------+      +---------------+     +----------------+
  Host PC --> | UART RX/TX | <---> | UART Controller | <--->| Bus Converter | <-> | On-Chip Memory |
              +------------+       +------+----------+      +--------+------+     +----------------+
```

## Command

Each command transaction consists of several bytes:

```
Command (1 byte) - Address (2-4 byte) - Data (2-4 byte)
```

The number of address byte and number of data byte is configurable through parameters

### List of Commands

| Command            | CMD ID |
| ------------------ | ------ |
| Single Write       | 0x01   |
| Single Read        | 0x02   |
| Reset Assertion    | 0xFE   |
| Reset De-assertion | 0xFF   |

### Command details

| Command            | Format                        | Description                |
| ------------------ | ----------------------------- | -------------------------- |
| Reset Assertion    | `0FE`                         | Assert the `rst_n_out`.    |
| Reset De-assertion | `0xFF`                        | De-assert the `rst_n_out`. |
| Write              | `0x01 - Address - Write Data` | Single write.              |
| Read               | `0x02 - Address`              | Single read.               |

## Software

A python script [UartDebug.py](../tools/UartDebug/UartDebug.py) is created to interact with the target FPGA to transfer data between the host machine and the FPGA.

### Prerequisites

`pyserial` package is required to use access uart. Use the following command to install the package: ```pip install pyserial```

### Usage

#### Config file

A config file [config.json](../tools/UartDebug/config.json) defines necessary information for the design.
Before using the script, the config file need to be updated to match with the design.

```json
"com_port" : "/dev/ttyUSB1"    // The serial com port
"baud_rate": 115200            // baud rate of the uart_host module
"addr_byte": 2                 // number of addr byte
"data_byte": 2                 // number of data byte
```

#### Script usage

```shell
# Show help message
./UartDebug.py -h

# Enter interactive shell
./UartDebug.py

# Program a ram/hex file at given address. addr can be omitted if address start at 0
./UartDebug.py file [addr]
```

#### Command in interactive shell mode

```bash
> help                            # print help message
> exit                            # exit the command
> read    <address>               # read date at <address>
> write   <address> <data>        # write <data> to <address>
> program <address> <file>        # program a RAM or continuous memory space starting at <address> using content in the <file>.
```

## Implementation

Uart Debug supports the following implementation:

### uart2wb.sv

- uart2wb provide wishbone interface access. It support wishbone 4b pipeline interface.
- Design implementation: [uart2wb](uart2wb.md).