// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: Uart Controller
// Author: Heqing Huang
// Date Created: 06/25/2025
//
// -------------------------------------------------------------------
// uart_baud: generate sample for TX/RX module
// -------------------------------------------------------------------

module uart_baud (
    input        clk,
    input        rst_n,
    input [15:0] cfg_div,           // Number of clock cycles per 16x sampling tick
    input        clear,
    output logic sample_tick,       // 16x baud (fast)
    output logic baud_tick,         // 1x baud (slow)
    output logic half_baud_tick     // half of 1x baud
);

    logic [15:0] div;
    logic [15:0] sample_cnt;
    logic [3:0]  baud_cnt;

    assign div = cfg_div - 1'b1;

    assign sample_tick = sample_cnt == 0;
    assign baud_tick = (baud_cnt == 0) & sample_tick;
    assign half_baud_tick = (baud_cnt == 8) & sample_tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt <= 0;
            baud_cnt <= 0;
        end
        else begin
            if (sample_tick || clear) sample_cnt <= div;
            else sample_cnt <= sample_cnt - 1'b1;

            if (baud_tick || clear) baud_cnt <= 15;
            else if (sample_tick) baud_cnt <= baud_cnt - 1'b1;
        end
    end

endmodule
