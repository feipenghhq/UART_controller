// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: Uart Controller
// Author: Heqing Huang
// Date Created: 06/25/2025
//
// Update: 11/24/2026
// - Make it Uart16550 compatible
//
// -------------------------------------------------------------------
// uart_tx: UART Transmit module
// -------------------------------------------------------------------

module uart_tx (
    input        clk,
    input        rst_n,
    input [15:0] cfg_div,   // The value set should be equal to (system clock speed) /(16 x desired baud rate)
    input        cfg_txen,
    input [1:0]  cfg_word,
    input        cfg_stop,
    input        cfg_parity,
    input        cfg_even_parity,
    input        cfg_stick_parity,
    input        cfg_break,
    input        tx_valid,
    input [7:0]  tx_data,
    output logic tx_ready,
    output logic uart_txd
);

    // --------------------------------------------
    //  Signal Declaration
    // --------------------------------------------

    logic req;
    logic enable;
    logic baud_tick;
    logic half_baud_tick;
    logic bit_cnt_cmpl;
    logic stop_cmpl;
    logic baud_clear;
    logic parity_bit;

    logic [7:0] tx_data_mask;
    logic [7:0] buffer;
    logic [2:0] bit_cnt;


    typedef enum logic [2:0] {IDLE, START, DATA, PARITY, STOP} state_t;
    state_t state;

    // --------------------------------------------
    //  main logic
    // --------------------------------------------

    assign enable = cfg_txen & (cfg_div != 0);
    assign req = tx_valid & tx_ready & enable;
    assign bit_cnt_cmpl = (bit_cnt == 0) & baud_tick;
    assign baud_clear = (state == IDLE) & req;

    assign tx_data_mask = tx_data & (8'hFF >> (3 - cfg_word));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else begin
        case(state)
            IDLE:   if (req)          state <= START;
            START:  if (bit_cnt_cmpl) state <= DATA;
            DATA:   if (bit_cnt_cmpl) state <= cfg_parity ? PARITY : STOP;
            PARITY: if (bit_cnt_cmpl) state <= STOP;
            STOP:   if (stop_cmpl)    state <= IDLE;
            default: state <= IDLE;
        endcase
        end
    end

    always @(posedge clk) begin
        tx_ready <= 1'b0;
        uart_txd <= 1'b1;
        if (baud_tick) bit_cnt <= bit_cnt - 1'b1;
        case(state)
            IDLE: begin
                uart_txd <= 1'b1;
                buffer <= tx_data_mask;
                tx_ready <= ~req & enable;
                bit_cnt <= 0;
                parity_bit <= (^tx_data_mask) ^ ~cfg_even_parity;
            end
            START: begin
                uart_txd <= 1'b0;
                if (bit_cnt_cmpl) begin
                    case(cfg_word)
                        2'b00: bit_cnt <= 4;
                        2'b01: bit_cnt <= 5;
                        2'b10: bit_cnt <= 6;
                        2'b11: bit_cnt <= 7;
                    endcase
                end
            end
            DATA: begin
                uart_txd <= buffer[0];
                if (baud_tick) buffer <= (buffer >> 1);
                if (bit_cnt_cmpl) begin
                    if (cfg_parity) bit_cnt <= 0;
                    else bit_cnt <= {2'b0, cfg_stop};
                end
            end
            PARITY: begin
                uart_txd <= cfg_stick_parity ? ~cfg_even_parity : parity_bit;
                if (bit_cnt_cmpl) bit_cnt <= {2'b0, cfg_stop};
            end
            STOP: begin
                uart_txd <= 1'b1;
            end
            default: begin end
        endcase

        if (cfg_break) uart_txd <= 1'b0;

    end

    // check when stop bit complete
    always_comb begin
        stop_cmpl = 1'b0;
        if ((cfg_word != 0) || (cfg_stop == 0))  // 1 stop bit or 2 stop bit
            stop_cmpl = bit_cnt_cmpl;
        else // 1.5 stop bit
            stop_cmpl = (bit_cnt == 0) & half_baud_tick;
    end

    // --------------------------------------------
    //  Module instantiation
    // --------------------------------------------

    uart_baud u_uart_baud(
        .clk            (clk),
        .rst_n          (rst_n),
        .cfg_div        (cfg_div),
        .clear          (baud_clear),
        .sample_tick    (),
        .baud_tick      (baud_tick),
        .half_baud_tick (half_baud_tick)
    );

endmodule
