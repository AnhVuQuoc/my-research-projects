// =============================================================================
// File        : timer8.v
// Module      : timer8
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Job         : 8-bit timer. A prescaler makes a tick every PRESC+1 clocks; the
//               counter counts ticks 0..LOAD and wraps. On each tick it raises
//               ovf_pulse (cnt >= LOAD, wrap) and cmp_pulse (cnt == CMP).
//               pwm_out = registered (cnt < CMP), so duty = CMP / (LOAD + 1).
//               ONESHOT: stop after the first overflow (oneshot_done clears EN).
// Formulas    : period  = (PRESC + 1) * (LOAD + 1) clocks
//               compare = (CMP + 1) * (PRESC + 1) clocks after enable
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module timer8 (
    input  wire       clk,
    input  wire       rst_n,        // asynchronous, active low
    input  wire       en,           // TMR_CTRL.EN
    input  wire       oneshot,      // TMR_CTRL.ONESHOT
    input  wire [7:0] presc,        // TMR_PRESC
    input  wire [7:0] load,         // TMR_LOAD (top value)
    input  wire [7:0] cmp,          // TMR_CMP
    output reg  [7:0] cnt,          // TMR_CNT
    output wire       tick,         // prescaler tick (trace)
    output wire       ovf_pulse,    // 1 clock: counter wrapped
    output wire       cmp_pulse,    // 1 clock: counter matched CMP
    output wire       oneshot_done, // 1 clock: hardware must clear EN
    output reg        pwm_out
);

    reg [7:0] pcnt;                                   // prescaler counter

    assign tick         = en & (pcnt >= presc);       // >= : safe if PRESC shrinks
    assign ovf_pulse    = tick & (cnt >= load);       // >= : safe if LOAD shrinks
    assign cmp_pulse    = tick & (cnt == cmp);
    assign oneshot_done = ovf_pulse & oneshot;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pcnt <= 8'd0; cnt <= 8'd0; pwm_out <= 1'b0;
        end
        else if (!en) begin                           // off: hold everything at 0
            pcnt <= 8'd0; cnt <= 8'd0; pwm_out <= 1'b0;
        end
        else begin
            pcnt    <= tick ? 8'd0 : pcnt + 8'd1;
            if (tick) cnt <= ovf_pulse ? 8'd0 : cnt + 8'd1;
            pwm_out <= (cnt < cmp);                   // registered: glitch-free pin
        end
    end

endmodule

`default_nettype wire
