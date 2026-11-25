// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: Uart Controller
// Author: Heqing Huang
// Date Created: 06/25/2025
//
// Update: 11/24/2026
// - Make it Uart16550 compatible
//
// -------------------------------------------------------------------
// uart_core: Uart TX + Uart RX
// -------------------------------------------------------------------

module uart_core (
    input        clk,
    input        rst_n,

    input [15:0] cfg_div,
    input        cfg_txen,
    input        cfg_rxen,
    input [1:0]  cfg_word,
    input        cfg_stop,
    input        cfg_parity,
    input        cfg_even_parity,
    input        cfg_stick_parity,
    input        cfg_break,

    input        tx_valid,
    input  [7:0] tx_data,
    output       tx_ready,
    output       rx_valid,
    output [7:0] rx_data,

    output       frame_error,
    output       parity_error,
    output       break_error,

    output       uart_txd,
    input        uart_rxd
);

    // --------------------------------------------
    //  Module instantiation
    // --------------------------------------------

    uart_tx u_uart_tx(.*);
    uart_rx u_uart_rx(.*);

endmodule
