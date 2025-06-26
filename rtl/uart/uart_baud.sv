// -------------------------------------------------------------------
// Copyright 2025 by Heqing Huang (feipenghhq@gamil.com)
// -------------------------------------------------------------------
//
// Project: Uart Controller
// Author: Heqing Huang
// Date Created: 06/25/2025
//
// -------------------------------------------------------------------
// uart_baud: generate baud tick for TX/RX module
//
// Implementation Notes:
// The TX module use 16 over-sampling and a 2/3 majority vote to determine the input value.
// it sample the input RX at 6, 8, 10-th sample to get the 3 value for majority vote.
// Because of that, the baud module will generate pulse for 6/8/10th and 16th sample
// -------------------------------------------------------------------

module uart_baud (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] cfg_div,            // cfg_div = F_clk/F_baud - 1
    input  logic        clear,              // Clear the clock divider counter and start a new sampling.
    output logic        baud_sample_6th,    // 6th sampling of the total 16 sampling
    output logic        baud_sample_8th,    // 8th sampling of the total 16 sampling
    output logic        baud_sample_10th,   // 10th sampling of the total 16 sampling
    output logic        baud_sample_16th    // 16th sampling of the total 16 sampling
);

    logic        tick;
    logic [11:0] counter;       // number of clock cycle for each sample
    logic [3:0]  sample_count;


    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 12'b0;
        end
        else begin
            if (clear || tick) counter <= cfg_div[15:4];
            else counter <= counter - 1'b1;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            sample_count <= 4'b0;
        end
        else begin
            if (clear || baud_sample_16th) sample_count <= 0;
            else if (tick) sample_count <= sample_count + 1'b1;
        end
    end

    assign tick = (counter == 12'b1); // last count is 1 instead of 0.
    assign baud_sample_6th  = tick & (sample_count == 4'd5);
    assign baud_sample_8th  = tick & (sample_count == 4'd7);
    assign baud_sample_10th = tick & (sample_count == 4'd9);
    assign baud_sample_16th = tick & (sample_count == 4'd15);

endmodule