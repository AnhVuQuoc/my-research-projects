// =============================================================================
// File        : timer_adc8_top.v
// Module      : timer_adc8_top
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Job         : Connects apb_regs8, timer8, sar_adc_ctrl and sync_fifo, selects
//               the ADC trigger and checks every result against the window.
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module timer_adc8_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       psel,
    input  wire       penable,
    input  wire       pwrite,
    input  wire [3:0] paddr,
    input  wire [7:0] pwdata,
    output wire [7:0] prdata,
    output wire       pready,
    output wire       pslverr,
    output wire       irq,
    output wire       pwm_out,
    output wire       adc_sample,
    output wire [1:0] adc_ch,
    output wire [7:0] adc_dac,
    input  wire       adc_cmp
);

    wire       tmr_en, tmr_oneshot, tmr_ovf, tmr_cmp_ev, tmr_oneshot_done;
    /* verilator lint_off UNUSEDSIGNAL */
    wire       tmr_tick;                              // trace only
    /* verilator lint_on UNUSEDSIGNAL */
    wire [7:0] tmr_presc, tmr_load, tmr_cmp, tmr_cnt;
    wire       adc_en, adc_start, adc_busy, adc_eoc, adc_trig_miss;
    wire [1:0] adc_trig_sel, adc_ch_sel, adc_res_ch;
    wire [7:0] adc_smp, adc_div, thr_lo, thr_hi, adc_result;
    wire [9:0] fifo_dout;
    wire [3:0] fifo_level;
    wire       fifo_empty, fifo_full, fifo_ovr, fifo_pop;

    // trigger select: START always works; TRIG_SEL adds a hardware source
    wire adc_trig = adc_start | ((adc_trig_sel == 2'd1) & tmr_ovf) | ((adc_trig_sel == 2'd2) & tmr_cmp_ev);
    wire adc_cont = (adc_trig_sel == 2'd3);
    wire adc_wd   = adc_eoc & ((adc_result < thr_lo) | (adc_result > thr_hi));

    apb_regs8 u_regs (
        .clk(clk), .rst_n(rst_n), .psel(psel), .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata),
        .prdata(prdata), .pready(pready), .pslverr(pslverr),
        .tmr_en(tmr_en), .tmr_oneshot(tmr_oneshot), .tmr_presc(tmr_presc), .tmr_load(tmr_load), .tmr_cmp(tmr_cmp),
        .tmr_cnt(tmr_cnt), .tmr_ovf(tmr_ovf), .tmr_cmp_ev(tmr_cmp_ev), .tmr_oneshot_done(tmr_oneshot_done),
        .adc_en(adc_en), .adc_start(adc_start), .adc_trig_sel(adc_trig_sel), .adc_ch(adc_ch_sel),
        .adc_smp(adc_smp), .adc_div(adc_div), .thr_lo(thr_lo), .thr_hi(thr_hi),
        .adc_busy(adc_busy), .adc_eoc(adc_eoc), .adc_wd(adc_wd), .adc_trig_miss(adc_trig_miss),
        .fifo_dout(fifo_dout), .fifo_level(fifo_level), .fifo_empty(fifo_empty), .fifo_full(fifo_full),
        .fifo_ovr(fifo_ovr), .fifo_pop(fifo_pop), .irq(irq));

    timer8 u_timer (
        .clk(clk), .rst_n(rst_n), .en(tmr_en), .oneshot(tmr_oneshot), .presc(tmr_presc), .load(tmr_load),
        .cmp(tmr_cmp), .cnt(tmr_cnt), .tick(tmr_tick), .ovf_pulse(tmr_ovf), .cmp_pulse(tmr_cmp_ev),
        .oneshot_done(tmr_oneshot_done), .pwm_out(pwm_out));

    sar_adc_ctrl #(.N(8)) u_adc (
        .clk(clk), .rst_n(rst_n), .en(adc_en), .trig(adc_trig), .cont(adc_cont), .ch_sel(adc_ch_sel),
        .smp(adc_smp), .div(adc_div), .adc_cmp(adc_cmp), .adc_sample(adc_sample), .adc_ch(adc_ch),
        .adc_dac(adc_dac), .busy(adc_busy), .eoc(adc_eoc), .result(adc_result), .result_ch(adc_res_ch),
        .trig_miss(adc_trig_miss));

    sync_fifo #(.W(10), .DEPTH(8), .AW(3)) u_fifo (
        .clk(clk), .rst_n(rst_n), .push(adc_eoc), .din({adc_res_ch, adc_result}), .pop(fifo_pop),
        .dout(fifo_dout), .level(fifo_level), .empty(fifo_empty), .full(fifo_full), .overflow(fifo_ovr));

endmodule

`default_nettype wire
