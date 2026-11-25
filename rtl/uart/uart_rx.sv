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
// uart_rx: UART Receiver module
// -------------------------------------------------------------------

module uart_rx (
    input              clk,
    input              rst_n,
    input [15:0]       cfg_div,   // The value set should be equal to (system clock speed) /(16 x desired baud rate)
    input              cfg_rxen,
    input [1:0]        cfg_word,
    input              cfg_stop,
    input              cfg_parity,
    input              cfg_even_parity,
    input              cfg_stick_parity,
    output logic       rx_valid,
    output logic [7:0] rx_data,
    output logic       frame_error,
    output logic       parity_error,
    output logic       break_error,
    input              uart_rxd
);

    // --------------------------------------------
    //  Signal Declaration
    // --------------------------------------------

    logic enable;
    logic sample_tick;
    logic baud_tick;
    logic half_baud_tick;
    logic bit_cnt_cmpl;
    logic stop_cmpl;
    logic baud_clear;

    logic uart_rxd_synced;
    logic uart_rx_final;

    logic parity_bit;
    logic stop_bit;
    logic stop_bit_stored;

    logic rx_cmpl;

    logic [1:0] uart_rxd_sync;
    logic [2:0] bit_cnt;
    logic [2:0] rx_vote3;


    typedef enum logic [2:0] {IDLE, START, DATA, PARITY, STOP} state_t;
    state_t state;

    // --------------------------------------------
    //  main logic
    // --------------------------------------------

    assign enable = cfg_rxen & (cfg_div != 0);
    assign bit_cnt_cmpl = (bit_cnt == 0) & baud_tick;

    // - clear baud counter when we see a potential start signal to align the baud counter
    assign baud_clear = ((state == IDLE) & ~uart_rxd_synced);

    // double flop synchronization for the uart_rxd signal
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) uart_rxd_sync <= 2'b11;
        else uart_rxd_sync <= {uart_rxd_sync[0], uart_rxd};
    end

    assign uart_rxd_synced = uart_rxd_sync[1];

    // majority voter on 3 continuous input to filter input glitch
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_vote3 <= 0;
        else if (sample_tick) rx_vote3 <= {rx_vote3[1:0], uart_rxd_synced};
    end

    always_comb begin
        case (rx_vote3)
            3'b000: uart_rx_final = 1'b0;
            3'b001: uart_rx_final = 1'b0;
            3'b010: uart_rx_final = 1'b0;
            3'b011: uart_rx_final = 1'b1;
            3'b100: uart_rx_final = 1'b0;
            3'b101: uart_rx_final = 1'b1;
            3'b110: uart_rx_final = 1'b1;
            3'b111: uart_rx_final = 1'b1;
        endcase
    end

    // main state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else begin
        case(state)
            IDLE:   if (!uart_rxd_synced && enable) state <= START;
            START:
                    if (half_baud_tick && uart_rx_final) state <= IDLE;
                    else if (baud_tick) state <= DATA;
            DATA:   if (bit_cnt_cmpl) state <= cfg_parity ? PARITY : STOP;
            PARITY: if (bit_cnt_cmpl) state <= STOP;
            STOP:   if (stop_cmpl)    state <= IDLE;
            default: state <= IDLE;
        endcase
        end
    end

    always @(posedge clk) begin
        rx_cmpl <= 1'b0;
        if (baud_tick) bit_cnt <= bit_cnt - 1'b1;
        case(state)
            IDLE: begin
                bit_cnt <= 0;
            end
            START: begin
                // clear the bit at START state, they are used at the beginning of the IDLE state
                rx_data    <= 0;
                parity_bit <= 0;
                stop_bit   <= 0;
                stop_bit_stored <= 0;
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
                if (half_baud_tick) rx_data <= {uart_rx_final, rx_data[7:1]}; // right shift
                if (bit_cnt_cmpl) begin
                    if (cfg_parity) bit_cnt <= 0;
                    else bit_cnt <= {2'b0, cfg_stop};
                end
            end
            PARITY: begin
                if (half_baud_tick) parity_bit <= uart_rx_final;
                if (bit_cnt_cmpl) bit_cnt <= {2'b0, cfg_stop};
            end
            STOP: begin
                // only check the first stop bit. (National Semiconductor PC16550D Datasheet)
                if (half_baud_tick && !stop_bit_stored) begin
                    stop_bit <= uart_rx_final;
                    stop_bit_stored <= 1'b1;
                end
                rx_cmpl <= stop_cmpl;
            end
            default: begin end
        endcase
    end

    // final output
    always @(posedge clk) begin
        rx_valid     <= rx_cmpl;
        break_error  <= ~(|{stop_bit, parity_bit, rx_data}); // all the received bits are zero
        frame_error  <= ~stop_bit;
        parity_error <= ~(cfg_even_parity^(cfg_stick_parity ? parity_bit : parity_bit^(^rx_data)));
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
        .sample_tick    (sample_tick),
        .baud_tick      (baud_tick),
        .half_baud_tick (half_baud_tick)
    );

endmodule
