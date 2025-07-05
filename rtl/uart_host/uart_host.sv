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
    parameter ADDR_BYTE = 2,        // number of address byte
    parameter DATA_BYTE = 2,        // number of data byte
    parameter BAUD_RATE = 115200,   // baud rate
    parameter CLK_FREQ  = 100       // clock frequency
) (

    input  logic                   clk,
    input  logic                   rst_n,

    output logic                   uart_txd,
    input  logic                   uart_rxd,

    input  logic                   enable,

    // output bus
    output logic                   rst_n_out, // reset output
    output logic [8*ADDR_BYTE-1:0] address,   // address
    output logic                   wvalid,    // write request
    output logic [8*DATA_BYTE-1:0] wdata,     // write data
    input  logic                   wready,    // write ready
    output logic                   rvalid,    // read request
    input  logic                   rready,    // read ready
    input  logic                   rrvalid,   // read response valid
    input  logic [8*DATA_BYTE-1:0] rdata      // read data
);

    localparam CFG_DIV = (CLK_FREQ * 1000000) / BAUD_RATE - 1;

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
    localparam      READ    = 4;        // Wait for the read data
    localparam      SEND    = 5;        // send back the data to Uart

    logic [3:0]     state, state_next;
    logic           last_addr_byte;
    logic           last_data_byte;
    logic [$clog2(ADDR_BYTE+1)-1:0] addr_cnt;
    logic [$clog2(DATA_BYTE+1)-1:0] data_cnt;

    localparam      CMD_READ  = 8'h1,
                    CMD_WRITE = 8'h2,
                    CMD_RST_A = 8'hFE,  // reset assertion
                    CMD_RST_D = 8'hFF;  // reset de-assertion
    logic [7:0]     cmd;
    logic           write_cmd;

    logic                           rst_cmd;       // reset related command
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
            IDLE: if (rx_valid & !rst_cmd) state_next = ADDR;
            ADDR: begin
                if (rx_valid && last_addr_byte) begin
                    if (write_cmd) state_next = DATA;
                    else           state_next = ACCESS;
                end
            end
            DATA: if (rx_valid && last_data_byte) state_next = ACCESS;
            ACCESS: begin
                if (wvalid && wready)      state_next = IDLE; // assuming action will complete before the next command arrives
                else if (rvalid && rready) state_next = READ;
            end
            READ: if (rrvalid) state_next = SEND;
            SEND: if (tx_valid && tx_ready && last_send) state_next = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) cmd <= 0;
        else if (state == IDLE && rx_valid) begin
            cmd <= rx_data;
        end
    end

    always @(posedge clk) begin
        case(state)
            IDLE: begin
                address  <= '0;
                addr_cnt <= '0;
                data_cnt <= '0;
            end
            ADDR: begin
                if (rx_valid) begin
                    address <= {rx_data, address[8*ADDR_BYTE-1:8]};
                    addr_cnt <= addr_cnt + 1'b1;
                end
            end
            DATA: begin
                if (rx_valid) begin
                    wdata <= {rx_data, wdata[8*DATA_BYTE-1:8]};
                    data_cnt <= data_cnt + 1'b1;
                end
            end
            READ: if (rrvalid) rdata_s0 <= rdata;
        endcase
    end

    assign rst_cmd = (rx_data == CMD_RST_A) | (rx_data == CMD_RST_D);
    assign write_cmd = (cmd == CMD_WRITE) ? 1'b1 : 1'b0;
    assign last_addr_byte = (addr_cnt == ADDR_BYTE-1);
    assign last_data_byte = (data_cnt == DATA_BYTE-1);

    // decode command and send request to the bus
    always @(posedge clk) begin
        if (!rst_n) begin
            wvalid <= 1'b0;
            rvalid <= 1'b0;
        end
        else begin
            wvalid <= 1'b0;
            rvalid <= 1'b0;
            if (state_next == ACCESS) begin // use next state here so the bus request align with state
                /* verilator lint_off CASEINCOMPLETE */
                case(cmd)
                /* verilator lint_on CASEINCOMPLETE */
                    CMD_WRITE: begin
                        wvalid <= 1'b1;
                    end
                    CMD_READ: begin
                        rvalid <= 1'b1;
                    end
                endcase
            end
        end
    end

    // output reset
    always @(posedge clk) begin
        if (!rst_n) rst_n_out <= 1'b1;
        else if (cmd == CMD_RST_A) rst_n_out <= 1'b0;
        else if (cmd == CMD_RST_D) rst_n_out <= 1'b1;
    end

    // uart core
    assign cfg_div = CFG_DIV[15:0];
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

    assign tx_valid = (state == SEND) | (send_cnt > 0);
    assign tx_data  = rdata_s0[send_cnt];
    assign last_send = (send_cnt == DATA_BYTE-1);

    uart_core
    u_uart_core (.*);

endmodule
