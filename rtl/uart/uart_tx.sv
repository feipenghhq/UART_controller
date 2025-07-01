// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: Uart Controller
// Author: Heqing Huang
// Date Created: 06/25/2025
//
// -------------------------------------------------------------------
// uart_tx: UART Transmit module
// -------------------------------------------------------------------

module uart_tx (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [15:0] cfg_div,
    input  logic        cfg_txen,
    input  logic        cfg_nstop,

    input  logic        tx_valid,
    input  logic [7:0]  tx_data,
    output logic        tx_ready,

    output logic        uart_txd
);

    // --------------------------------------------
    //  Signal Declaration
    // --------------------------------------------

    logic baud_sample_16th;
    logic baud_clear;

    logic [9:0] uart_data; // {stop, data, start}
    logic [2:0] data_cnt;
    logic       stop_cnt;
    logic       last_data;
    logic       last_stop;

    // state machine
    localparam IDLE  = 0;
    localparam START = 1;
    localparam DATA  = 2;
    localparam STOP  = 3;

    logic [1:0] tx_state;
    logic [1:0] tx_state_next;

    // --------------------------------------------
    // Main logic
    // --------------------------------------------

    // state machine
    always @(posedge clk) begin
        if (!rst_n) begin
            tx_state <= IDLE;
        end
        else begin
            tx_state <= tx_state_next;
        end
    end

    always @(*) begin
        tx_state_next = tx_state;
        case(tx_state)
            IDLE: begin
                if (tx_valid && tx_ready && cfg_txen) tx_state_next = START;
            end
            START: begin
                if (baud_sample_16th) tx_state_next = DATA;
            end
            DATA: begin
                if (baud_sample_16th && last_data) tx_state_next = STOP;
            end
            STOP: begin
                if (baud_sample_16th && last_stop) tx_state_next = IDLE;
            end
        endcase
    end

    // uart_data
    // uart data include the start bit, the data bits and the stop bits
    always @(posedge clk) begin
        if (!rst_n) begin
            data_cnt <= 3'b0;
            stop_cnt <= 1'b0;
            uart_data <= 10'b1; // LSB should be reset to one to make uart_txd default high.
            tx_ready <= 1'b0;
        end
        else begin

            tx_ready <= 1'b0;

            case (tx_state)
                IDLE: begin
                    tx_ready <= 1'b1;
                    data_cnt <= 0;
                    stop_cnt <= 0;
                    uart_data <= 10'h1;
                    if (tx_valid && tx_ready) begin
                        uart_data <= {1'b1, tx_data, 1'b0}; // stop, data, start
                        tx_ready <= 1'b0;
                    end
                end
                START: begin
                    if (baud_sample_16th) begin
                        uart_data <= (uart_data >> 1);
                    end
                end
                DATA: begin
                    // The UART module transmits and receives the Least Significant bit (LSb) first
                    // Shift on the 16th sample tick in START and DATA state.
                    // No need to shift on the STOP state as the data is fixed to 1 for stop bit.
                    if (baud_sample_16th) begin
                        uart_data <= (uart_data >> 1);
                        data_cnt <= data_cnt + 1'b1;
                    end
                end
                STOP: begin
                    if (baud_sample_16th) begin
                        stop_cnt <= stop_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

    assign last_data = (data_cnt == 3'd7);
    assign last_stop = (stop_cnt == cfg_nstop);

    // --------------------------------------------
    // uart_txd and misc
    // --------------------------------------------

    assign uart_txd = uart_data[0];
    assign baud_clear = (tx_state == IDLE) & tx_valid;

    // --------------------------------------------
    //  Module instantiation
    // --------------------------------------------

    uart_baud u_uart_baud(
        .clk                (clk),
        .rst_n              (rst_n),
        .cfg_div            (cfg_div),
        .clear              (baud_clear),
        .baud_sample_6th    (),
        .baud_sample_8th    (),
        .baud_sample_10th   (),
        .baud_sample_16th   (baud_sample_16th)
    );

endmodule
