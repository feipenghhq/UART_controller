// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: UART Controller
// Author: Heqing Huang
// Date Created: 06/25/2025
//
// -------------------------------------------------------------------
// Top level for the Arty FPGA board
// Loopback the RX to TX
// -------------------------------------------------------------------

module top
(
    input         CLOCK_100,    // 100 MHz

    input         RESETn,       // RESET, low active

    input         UART_RXD,
    output        UART_TXD
);

logic           clk;
logic           rst_n;
logic [15:0]    cfg_div;
logic           cfg_txen;
logic           cfg_rxen;
logic           cfg_nstop;
logic           tx_valid;
logic [7:0]     tx_data;
logic           tx_ready;
logic           rx_valid;
logic [7:0]     rx_data;
logic           uart_txd;
logic           uart_rxd;


assign clk = CLOCK_100;
assign rst_n = RESETn;
assign cfg_div = 867; // Baud rate = 115200. cfg_div = Fclk/Fbaud - 1 = 100 * 1000000 / 115200 - 1
assign cfg_txen = 1;
assign cfg_rxen = 1;
assign cfg_nstop = 0;

assign tx_valid = rx_valid;
assign tx_data = rx_data;

assign uart_rxd = UART_RXD;
assign UART_TXD = uart_txd;

uart_core

u_uart_core
(
    .*
);


endmodule
