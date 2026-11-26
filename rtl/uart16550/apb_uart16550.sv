/*
 * Copyright (c) 2026 Heqing Huang
 * SPDX-License-Identifier: MIT
 */


module apb_uart16550  (
    input        clk,
    input        rst_n,
    // APB
    input        psel,
    input        penable,
    input        pwrite,
    input  [2:0] paddr,
    input  [7:0] pwdata,
    output [7:0] prdata,
    output       pslverr,
    output       pready,
    // UART
    input        uart_rxd,
    output       uart_txd,
    // Interrupt
    output       uart_interrupt
);

    logic       read;
    logic       write;
    logic [2:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
    logic       error;

    assign read  = psel & ~penable & pready & ~pwrite;  // read at the SETUP Phase as we use synchronous read.
    assign write = psel &  penable & pready &  pwrite;   // write should happen at ACCESS Phase.
    assign wdata = pwdata;
    assign addr  = paddr;

    assign prdata = rdata;
    assign pslverr = error;
    assign pready = 1'b1;

    uart16550 u_uart16550(.*);

endmodule
