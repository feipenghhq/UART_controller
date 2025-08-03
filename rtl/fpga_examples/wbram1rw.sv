// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: Wishbone IP
// Author: Heqing Huang
// Date Created: 08/03/2025
//
// -------------------------------------------------------------------
// wbram1rw: Access FPGA on-chip RAM with Wishbone Interface
// - 1 read/write port
// - Wishbone B4 Pipeline Interface
// -------------------------------------------------------------------

module wbram1rw #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter BYTE_WIDTH = 8,
    parameter NUM_BYTES  = DATA_WIDTH / BYTE_WIDTH
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [DATA_WIDTH-1:0]   wb_dat_i,
    output logic [DATA_WIDTH-1:0]   wb_dat_o,
    input  logic                    wb_cyc_i,
    input  logic                    wb_stb_i,
    input  logic                    wb_we_i,
    input  logic [ADDR_WIDTH-1:0]   wb_adr_i,
    input  logic [NUM_BYTES -1:0]   wb_sel_i,
    output logic                    wb_ack_o,
    output logic                    wb_stall_o
);

    localparam DEPTH = 2**ADDR_WIDTH;

    logic [NUM_BYTES-1:0][BYTE_WIDTH-1:0] ram[0:DEPTH-1];
    logic                 we;
    logic [NUM_BYTES-1:0] be;
    logic                 wb_act;

    assign wb_act = wb_cyc_i & wb_stb_i & ~wb_stall_o;
    assign we = wb_act & wb_we_i;
    assign be = wb_sel_i;

    always@(posedge clk)
    begin
	     if(we) begin
           for (int i = 0; i < NUM_BYTES; i = i + 1) begin
             if(be[i]) ram[wb_adr_i][i] <= wb_dat_i[i*BYTE_WIDTH +: BYTE_WIDTH];
           end
       end
       wb_dat_o <= ram[wb_adr_i];
    end

    assign wb_stall_o = 1'b0;

    always_ff @(posedge clk) begin
        if (!rst_n) wb_ack_o <= 1'b0;
        else wb_ack_o <= wb_act;
    end

endmodule
