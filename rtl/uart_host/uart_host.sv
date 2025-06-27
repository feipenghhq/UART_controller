// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: Uart Controller
// Author: Heqing Huang
// Date Created: 06/25/2025
//
// -------------------------------------------------------------------
// uart_host: Use UART as a host interface to read/write on-chip memory
// -------------------------------------------------------------------

module uart_host #(
    parameter ADDR_BYTE = 4,        // number of address byte
    parameter DATA_BYTE = 4,        // number of data byte
    parameter BAUD_RATE = 115200,   // baud rate
    parameter CLK_FREQ  = 100       // clock frequency
) (

    input  logic                   clk,
    input  logic                   rst_n,

    output logic                   uart_txd,
    input  logic                   uart_rxd,

    input  logic                   enable,
    // output bus
    output logic [8*ADDR_BYTE-1:0] address,   // address
    output logic                   wvalid,    // write request
    output logic [8*DATA_BYTE-1:0] wdata,     // write data
    input  logic                   wready,    // write ready
    output logic                   rvalid,    // read request
    input  logic                   rready,    // read ready
    input  logic                   rrvalid,   // read response valid
    input  logic [8*DATA_BYTE-1:0] rdata      // read data
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

    localparam      IDLE    = 0;
    localparam      ADDR    = 1;        // receive command from Uart
    localparam      DATA    = 2;        // receive data from Uart
    localparam      ACCESS  = 3;        // access the bus
    localparam      SEND    = 4;        // send back the data to Uart

    logic [3:0]     state, state_next;
    logic           last_addr_byte;
    logic           last_data_byte;
    logic           rhandshake_complete;  // read request handshake complete, waiting for read data
    logic [$clog2(ADDR_BYTE+1)-1:0] addr_cnt;
    logic [$clog2(DATA_BYTE+1)-1:0] data_cnt;

    localparam      CMD_READ  = 1;
    localparam      CMD_WRITE = 2;
    logic [7:0]     cmd;

    logic [$clog2(DATA_BYTE+1)-1:0] send_cnt;
    logic [DATA_BYTE-1:0][7:0]      rdata_s0;      // read data;
    logic                           last_send;

    // state machine
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
        end
        else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;
        case (state)
            IDLE: if (rx_valid) state_next = ADDR;
            ADDR: if (rx_valid && last_addr_byte) state_next = DATA;
            DATA: if (rx_valid && last_data_byte) state_next = ACCESS;
            ACCESS: if (wvalid && wready) state_next = IDLE; // assuming action will complete before the next command arrives
                    else if (rvalid)      state_next = SEND;
            SEND: if (tx_valid && tx_ready && last_send) state_next = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            cmd <= 0;
        end
        else begin
            case(state)
                IDLE: if (rx_valid) cmd <= rx_data;
                ADDR: if (rx_valid) begin
                    address <= {rx_data, address[8*ADDR_BYTE-1:8]};
                    addr_cnt <= addr_cnt + 1'b1;
                end
                DATA: begin
                    if (rx_valid) wdata <= {rx_data, wdata[8*DATA_BYTE-1:8]};
                    data_cnt <= data_cnt + 1'b1;
                end
                ACCESS: if (rrvalid) rdata_s0 <= rdata;
            endcase
        end
    end

    assign last_addr_byte = (addr_cnt == ADDR_BYTE-1);
    assign last_data_byte = (data_cnt == DATA_BYTE-1);

    // command decode
    always @(posedge clk) begin
        if (!rst_n) begin
            wvalid <= 1'b0;
            rvalid <= 1'b0;
            rhandshake_complete <= 1'b0;
        end
        else begin
            wvalid <= 1'b0;
            if (state == ACCESS) begin
                case(cmd)
                    CMD_WRITE: begin
                        wvalid <= 1'b1;
                    end
                    CMD_READ: begin
                        if (rvalid && rready) rvalid <= 1'b0;
                        else                  rvalid <= ~rhandshake_complete;
                        if (rvalid && rready) rhandshake_complete <= 1'b1;
                        else if (rrvalid)     rhandshake_complete <= 1'b0;
                    end
                endcase
            end
        end
    end

    // uart core
    assign cfg_div = CLK_FREQ/BAUD_RATE - 1;
    assign cfg_txen = enable;
    assign cfg_rxen = enable;
    assign cfg_nstop = 0;

    // send the data back to uart
    always @(posedge clk) begin
        if (!rst_n) begin
            send_cnt <= 0;
        end
        else begin
            if (tx_valid && tx_ready) begin
                if (send_cnt == DATA_BYTE-1) send_cnt <= 0;
                else                         send_cnt <= send_cnt + 1;
            end
        end
    end

    assign tx_valid = rrvalid | (send_cnt > 0);
    assign tx_data  = rdata_s0[send_cnt];
    assign last_send = (send_cnt == DATA_BYTE-1);

    uart_core
    u_uart_core (.*);

endmodule
