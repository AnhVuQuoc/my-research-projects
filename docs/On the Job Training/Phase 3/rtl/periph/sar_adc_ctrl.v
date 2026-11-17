// =============================================================================
// File        : sar_adc_ctrl.v
// Module      : sar_adc_ctrl
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Job         : Successive-approximation controller. IDLE -> SAMPLE (SMP+1 ticks,
//               adc_sample = 1) -> CONVERT (8 ticks, 1 bit per tick, MSB first,
//               comparator read at the end of each tick) -> DONE (1 clock, eoc).
//               A tick is every DIV+1 clocks. Conversion time from the start edge
//               to the DONE state: (SMP + 9) * (DIV + 1) clocks.
//               Continuous mode restarts from DONE. EN = 0 aborts at once.
//               A trigger while busy is reported as trig_miss.
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module sar_adc_ctrl #(
    parameter N = 8                                   // resolution (bits)
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         en,            // ADC_CTRL.EN
    input  wire         trig,          // 1-clock start request (already selected)
    input  wire         cont,          // continuous mode (TRIG_SEL = 3)
    input  wire [1:0]   ch_sel,        // ADC_CTRL.CH, latched at start
    input  wire [7:0]   smp,           // ADC_SMP: sample window = SMP+1 ticks
    input  wire [7:0]   div,           // ADC_DIV: tick every DIV+1 clocks
    input  wire         adc_cmp,       // comparator: 1 = held input >= DAC
    output reg          adc_sample,    // to S/H: 1 = track
    output reg  [1:0]   adc_ch,        // to MUX
    output reg  [N-1:0] adc_dac,       // to DAC: current guess
    output wire         busy,
    output reg          eoc,           // 1 clock: result valid
    output reg  [N-1:0] result,
    output reg  [1:0]   result_ch,
    output wire         trig_miss      // 1 clock: trigger lost (busy)
);

    localparam [1:0] S_IDLE = 2'd0, S_SAMPLE = 2'd1, S_CONVERT = 2'd2, S_DONE = 2'd3;
    reg [1:0]  state;
    reg [7:0]  dcnt;                                  // clock divider
    reg [7:0]  scnt;                                  // sample tick counter
    reg [2:0]  bitn;                                  // bit under test
    wire       tick  = (dcnt >= div);
    wire       start = en & ((state == S_IDLE) & (trig | cont));
    wire [N-1:0] kept = adc_cmp ? adc_dac : (adc_dac & ~({{(N-1){1'b0}}, 1'b1} << bitn));

    assign busy      = (state != S_IDLE);
    assign trig_miss = en & trig & busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE; dcnt <= 8'd0; scnt <= 8'd0; bitn <= 3'd0; adc_sample <= 1'b0;
            adc_ch <= 2'd0; adc_dac <= {N{1'b0}}; eoc <= 1'b0; result <= {N{1'b0}}; result_ch <= 2'd0;
        end
        else if (!en) begin                           // abort: no result
            state <= S_IDLE; dcnt <= 8'd0; adc_sample <= 1'b0; adc_dac <= {N{1'b0}}; eoc <= 1'b0;
        end
        else begin
            eoc <= 1'b0;
            case (state)
                S_IDLE: if (start) begin
                    state <= S_SAMPLE; dcnt <= 8'd0; scnt <= 8'd0; adc_ch <= ch_sel; adc_sample <= 1'b1;
                end
                S_SAMPLE: begin
                    dcnt <= tick ? 8'd0 : dcnt + 8'd1;
                    if (tick) begin
                        if (scnt >= smp) begin            // SMP+1 ticks done: hold, first guess
                            state <= S_CONVERT; adc_sample <= 1'b0; bitn <= 3'd7;
                            adc_dac <= {1'b1, {(N-1){1'b0}}};
                        end
                        else scnt <= scnt + 8'd1;
                    end
                end
                S_CONVERT: begin
                    dcnt <= tick ? 8'd0 : dcnt + 8'd1;
                    if (tick) begin
                        if (bitn == 3'd0) begin            // last decision
                            state <= S_DONE; result <= kept; result_ch <= adc_ch; eoc <= 1'b1;
                            adc_dac <= kept;
                        end
                        else begin
                            bitn    <= bitn - 3'd1;
                            adc_dac <= kept | ({{(N-1){1'b0}}, 1'b1} << (bitn - 3'd1));
                        end
                    end
                end
                default: begin                             // S_DONE: 1 clock
                    if (cont) begin
                        state <= S_SAMPLE; dcnt <= 8'd0; scnt <= 8'd0; adc_ch <= ch_sel; adc_sample <= 1'b1;
                        adc_dac <= {N{1'b0}};
                    end
                    else begin
                        state <= S_IDLE; adc_dac <= {N{1'b0}};
                    end
                end
            endcase
        end
    end

endmodule

`default_nettype wire
