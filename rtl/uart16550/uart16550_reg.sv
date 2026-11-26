/*
 * Copyright (c) 2026 Heqing Huang
 * SPDX-License-Identifier: MIT
 */

module uart16550_reg  (
    input              clk,
    input              rst_n,
    // general bus interface
    input              read,
    input              write,
    input [2:0]        addr,
    input [7:0]        wdata,
    output logic [7:0] rdata,
    output logic       error,
    // FIFO Configuration
    output             fifo_enable,
    output logic       fifo_reset_tx,
    output logic       fifo_reset_rx,
    output logic [15:0] cfg_div,
    output logic [1:0] cfg_word,
    output             cfg_stop,
    output             cfg_parity,
    output             cfg_even_parity,
    output             cfg_stick_parity,
    output             cfg_break,
    // UART read and write interface
    input              rx_valid,
    output             rx_ready,
    input  [7:0]       rx_data,
    input              parity_error,
    input              frame_error,
    input              break_error,
    input              fifo_overrun,
    output             tx_valid,
    input              tx_ready,
    output logic [7:0] tx_data,
    // Status
    input [4:0]        rx_fifo_count,
    input [4:0]        rx_fifo_error_count,
    input              tx_fifo_empty,
    output logic       uart_interrupt
);

    // register address
    localparam RHR = 0, THR = 0, DLL = 0;
    localparam IER = 1, DLM = 1;
    localparam ISR = 2, FCR = 2;
    localparam LCR = 3;
    localparam MCR = 4;
    localparam LSR = 5;
    localparam MSR = 6;
    localparam SPR = 7;

    // ------------------------------------------
    // Signal
    // ------------------------------------------

    logic [7:0][7:0] register;
    logic [15:0] divisor_latch;

    logic read_RHR;
    logic write_THR;

    // Register Field
    logic LCR_DLAB;
    logic fifo_enabled;
    logic fifo_enable_r;

    // Register to store RX data
    logic RHR_reg_valid;
    logic [7:0] RHR_reg;
    logic parity_error_r;
    logic framing_error_r;
    logic break_interrupt_r;

    // Register to store TX data
    logic THR_reg_valid;
    logic [7:0] THR_reg;

    logic rcv_line_status;
    logic rcv_data_ready;
    logic timer_start;
    logic reception_timeout;
    logic [31:0] timer;
    logic [31:0] timeout_limit;
    logic rx_fifo_trigger;
    logic [4:0] rx_fifo_trigger_level;
    logic tx_holding_empty;

    logic interrupt_status;
    logic [2:0] interrupt_code;

    // LSR Error
    logic RHR_overrun;
    logic overrun_error;
    logic overrun_error_r;
    logic fifo_data_error_r;

    // ------------------------------------------
    // Register field
    // ------------------------------------------

    assign LCR_DLAB = register[LCR][7];

    assign fifo_enabled = register[FCR][0];

    // ------------------------------------------
    // Register Access
    // ------------------------------------------

    assign read_RHR = ~LCR_DLAB & read & addr == RHR;
    assign write_THR = !LCR_DLAB & write & addr == THR;

    // Register read
    always_ff @(posedge clk or negedge clk) begin
        case(addr)
        RHR, DLL: rdata <= LCR_DLAB ? divisor_latch[7:0] : fifo_enable ? rx_data : RHR_reg;
        IER, DLM: rdata <= LCR_DLAB ? divisor_latch[15:8] : register[IER];
        ISR: rdata <= {fifo_enabled, fifo_enabled, 2'b0, interrupt_code, interrupt_status};
        LCR: rdata <= register[LCR];
        MCR: rdata <= register[MCR];
        LSR: begin
            rdata[0] <= fifo_enable & rx_valid | ~fifo_enable & RHR_reg_valid;
            rdata[1] <= overrun_error_r;
            rdata[2] <= parity_error_r;
            rdata[3] <= framing_error_r;
            rdata[4] <= break_interrupt_r;
            rdata[5] <= fifo_enable & tx_fifo_empty | ~fifo_enable & ~THR_reg_valid;
            rdata[6] <= (fifo_enable & tx_fifo_empty | ~fifo_enable & ~THR_reg_valid) & tx_ready;
            rdata[7] <= fifo_enable & (rx_fifo_error_count > 0);
        end
        MSR: rdata <= 0; // Not implemented yet
        SPR: rdata <= register[SPR];
        endcase
    end

    // Register Write
    always_ff @(posedge clk or negedge clk) begin
        if (!rst_n) begin
            register <= 0;
        end
        else if (write) begin
            register[FCR][1] <= 0; // RX FIFO reset - return to 0 automatically
            register[FCR][2] <= 0; // TX FIFO reset - return to 0 automatically
            case(addr)
            THR, DLL: if (LCR_DLAB) divisor_latch[7:0] <= wdata;
            IER, DLM: begin
                if (LCR_DLAB) divisor_latch[15:8] <= wdata;
                else register[IER] <= wdata;
            end
            FCR: register[FCR] <= wdata;
            LCR: register[LCR] <= wdata;
            MCR: register[MCR] <= wdata;
            SPR: register[SPR] <= wdata;
            endcase
        end
    end

    // ------------------------------------------
    // Uart Read/Write
    // ------------------------------------------

    // RX
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            RHR_reg_valid <= 1'b0;
            RHR_reg <= 0;
            parity_error_r <= 1'b0;
            framing_error_r <= 1'b0;
            break_interrupt_r <= 1'b0;
        end
        else begin
            // RHR register for non FIFO mode
            if (rx_valid && rx_ready && !fifo_enable) begin
                RHR_reg_valid <= 1'b1;
                RHR_reg <= rx_data;
            end
            else if (read_RHR) begin
                RHR_reg_valid <= 1'b0;
            end

            if (rx_valid && rx_ready) begin
                parity_error_r <= parity_error;
                framing_error_r <= frame_error;
                break_interrupt_r <= break_error;
            end
        end
    end

    // If RHR overrun, new character will override the existing one, so in non FIFO mode it is always ready to receive
    assign rx_ready = ~fifo_enabled | read_RHR;

    // TX
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            THR_reg_valid <= 1'b0;
            THR_reg <= 0;
            tx_valid <= 1'b0;
            tx_data <= 0;
        end
        else begin
            // THR register for non FIFO mode
            if (write_THR) begin
                THR_reg_valid <= 1'b1;
                THR_reg <= wdata;
            end
            else if (tx_valid && tx_ready) begin
                THR_reg_valid <= 1'b0;
            end
            // Send TX request to UART
            tx_valid <= 0;
            tx_data <= 0;
            if (fifo_enable && write_THR) begin
                tx_valid <= 1'b1;
                tx_data <= wdata;
            end
            else if (THR_reg_valid) begin
                tx_valid <= 1'b1;
                tx_data <= THR_reg;
            end
        end
    end

    // ------------------------------------------
    // Configuration
    // ------------------------------------------

    always_ff @(posedge clk) fifo_enable_r <= fifo_enable;

    assign fifo_enable = register[FCR][0];

    assign fifo_reset_tx = register[FCR][1] | fifo_enable ^ fifo_enable_r;
    assign fifo_reset_rx = register[FCR][2] | fifo_enable ^ fifo_enable_r;

    assign cfg_word = register[LCR][1:0];
    assign cfg_stop = register[LCR][2];
    assign cfg_parity = register[LCR][3];
    assign cfg_even_parity = register[LCR][4];
    assign cfg_stick_parity = register[LCR][5];
    assign cfg_break = register[LCR][6];

    // ------------------------------------------
    // Interrupt
    // ------------------------------------------

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            rcv_line_status <= 1'b0;
        end
        else begin
            // read ISR clear rcv_line_status
            if (read && addr == ISR) rcv_line_status <= 1'b0;
            else if (parity_error || overrun_error || frame_error || break_error) rcv_line_status <= 1'b1;
        end
    end

    assign interrupt_status = ~((rcv_line_status & register[IER][2]) |
                                (rcv_data_ready  & register[IER][0]) |
                                reception_timeout |
                                tx_holding_empty & register[IER][1]);

    assign interrupt_code = rcv_line_status   ? 3'b011 :
                            rcv_data_ready    ? 3'b010 :
                            reception_timeout ? 3'b110 :
                            tx_holding_empty  ? 3'b001 :
                            0;

    // Receiver Data Ready
    always_comb begin
        case(register[FCR][7:6])
        2'b00: rx_fifo_trigger_level = 1;
        2'b01: rx_fifo_trigger_level = 4;
        2'b10: rx_fifo_trigger_level = 8;
        2'b11: rx_fifo_trigger_level = 14;
        endcase
    end
    assign rx_fifo_trigger = (rx_fifo_count + RHR_reg_valid) >= rx_fifo_trigger_level;
    assign rcv_data_ready = fifo_enabled ? rx_fifo_trigger : RHR_reg_valid;

    // Reception Timeout
    /* verilator lint_off WIDTHEXPAND */
    assign timeout_limit = 4 * 16 * (1 + cfg_stop + cfg_parity + 5 + cfg_word) * cfg_div;
    /* verilator lint_on WIDTHEXPAND */
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            timer <= -1;
            timer_start <= 1'b0;
            reception_timeout <= 1'b0;
        end
        else begin
            if (read_RHR) timer_start <= 1'b0;
            else if (rx_valid && fifo_enable) timer_start <= 1'b1;

            if (read_RHR) timer <= timeout_limit;
            else if (timer_start && (timer != 0)) timer <= timer - 1'b1;

            if (read_RHR) reception_timeout <= 1'b0;
            else if (timer_start && (timer == 0)) reception_timeout <= 1'b1;
        end
    end

    // Transmitter Holding Register Empty
    assign tx_holding_empty = fifo_enable ? tx_fifo_empty : tx_ready;

    // Final interrupt for UART
    always_ff @(posedge clk) uart_interrupt <= interrupt_status;

    // ------------------------------------------
    // LSR Error logging
    // ------------------------------------------

    assign RHR_overrun =  ~fifo_enable & RHR_reg_valid & rx_valid & rx_ready;
    assign overrun_error = fifo_enable & fifo_overrun | ~fifo_enable & RHR_overrun;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            overrun_error_r <= 1'b0;
            fifo_data_error_r <= 1'b0;
        end
        else begin
            if (addr == LSR && read) begin
                overrun_error_r <= 1'b0;
                fifo_data_error_r <= 1'b0;
            end
            else begin
                if (overrun_error) overrun_error_r <= 1'b1;
                if (parity_error || frame_error || break_error) fifo_data_error_r <= 1'b1;
            end
        end
    end

endmodule
