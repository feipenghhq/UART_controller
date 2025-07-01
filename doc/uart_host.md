# Uart Host

Use UART as a host interface to read/write on-chip memory (e.g., BRAM, registers, etc.).

- [Uart Host](#uart-host)
  - [System Architecture](#system-architecture)
  - [UART Command Format](#uart-command-format)
    - [1. Write Command](#1-write-command)
    - [2. Read Command](#2-read-command)
  - [Implementation](#implementation)
    - [Parameters](#parameters)
    - [Ports](#ports)
    - [State Machine](#state-machine)


## System Architecture

```
          +----------------+       +--------------------+
  PC ---> |   UART RX/TX   | <---> |   UART Controller  |
          +----------------+       +--------+-----------+
                                             |
                                             v
                                    +-------------------+
                                    |  On-Chip Memory   |
                                    | (e.g., BRAM, RAM) |
                                    +-------------------+
```

## UART Command Format

Each transaction consists of several uart byte. Here is the sequence of the bytes:

```
Command (1 byte) - Address (2-4 byte) - Data (2-4 byte)
```

The number of address byte and number of data byte is configurable through parameters

### 1. Write Command

| Byte Index | Description              |
| ---------- | ------------------------ |
| 0          | Command = `0x01` (Write) |
| 1\~4       | Address (32-bit)         |
| 5\~8       | Data (32-bit)            |

### 2. Read Command

| Byte Index | Description             |
| ---------- | ----------------------- |
| 0          | Command = `0x02` (Read) |
| 1\~4       | Address (32-bit)        |

## Implementation

### Parameters

| Name      | Description                       |
| --------- | --------------------------------- |
| ADDR_BYTE | Number of byte to receive address |
| DATA_BYTE | Number of byte to receive data    |
| BAUD_RATE | baud rate                         |
| CLK_FREQ  | clock frequency                   |

### Ports

| Name     | Direction | Width       | Description         |
| -------- | --------- | ----------- | ------------------- |
| clk      | input     | 1           | Clock.              |
| rst_n    | input     | 1           | Reset.              |
| uart_rxd | input     | 1           | UART RX signal      |
| uart_txd | output    | 1           | UART RX signal      |
| enable   | input     | 1           | enable uart host    |
| address  | output    | 8*ADDR_BYTE | Output address      |
| wvalid   | output    | 1           | write request       |
| wdata    | output    | 8*DATA_BYTE | write data          |
| wready   | input     | 1           | write request ready |
| rvalid   | output    | 1           | read request        |
| rready   | input     | 1           | read request ready  |
| rrvalid  | input     | 1           | read data valid     |
| rdata    | input     | 8*DATA_BYTE | read data           |

### State Machine

![state machine](./assets/uart_host_state.drawio.svg)

The state machine is the main control logic for the uart host.

In **IDLE** state, the logic is waiting for a new command. Once it receive a byte from the Uart core logic, this byte will
be treated as the command. It then transfer to the **ADDR** state to receives the address.

In **ADDR** state, the address of the transaction is received from the Uart core logic. The least significant byte is
received first. Once all the address byte has been received, if the command is read command, it transfers to **ACCESS** state.
If the command is write, it transfers to **DATA** state.

In **DATA** state, the write data of the transaction is received from the Uart core logic. The least significant byte is
received first. Once all the data byte has been received, it transfers to **ACCESS** state.

In **ACCESS** state, the uart host logic will access the system bus to write or read the data. If the command is write,
it simply put write request onto the bus and once the bus handshake complete, it transfers back to **IDLE** state.
If the command is read, it put the read request onto the bus and then transfer to **READ** state.

In **READ** state, the logic is waiting for the read data (response) from the bus, once the date is returned, it transfers
to **SEND** state.

In **SEND** state, the read data is sent to the host machine through Uart core logic. The least significant byte is
received first. Once all the data byte is sent, it transfers back to IDLE state.