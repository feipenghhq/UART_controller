# Uart2wb Implementation

- **uart2wb*- provide wishbone interface access.
- Support wishbone 4b pipeline interface.

## Implementation

### Parameters

| Name      | Description                       |
| --------- | --------------------------------- |
| ADDR_BYTE | Number of byte to receive address |
| DATA_BYTE | Number of byte to receive data    |
| BAUD_RATE | baud rate                         |
| CLK_FREQ  | clock frequency                   |

Reset of parameter are fixed and should not be changed by user.

| Name | Description   |
| ---- | ------------- |
| AW   | Address width |
| DW   | Data width    |

### Interfaces

| Name        | Direction | Width | Description      |
| ----------- | --------- | ----- | ---------------- |
| `clk`       | input     | 1     | Clock.           |
| `rst_n`     | input     | 1     | Reset.           |
| `uart_rxd`  | input     | 1     | UART RX signal   |
| `uart_txd`  | output    | 1     | UART RX signal   |
| `enable`    | input     | 1     | enable uart host |
| `rst_n_out` | output    | 1     | reset output     |

#### Wishbone B4 Interface

| Signal         | Direction | Width       | Description                                     |
|----------------|-----------|-------------|-------------------------------------------------|
| `wb_cyc_o`     | Output    | 1           | Asserted for the duration of a valid bus cycle |
| `wb_stb_o`     | Output    | 1           | Indicates a valid data transfer request        |
| `wb_we_o`      | Output    | 1           | Write enable (1 = write, 0 = read)             |
| `wb_adr_o`     | Output    | AW          | Address of the access                          |
| `wb_dat_i`     | Input     | DW          | Data read from slave                           |
| `wb_dat_o`     | Output    | DW          | Data written to slave                          |
| `wb_ack_i`     | Input     | 1           | Acknowledge from slave                         |
| `wb_stall_i`   | Input     | 1           | Slave requests bus hold (wait state)           |


### State Machine

![state machine](./assets/state_machine/uart_host_state.drawio.svg)

**IDLE**
- The default state, waiting for a new command byte from the UART core.
- Upon receiving a byte, it is treated as the command.
- Then transitions to **ADDR** state.

**ADDR**
- Receives the address for the transaction from UART, **LSB first**.
- After receiving all address bytes:
  - If it's a **read** command -> transitions to **ACCESS**
  - If it's a **write** command -> transitions to **DATA**

**DATA**
- Receives write data from UART, **LSB first**.
- After receiving all data bytes, transitions to **ACCESS**

 **ACCESS**
- Accesses the system bus:
  - For **write**: issues the write on the bus and waits for handshake.
    - On completion, transitions back to **IDLE**
  - For **read**: issues the read and transitions to **READ**

**READ**
- Waits for the read data response from the bus.
- Once data is received, transitions to **SEND**

**SEND**
- Sends the read data back to the host via UART, **LSB first**.
- After all bytes are sent, transitions back to **IDLE**
