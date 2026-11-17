// =============================================================================
// File        : timer_adc8_cpu_if.v
// Module      : timer_adc8_cpu_if
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Job         : Makes the APB slave look like a 1-clock CPU bus: cs drives both
//               psel and penable, so every LD / ST is a complete access in the
//               same clock, with rdata ready combinationally (0 when cs = 0).
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module timer_adc8_cpu_if (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       cs,
    input  wire       we,
    input  wire [3:0] addr,
    input  wire [7:0] wdata,
    output wire [7:0] rdata,
    output wire       irq,
    output wire       pwm_out,
    output wire       adc_sample,
    output wire [1:0] adc_ch,
    output wire [7:0] adc_dac,
    input  wire       adc_cmp
);

    /* verilator lint_off UNUSEDSIGNAL */
    wire pready, pslverr;                             // always 1 / 0 in this slave
    /* verilator lint_on UNUSEDSIGNAL */

    timer_adc8_top u_periph (
        .clk(clk), .rst_n(rst_n), .psel(cs), .penable(cs), .pwrite(we), .paddr(addr), .pwdata(wdata),
        .prdata(rdata), .pready(pready), .pslverr(pslverr), .irq(irq), .pwm_out(pwm_out),
        .adc_sample(adc_sample), .adc_ch(adc_ch), .adc_dac(adc_dac), .adc_cmp(adc_cmp));

endmodule

`default_nettype wire
