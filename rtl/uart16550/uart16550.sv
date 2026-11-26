/*
 * Copyright (c) 2026 Heqing Huang
 * SPDX-License-Identifier: MIT
 */



module uart16550  (
    input        clk,
    input        rst_n,
    // general bus interface
    input        read,
    input        write,
    input  [2:0] addr,
    input  [7:0] wdata,
    output [7:0] rdata,
    output       error,
    // UART
    input        uart_rxd,
    output       uart_txd,
    // Interrupt
    output       uart_interrupt
);

    // FIFO Configuration
    logic       fifo_enable;
    logic       fifo_reset_tx;
    logic       fifo_reset_rx;

    // Uart configuration
    logic [15:0] cfg_div;
    logic       cfg_txen;
    logic       cfg_rxen;
    logic [1:0] cfg_word;
    logic       cfg_stop;
    logic       cfg_parity;
    logic       cfg_even_parity;
    logic       cfg_stick_parity;
    logic       cfg_break;

    // UART read and write interface
    logic       reg_tx_valid;
    logic       reg_tx_ready;
    logic [7:0] reg_tx_data;
    logic       reg_rx_valid;
    logic       reg_rx_ready;
    logic [7:0] reg_rx_data;

    logic       core_tx_valid;
    logic       core_tx_ready;
    logic [7:0] core_tx_data;
    logic       core_rx_valid;
    logic [7:0] core_rx_data;

    logic       core_parity_error;
    logic       reg_parity_error;
    logic       core_frame_error;
    logic       reg_frame_error;
    logic       core_break_error;
    logic       reg_break_error;

    logic       fifo_overrun;

    // FIFO interfaces
    logic       tx_fifo_push_valid;
    logic       tx_fifo_push_ready;
    logic       tx_fifo_pop_valid;
    logic       tx_fifo_pop_ready;
    logic [7:0] tx_fifo_pop_data;
    logic [4:0] tx_fifo_count;

    logic        rx_fifo_push_valid;
    logic        rx_fifo_push_ready;
    logic        rx_fifo_pop_valid;
    logic        rx_fifo_pop_ready;
    // RX entry: {break_error, frame_error, parity_error, data[7:0]}
    logic [10:0] rx_fifo_pop_data;

    // Status
    logic       rx_fifo_full;
    logic [4:0] rx_fifo_count;
    logic [4:0] rx_fifo_error_count;
    logic       tx_fifo_empty;

    // ------------------------------------------
    // Glue Logic
    // ------------------------------------------

    // UART enable
    assign cfg_txen = cfg_div != 0;
    assign cfg_rxen = cfg_txen;

    // TX FIFO / UART TX
    assign tx_fifo_push_valid = fifo_enable & reg_tx_valid;
    assign tx_fifo_pop_ready  = fifo_enable & core_tx_ready;
    assign core_tx_valid = fifo_enable & tx_fifo_pop_valid  | ~fifo_enable & reg_tx_valid;
    assign core_tx_data  = fifo_enable ? tx_fifo_pop_data : reg_tx_data;
    assign reg_tx_ready  = fifo_enable & tx_fifo_push_ready | ~fifo_enable & core_tx_ready;

    // RX FIFO / UART RX
    assign rx_fifo_push_valid = fifo_enable & core_rx_valid;
    assign rx_fifo_pop_ready  = fifo_enable & reg_rx_ready;
    assign reg_rx_valid = fifo_enable & rx_fifo_pop_valid | ~fifo_enable & core_rx_valid;
    assign reg_rx_data  = fifo_enable ? rx_fifo_pop_data[7:0] : core_rx_data;
    assign reg_parity_error = fifo_enable & rx_fifo_pop_data[8]  | ~fifo_enable & core_parity_error;
    assign reg_frame_error  = fifo_enable & rx_fifo_pop_data[9]  | ~fifo_enable & core_frame_error;
    assign reg_break_error  = fifo_enable & rx_fifo_pop_data[10] | ~fifo_enable & core_break_error;

    // FIFO status
    assign fifo_overrun = fifo_enable & rx_fifo_full & rx_fifo_push_valid & ~rx_fifo_pop_ready;

    // ------------------------------------------
    // Module Instantiation
    // ------------------------------------------

    uart16550_reg u_uart16550_reg (
        .clk                  (clk),
        .rst_n                (rst_n),
        .read                 (read),
        .write                (write),
        .addr                 (addr),
        .wdata                (wdata),
        .rdata                (rdata),
        .error                (error),
        .fifo_enable          (fifo_enable),
        .fifo_reset_tx        (fifo_reset_tx),
        .fifo_reset_rx        (fifo_reset_rx),
        .cfg_div              (cfg_div),
        .cfg_word             (cfg_word),
        .cfg_stop             (cfg_stop),
        .cfg_parity           (cfg_parity),
        .cfg_even_parity      (cfg_even_parity),
        .cfg_stick_parity     (cfg_stick_parity),
        .cfg_break            (cfg_break),
        .rx_valid             (reg_rx_valid),
        .rx_ready             (reg_rx_ready),
        .rx_data              (reg_rx_data),
        .parity_error         (reg_parity_error),
        .frame_error          (reg_frame_error),
        .break_error          (reg_break_error),
        .fifo_overrun         (fifo_overrun),
        .tx_valid             (reg_tx_valid),
        .tx_ready             (reg_tx_ready),
        .tx_data              (reg_tx_data),
        .rx_fifo_count        (rx_fifo_count),
        .rx_fifo_error_count  (rx_fifo_error_count),
        .tx_fifo_empty        (tx_fifo_empty),
        .uart_interrupt       (uart_interrupt)
    );

    uart16550_fifo #(
        .RX_FIFO              (0)
    ) u_tx_fifo (
        .clk                  (clk),
        .rst_n                (rst_n),
        .flush                (fifo_reset_tx),
        .push_valid           (tx_fifo_push_valid),
        .push_ready           (tx_fifo_push_ready),
        .push_data            (reg_tx_data),
        .pop_valid            (tx_fifo_pop_valid),
        .pop_ready            (tx_fifo_pop_ready),
        .pop_data             (tx_fifo_pop_data),
        .full                 (),
        .empty                (tx_fifo_empty),
        .count                (tx_fifo_count),
        .error_count          ()
    );

    uart16550_fifo #(
        .RX_FIFO              (1)
    ) u_rx_fifo (
        .clk                  (clk),
        .rst_n                (rst_n),
        .flush                (fifo_reset_rx),
        .push_valid           (rx_fifo_push_valid),
        .push_ready           (rx_fifo_push_ready),
        .push_data            ({core_break_error, core_frame_error, core_parity_error, core_rx_data}),
        .pop_valid            (rx_fifo_pop_valid),
        .pop_ready            (rx_fifo_pop_ready),
        .pop_data             (rx_fifo_pop_data),
        .full                 (rx_fifo_full),
        .empty                (),
        .count                (rx_fifo_count),
        .error_count          (rx_fifo_error_count)
    );

    uart_core u_uart_core (
        .clk                  (clk),
        .rst_n                (rst_n),
        .cfg_div              (cfg_div),
        .cfg_txen             (cfg_txen),
        .cfg_rxen             (cfg_rxen),
        .cfg_word             (cfg_word),
        .cfg_stop             (cfg_stop),
        .cfg_parity           (cfg_parity),
        .cfg_even_parity      (cfg_even_parity),
        .cfg_stick_parity     (cfg_stick_parity),
        .cfg_break            (cfg_break),
        .tx_valid             (core_tx_valid),
        .tx_data              (core_tx_data),
        .tx_ready             (core_tx_ready),
        .rx_valid             (core_rx_valid),
        .rx_data              (core_rx_data),
        .frame_error          (core_frame_error),
        .parity_error         (core_parity_error),
        .break_error          (core_break_error),
        .uart_txd             (uart_txd),
        .uart_rxd             (uart_rxd)
    );

endmodule
