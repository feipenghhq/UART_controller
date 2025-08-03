// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: Uart Controller
// Author: Heqing Huang
// Date Created: 06/25/2025
//
// -------------------------------------------------------------------
// uart2wb: UART to Wishbone
// - Use UART as a host interface to read/write on-chip memory
// - Wishbone B4 pipeline protocol
// -------------------------------------------------------------------

module uart2wb #(
    parameter ADDR_BYTE = 2,        // number of address byte
    parameter DATA_BYTE = 2,        // number of data byte
    parameter BAUD_RATE = 115200,   // baud rate
    parameter CLK_FREQ  = 100,      // clock frequency
    parameter AW = 8 * ADDR_BYTE,
    parameter DW = 8 * DATA_BYTE
) (

    input  logic            clk,
    input  logic            rst_n,

    input  logic            enable,

    output logic            uart_txd,
    input  logic            uart_rxd,

    // reset control
    output logic            rst_n_out,

    // wishbone b4
    output logic            wb_cyc_o,
    output logic            wb_stb_o,
    output logic            wb_we_o,
    output logic [AW-1:0]   wb_adr_o,
    input  logic [DW-1:0]   wb_dat_i,
    output logic [DW-1:0]   wb_dat_o,
    input  logic            wb_ack_i,
    input  logic            wb_stall_i
);

/////////////////////////////////////////////////
// Signal Declaration
/////////////////////////////////////////////////

localparam DIV = (CLK_FREQ * 1000000) / BAUD_RATE - 1;

typedef enum logic [3:0] {
    IDLE,
    ADDR,   // receive command from Uart
    DATA,   // receive data from Uart
    ACCESS, // access the bus
    READ,   // Wait for the read data
    SEND    // send back the data to Uart
} state_t;

typedef enum logic [7:0] {
    CMD_NOP   = 8'h00,  // NOP
    CMD_READ  = 8'h01,  // single read
    CMD_WRITE = 8'h02,  // single write
    CMD_RST_A = 8'hFE,  // reset assertion
    CMD_RST_D = 8'hFF   // reset de-assertion
} cmd_t;


state_t         state, state_next;
cmd_t           cmd;
logic           write_cmd;
logic           rst_cmd;

logic           wb_act; // bus action

logic [15:0]    cfg_div;
logic           cfg_txen;
logic           cfg_rxen;
logic           cfg_nstop;
logic           tx_valid;
logic [7:0]     tx_data;
logic           tx_ready;
logic           rx_valid;
logic [7:0]     rx_data;

logic           last_addr_byte;
logic           last_data_byte;

logic [$clog2(ADDR_BYTE+1)-1:0] addr_cnt;
logic [$clog2(DATA_BYTE+1)-1:0] data_cnt;
logic [$clog2(DATA_BYTE+1)-1:0] send_cnt;

logic [DATA_BYTE-1:0][7:0]      read_data;      // read data;
logic                           last_send;

/////////////////////////////////////////////////
// signal declaration
/////////////////////////////////////////////////

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
        IDLE: begin
            if (rx_valid & !rst_cmd) state_next = ADDR;
        end
        ADDR: begin
            if (rx_valid && last_addr_byte) begin
                if (write_cmd) state_next = DATA;
                else           state_next = ACCESS;
            end
        end
        DATA: begin
            if (rx_valid && last_data_byte) state_next = ACCESS;
        end
        ACCESS: begin
            // assuming action will complete before the next command arrives
            if      (wb_act &&  wb_we_o) state_next = IDLE;
            else if (wb_act && !wb_we_o) state_next = READ;
        end
        READ: begin
            state_next = SEND;
        end
        SEND: begin
            if (tx_valid && tx_ready && last_send) state_next = IDLE;
        end
    endcase
end

assign wb_act = wb_cyc_o & wb_stb_o & ~wb_stall_i;
assign last_addr_byte = (addr_cnt == 0);
assign last_data_byte = (data_cnt == 0);

// Receive command from Uart
always @(posedge clk) begin
    if (!rst_n) begin
        cmd <= CMD_NOP;
    end
    else begin
        if (state == IDLE && rx_valid) begin
            cmd <= cmd_t'(rx_data);
        end
    end
end

// Receive address and data from Uart
always @(posedge clk) begin
    case(state)
        IDLE: begin
            wb_adr_o <= '0;
            wb_dat_o <= '0;
            addr_cnt <= ADDR_BYTE-1;
            data_cnt <= DATA_BYTE-1;
        end
        ADDR: begin
            if (rx_valid) begin
                wb_adr_o <= {rx_data, wb_adr_o[8*ADDR_BYTE-1:8]};
                addr_cnt <= addr_cnt - 1'b1;
            end
        end
        DATA: begin
            if (rx_valid) begin
                wb_dat_o <= {rx_data, wb_dat_o[8*DATA_BYTE-1:8]};
                data_cnt <= data_cnt - 1'b1;
            end
        end
        READ: read_data <= wb_dat_i;
    endcase
end


assign rst_cmd   = (rx_data == CMD_RST_A) |
                   (rx_data == CMD_RST_D) ;

assign write_cmd = cmd == CMD_WRITE;

// Wishbone bus logic
always @(posedge clk) begin
    if (!rst_n) begin
        wb_cyc_o <= 1'b0;
        wb_stb_o <= 1'b0;
        wb_we_o  <= 1'b0;
    end
    else begin

        wb_stb_o <= 1'b0;
        wb_we_o  <= 1'b0;
        if (state_next == ACCESS) begin
            wb_stb_o <= 1'b1;
            case(cmd)
                CMD_WRITE: wb_we_o <= 1'b1;
                CMD_READ:  wb_we_o <= 1'b0;
            endcase
        end

        if (state_next == ACCESS) wb_cyc_o <= 1'b1;
        else if (wb_ack_i)        wb_cyc_o <= 1'b0;
    end
end

// output reset
always @(posedge clk) begin
    if (!rst_n) rst_n_out <= 1'b1;
    else if (cmd == CMD_RST_A) rst_n_out <= 1'b0;
    else if (cmd == CMD_RST_D) rst_n_out <= 1'b1;
end

// send the read data back through uart
always @(posedge clk) begin
    if (!rst_n) begin
        send_cnt <= 0;
    end
    else begin
        if (state != SEND) send_cnt <= 0;
        else if (tx_valid && tx_ready) send_cnt <= send_cnt + 1'b1;
    end
end

assign tx_valid  = state == SEND;
assign tx_data   = read_data[send_cnt];
assign last_send = send_cnt == DATA_BYTE - 1;

// uart core
assign cfg_div = DIV[15:0];
assign cfg_txen = enable;
assign cfg_rxen = enable;
assign cfg_nstop = 0;

uart_core
u_uart_core (.*);

endmodule
