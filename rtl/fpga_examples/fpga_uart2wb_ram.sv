// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: UART Controller
// Author: Heqing Huang
// Date Created: 08/03/2025
//
// -------------------------------------------------------------------
// A Demo program for FPGA. Use uart2wb to access FPGA on-chip RAM
// -------------------------------------------------------------------

module fpga_uart2wb_ram #(
    parameter ADDR_BYTE = 1,
    parameter DATA_BYTE = 2,
    parameter BAUD_RATE = 115200,
    parameter CLK_FREQ  = 100
) (
    input  logic clk,
    input  logic rst_n,
    output logic rst_n_out,
    input  logic uart_rxd,
    output logic uart_txd
);

    localparam ADDR_WIDTH = 8 * ADDR_BYTE;
    localparam DATA_WIDTH = 8 * DATA_BYTE;
    localparam SEL_WIDTH  = DATA_BYTE;

    // Wishbone signals
    logic                   wb_cyc;
    logic                   wb_stb;
    logic                   wb_we;
    logic [ADDR_WIDTH-1:0]  wb_adr;
    logic [DATA_WIDTH-1:0]  wb_dat_i_from_ram;
    logic [DATA_WIDTH-1:0]  wb_dat_o_from_uart;
    logic                   wb_ack;
    logic                   wb_stall;
    logic [SEL_WIDTH-1:0]   wb_sel;

    assign wb_sel = {SEL_WIDTH{1'b1}};

    uart2wb #(
        .ADDR_BYTE(ADDR_BYTE),
        .DATA_BYTE(DATA_BYTE),
        .BAUD_RATE(BAUD_RATE),
        .CLK_FREQ (CLK_FREQ)
    ) u_uart2wb (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (1'b1),
        .uart_txd   (uart_txd),
        .uart_rxd   (uart_rxd),
        .rst_n_out  (rst_n_out),
        .wb_cyc_o   (wb_cyc),
        .wb_stb_o   (wb_stb),
        .wb_we_o    (wb_we),
        .wb_adr_o   (wb_adr),
        .wb_dat_i   (wb_dat_i_from_ram),
        .wb_dat_o   (wb_dat_o_from_uart),
        .wb_ack_i   (wb_ack),
        .wb_stall_i (wb_stall)
    );

    wbram1rw #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_ram (
        .clk        (clk),
        .rst_n      (rst_n),
        .wb_dat_i   (wb_dat_o_from_uart),
        .wb_dat_o   (wb_dat_i_from_ram),
        .wb_cyc_i   (wb_cyc),
        .wb_stb_i   (wb_stb),
        .wb_we_i    (wb_we),
        .wb_adr_i   (wb_adr),
        .wb_sel_i   (wb_sel),
        .wb_ack_o   (wb_ack),
        .wb_stall_o (wb_stall)
    );

endmodule
