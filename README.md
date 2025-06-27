# UART Controller

- [UART Controller](#uart-controller)
  - [Introduction](#introduction)
  - [Features](#features)
  - [Overview](#overview)
  - [Design](#design)
    - [Uart Core](#uart-core)
    - [Uart Host](#uart-host)


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

## Design

### Uart Core

The `uart_core` module implements the essential logic of the UART protocol, including transmission, reception, baud rate control, and basic framing.

For detailed design documentation, see: [doc/uart_core.md](doc/uart_core.md).

### Uart Host

The `uart_host` module enables a PC to act as a host controller, accessing on-chip memory (e.g., BRAM or registers) via a UART interface. It interprets read and write commands received over UART and translates them into memory-mapped transactions. The module is fully parameterizable for address and data width, and designed for easy integration into FPGA-based systems requiring remote memory control or debugging via serial communication.