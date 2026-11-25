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
// -------------------------------------------------------------------

module top
(
    input         CLOCK_50,     // 50 MHz
    input         RESETn,       // RESETn Mapped to KEY[0]
    output        LED,
    input         UART_RXD,
    output        UART_TXD
);

uart2wbram #(.CLK_FREQ(50))
u_uart2wb_ram (
    .clk      (CLOCK_50),
    .rst_n    (RESETn),
    .rst_n_out(LED),
    .uart_rxd (UART_RXD),
    .uart_txd (UART_TXD)
);

endmodule
