# UART Controller

- [UART Controller](#uart-controller)
  - [Introduction](#introduction)
  - [Features](#features)
  - [Overview](#overview)
  - [Uart Core](#uart-core)
  - [Uart Host](#uart-host)
  - [Repo Structure](#repo-structure)


## Introduction

This repository contains a Universal Asynchronous Receiver/Transmitter (UART) controller written in **Verilog**.
The UART module is designed for serial communication between FPGA/ASIC systems and external devices (e.g., terminals, microcontrollers, or PCs).

In addition to the core UART module, the repo includes several related UART components and design examples.

## Features

- Supports 8-N-1 and 8-N-2 formats:
  - 8 data bits
  - No parity bit
  - 1 start bit
  - 1 or 2 stop bits
- 16x receive oversampling using 2/3 majority voting for improved noise immunity

## Overview

UART (Universal Asynchronous Receiver Transmitter) is a simple and commonly used serial protocol. This controller implements basic UART protocol compliant logic including:

- Baud rate generator
- Transmit (TX) shift register and control logic
- Receive (RX) shift register and control logic


## Uart Core

The `uart_core` module implements the essential logic of the UART protocol, including transmission, reception, baud rate control, and basic framing.

For detailed design documentation, read [doc/uart_core.md](doc/uart_core.md).

## Uart Host

The `uart_host` module enables a PC to act as a host controller, accessing on-chip memory (e.g., BRAM or registers) via a UART interface. It interprets read and write commands received over UART and translates them into memory-mapped transactions. The module is fully parameterizable for address and data width, and designed for easy integration into FPGA-based systems requiring remote memory control or debugging via serial communication.

A python script is created to use the uart_host to interact with the target FPGA. The script is located in `scripts/UartHost` directory.

For detailed design document, read [doc/uart_host.md](doc/uart_host.md).

## Repo Structure

```
.
├── doc
├── fpga
│   └── arty        # demo program on arty-a7 FPGA board
├── LICENSE
├── README.md
├── rtl
│   ├── uart        # Uart core module
│   └── uart_host   # Uart Host module
├── scripts
│   ├── UartHost    # Uart Host script to interact with target FPGA
│   └── vivado      # script for vivado
└── sim             # testbench and simulation flow
```