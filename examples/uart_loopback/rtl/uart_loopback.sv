// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: UART Controller
// Author: Heqing Huang
// Date Created: 06/25/2025
//
// -------------------------------------------------------------------
// A Demo program for FPGA. Loop back the RX to TX
// -------------------------------------------------------------------

module fpga_uart_loopback #(
    parameter CLK_FREQ = 50, // (MHz)
    parameter BAUD_RATE = 115200
) (
    input         clk,
    input         rst_n,
    input         uart_rxd,
    output        uart_txd
);

logic [15:0] cfg_div;
logic        cfg_txen;
logic        cfg_rxen;
logic [1:0]  cfg_word;
logic        cfg_stop;
logic        cfg_parity;
logic        cfg_even_parity;
logic        cfg_stick_parity;
logic        cfg_break;
logic        tx_valid;
logic [7:0]  tx_data;
logic        tx_ready;
logic        rx_valid;
logic [7:0]  rx_data;
logic        frame_error;
logic        parity_error;
logic        break_error;

assign cfg_div  = (CLK_FREQ * 1000000) / (16 * BAUD_RATE); // cfg_div = Fclk/(16 * baud)
assign cfg_txen = 1;
assign cfg_rxen = 1;
assign cfg_word = 3;
assign cfg_stop = 0;
assign cfg_parity = 0;
assign cfg_even_parity = 0;
assign cfg_stick_parity = 0;
assign cfg_break = 0;
assign tx_valid = rx_valid;
assign tx_data = rx_data;

uart_core u_uart_core
(.*);

endmodule
