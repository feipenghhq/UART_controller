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
    parameter CLK_FREQ = 50 // (MHz)
) (
    input         clk,
    input         rst_n,
    input         uart_rxd,
    output        uart_txd
);

logic [15:0]    cfg_div;
logic           cfg_txen;
logic           cfg_rxen;
logic           cfg_nstop;
logic           tx_valid;
logic [7:0]     tx_data;
logic           tx_ready;
logic           rx_valid;
logic [7:0]     rx_data;

assign cfg_div   = CLK_FREQ * 1000000 / 115200 - 1; // cfg_div = Fclk/baud - 1
assign cfg_txen  = 1;
assign cfg_rxen  = 1;
assign cfg_nstop = 0;

assign tx_valid = rx_valid;
assign tx_data = rx_data;

uart_core u_uart_core
(
    .*
);

endmodule
