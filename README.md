# UART Controller

## Introduction

This repo contains several useful UART design:

### UART Module

- UART Transmitter: [uart_tx.sv](rtl/uart/uart_tx.sv). Transmit data from FPGA to Host. Use AXI-Stream like interface.
- UART Receiver: [uart_rx.sv](rtl/uart/uart_rx.sv). Receive data from Host to FPGA. Use AXI-Stream like interface.
- UART Core: [uart_core.sv](rtl/uart/uart_core.sv). Bundled uart_tx and uart_rx together.

**Features:**

- AXI-Stream like interface.
- Supports 8-N-1 and 8-N-2 formats,
- Configurable baud rate.
- 16x receive oversampling using 2/3 majority voting for improved noise immunity

### UART Debug

- UART to Wishbone : [uart2wb.sv](rtl/uart_debug/uart2wb.sv).
  - This design receives command from the host machine and then access the bus through Wishbone interface.
  - It is a useful tools to program and debug a SoC system.


## Design Implementation

Detailed design implementation document can be found in `doc` folder:

- UART Module: [doc/uart_core.md](doc/uart_core.md).
- UART Debug: [doc/uart_debug.md](doc/uart_debug.md).

## RTL File

### UART Module

| File                    | Description                            |
| ----------------------- | -------------------------------------- |
| `rtl/uart/uart_baud.sv` | counter to generate desired baud rate  |
| `rtl/uart/uart_rx.sv`   | UART receiver module                   |
| `rtl/uart/uart_tx.sv`   | UART transmitter module                |
| `rtl/uart/uart_core.sv` | UART core, include uart_tx and uart_rx |

### UART Debug

| File                        | Description                 |
| --------------------------- | --------------------------- |
| `rtl/uart_debug/uart2wb.sv` | UART to wishbone controller |

## FPGA Demo

Few FPGA demo programs are created to verify the UART design on real hardware:
- UART Loopback: [fpga_uart_loopback.sv](./rtl/fpga_examples/fpga_uart_loopback.sv)
  - Loop back the UART RX back to TX.
- Uart2wb RAM: [fpga_uart2wb_ram.sv](rtl/fpga_examples/fpga_uart2wb_ram.sv)
  - Use uart2wb to access FPGA on-chip ram.

Supported FPGA boards:
- Arty A7 35
- Altera DE2

### Building and Programming the FPGA Image

If you have one of the FPGA board, Follow these steps to build and program the FPGA image:

```shell
# Go to program directory
cd fpga/<board>/<program>

# Arty FPGA - Require Xilinx Vivado tool
make          # Build the FPGA image
make pgm      # Program the FPGA

# DE2 FPGA - Require Altera Quartus 13.0sp1 version
make pgm      # Build the FPGA image and program the FPGA
```
