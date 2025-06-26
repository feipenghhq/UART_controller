# UART Controller

This repository contains a Universal Asynchronous Receiver/Transmitter (UART) controller written in **Verilog**.
The UART module is designed for serial communication between FPGA/ASIC systems and external devices (e.g., terminals, microcontrollers, or PCs).

## Features

- 8-N-1 and 8-N-2 formats: 8 data bits, no parity bit, 1 start bit, 1 or 2 stop bits.
- optional transmit and receive FIFO buffers with programmable watermark interrupts
- 16× Rx oversampling with 2/3 majority voting per bit

## Overview

UART (Universal Asynchronous Receiver Transmitter) is a simple and commonly used serial protocol. This controller implements basic UART protocol compliant logic including:

- Baud rate generator
- Transmit (TX) shift register and control logic
- Receive (RX) shift register and control logic
- Ready/valid handshakes
- Optional framing and error checking

## Implementation

### Uart Core

The UART core is the contains the core logic for implementing the UART transaction protocol. For detailed check [uart_core.md](doc/uart_core.md).