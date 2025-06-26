// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: Uart Controller
// Author: Heqing Huang
// Date Created: 06/25/2025
//
// -------------------------------------------------------------------
// uart_rx: UART Receiver module
// -------------------------------------------------------------------

module uart_rx (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] cfg_div,
    input  logic        cfg_rxen,
    input  logic        cfg_nstop,
    output logic        rx_valid,
    output logic [7:0]  rx_data,
    input  logic        uart_rxd
);

    // --------------------------------------------
    //  Signal Declaration
    // --------------------------------------------

    logic baud_sample_6th;
    logic baud_sample_8th;
    logic baud_sample_10th;
    logic baud_sample_16th;
    logic baud_clear;

    logic [2:0] data_cnt;
    logic       stop_cnt;
    logic       last_data;
    logic       last_stop;

    logic [1:0] uart_rxd_doublesync;
    logic       uart_rxd_sync;

    logic [2:0] uart_rxd_sample;
    logic       uart_rxd_vote;


    localparam IDLE  = 0;
    localparam START = 1;
    localparam DATA  = 2;
    localparam STOP  = 3;

    logic [1:0] rx_state;
    logic [1:0] rx_state_next;

    logic DATA_S;
    logic STOP_S;

    // --------------------------------------------
    // Main logic
    // --------------------------------------------

    // Synchronization
    always @(posedge clk) begin
        if (!rst_n) begin
            uart_rxd_doublesync <= 2'b0;
        end
        else begin
            uart_rxd_doublesync[0] <= uart_rxd;
            uart_rxd_doublesync[1] <= uart_rxd_doublesync[0];
        end
    end

    assign uart_rxd_sync = uart_rxd_doublesync[1];

    //  RX State Machine
    // state machine
    always @(posedge clk) begin
        if (!rst_n) begin
            rx_state <= IDLE;
        end
        else begin
            rx_state <= rx_state_next;
        end
    end

    always @(*) begin
        rx_state_next = rx_state;
        case(rx_state)
            IDLE: begin
                if (!uart_rxd_sync & cfg_rxen) rx_state_next = START;
            end
            START: begin
                if      (!uart_rxd_vote & baud_sample_16th) rx_state_next = DATA;
                else if (uart_rxd_vote & baud_sample_16th)  rx_state_next = IDLE;
            end
            DATA: begin
                if (last_data & baud_sample_16th) rx_state_next = STOP;
            end
            STOP: begin
                if (last_stop & baud_sample_16th) rx_state_next = IDLE;
            end
        endcase
    end

    assign baud_clear = (rx_state == IDLE) & ~uart_rxd_sync;

    //  2/3 Majority voter
    always @(posedge clk) begin
        if (!rst_n) begin
            uart_rxd_sample <= 3'b0;
        end
        else begin
            if (baud_sample_6th)  uart_rxd_sample[0] <= uart_rxd_sync;
            if (baud_sample_8th)  uart_rxd_sample[1] <= uart_rxd_sync;
            if (baud_sample_10th) uart_rxd_sample[2] <= uart_rxd_sync;
        end
    end

    assign uart_rxd_vote = (uart_rxd_sample[0] & uart_rxd_sample[1]) |
                           (uart_rxd_sample[0] & uart_rxd_sample[2]) |
                           (uart_rxd_sample[1] & uart_rxd_sample[2]) ;

    //  Receive data and stop
    always @(posedge clk) begin
        if (!rst_n) begin
            data_cnt <= 3'b0;
            stop_cnt <= 1'b0;
            rx_data <= 8'b0;
            rx_valid <= 1'b0;
        end
        else begin
            rx_valid <= 1'b0;
            case(rx_state)
                IDLE: begin
                    data_cnt <= 0;
                    stop_cnt <= 0;
                end
                DATA: begin
                    if (baud_sample_16th) begin
                        // LSb received first
                        rx_data <= {uart_rxd_vote, rx_data[7:1]};
                        data_cnt <= data_cnt + 1'b1;
                    end
                end
                STOP: begin
                    if (baud_sample_16th) begin
                        stop_cnt <= stop_cnt + 1'b1;
                    end
                    if (baud_sample_16th && last_stop) begin
                        rx_valid <= 1'b1;
                    end
                end
            endcase
        end
    end

    assign last_data = (data_cnt == 3'd7);
    assign last_stop = (stop_cnt == cfg_nstop);

    // --------------------------------------------
    //  Module instantiation
    // --------------------------------------------

    uart_baud u_uart_baud(
        .clk                (clk             ),
        .rst_n              (rst_n           ),
        .cfg_div            (cfg_div         ),
        .clear              (baud_clear      ),
        .baud_sample_6th    (baud_sample_6th ),
        .baud_sample_8th    (baud_sample_8th ),
        .baud_sample_10th   (baud_sample_10th),
        .baud_sample_16th   (baud_sample_16th)
    );

endmodule
