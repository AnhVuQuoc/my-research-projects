// =============================================================================
// File        : sv/timer_adc_sva.sv   (SIMULATION ONLY)
// Module      : timer_adc_sva (the checker). Attach it with sv/timer_adc_bind.sv (bind),
//               or instance it directly as in tb/soc/tb_soc_sva.sv (simulators without bind)
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Job         : 33 rules checked on every clock. Rules with a delay that depends
//               on a register (conversion time, sample width) use a small
//               counter and an immediate assertion, so they run on every
//               simulator. Each failure increments sva_fail.
// =============================================================================
`timescale 1ns / 1ps
module timer_adc_sva (
    input logic       clk, rst_n,
    input logic       psel, penable, pwrite, pready, pslverr, irq,
    input logic [3:0] paddr,
    input logic [7:0] pwdata, prdata,
    input logic       tmr_en, tmr_oneshot, tmr_ovf, tmr_cmp_ev, tmr_oneshot_done, tmr_tick, pwm_out,
    input logic [7:0] tmr_cnt, tmr_load, tmr_cmp,
    input logic       adc_en, adc_trig, adc_cont, adc_busy, adc_eoc, adc_sample, adc_trig_miss, adc_start, adc_wd,
    input logic [7:0] adc_smp, adc_div, adc_dac, adc_result, thr_lo, thr_hi,
    input logic [1:0] adc_state, adc_wm,
    input logic [3:0] fifo_level,
    input logic       fifo_empty, fifo_full, fifo_ovr, fifo_pop,
    input logic [5:0] flags,
    input logic [6:0] irq_en
);
    int sva_fail = 0, sva_checks = 0;
    wire wr_ctrl = psel & penable & pwrite & (paddr == 4'h0);
    wire wr_stat = psel & penable & pwrite & (paddr == 4'hE);
    wire wm_flag = ({1'b0, fifo_level} >= (5'd1 << adc_wm));
    wire [5:0] events = {adc_trig_miss, fifo_ovr, adc_wd, adc_eoc, tmr_cmp_ev, tmr_ovf};
    `define CHK(name, cond) begin sva_checks++; if (!(cond)) begin sva_fail++; $error("SVA %s failed at %0t", name, $time); end end

    // ---------------- concurrent rules
    `define AP(name, prop) name : assert property (@(posedge clk) disable iff (!rst_n) prop);
    `AP(a_cnt_le_load, ((tmr_en && $past(tmr_en) && tmr_load == $past(tmr_load) && $past(tmr_cnt) <= $past(tmr_load)) |-> tmr_cnt <= tmr_load))
    `AP(a_ovf_wrap, (tmr_ovf |=> (tmr_cnt == 8'd0)))
    `AP(a_cmp_match, (tmr_cmp_ev |-> (tmr_cnt == tmr_cmp)))
    `AP(a_event_tick, ((tmr_ovf || tmr_cmp_ev) |-> tmr_tick))
    `AP(a_count_step, ((tmr_tick && !tmr_ovf) |=> (!tmr_en || tmr_cnt == $past(tmr_cnt) + 8'd1)))
    `AP(a_hold, ((tmr_en && !tmr_tick) |=> (!tmr_en || tmr_cnt == $past(tmr_cnt))))
    `AP(a_off_zero, (!tmr_en |=> (tmr_cnt == 8'd0)))
    `AP(a_oneshot_stop, ((tmr_oneshot_done && !wr_ctrl) |=> !tmr_en))
    `AP(a_pwm, ((tmr_en && $past(tmr_en)) |-> (pwm_out == $past(tmr_cnt < tmr_cmp))))
    `AP(a_eoc_pulse, (adc_eoc |=> !adc_eoc))
    `AP(a_eoc_busy, (adc_eoc |-> adc_busy))
    `AP(a_abort, (!adc_en |=> (!adc_busy && !adc_sample)))
    `AP(a_miss_busy, (adc_trig_miss |-> (adc_busy && adc_trig)))
    `AP(a_result_eoc, ($changed(adc_result) |-> adc_eoc))
    `AP(a_no_samp_conv, (!(adc_sample && adc_state == 2'd2)))
    `AP(a_msb_first, ((adc_state == 2'd2 && $past(adc_state) == 2'd1) |-> adc_dac == 8'h80))
    `AP(a_window, (adc_wd == (adc_eoc && (adc_result < thr_lo || adc_result > thr_hi))))
    `AP(a_level_max, (fifo_level <= 4'd8))
    `AP(a_empty_full, (fifo_empty == (fifo_level == 0) && fifo_full == (fifo_level == 8)))
    `AP(a_level_step, ((fifo_level == $past(fifo_level)) || (fifo_level == $past(fifo_level) + 4'd1) || (fifo_level + 4'd1 == $past(fifo_level))))
    `AP(a_overflow_flag, ((adc_eoc && fifo_full && !fifo_pop) |-> fifo_ovr))
    `AP(a_overflow_drop, ((adc_eoc && fifo_full && !fifo_pop) |=> (fifo_level == 4'd8)))
    `AP(a_push, ((adc_eoc && !fifo_full && !(fifo_pop && !fifo_empty)) |=> fifo_level == $past(fifo_level) + 4'd1))
    `AP(a_pop, ((fifo_pop && !fifo_empty && !adc_eoc) |=> fifo_level + 4'd1 == $past(fifo_level)))
    `AP(a_pop_only_rd, (fifo_pop |-> (psel && penable && !pwrite && paddr == 4'hA)))
    `AP(a_apb_ok, (pready && !pslverr))
    `AP(a_prdata_zero, (!psel |-> prdata == 8'h00))
    `AP(a_id, ((psel && paddr == 4'hF) |-> prdata == 8'hA8))
    `AP(a_irq, (irq == |({wm_flag, flags} & irq_en)))
    `AP(a_flag_set, ((events != 6'd0) |=> ((flags & $past(events)) == $past(events))))
    `AP(a_flag_sticky, (1'b1 |=> ((flags & $past(flags) & ~$past(wr_stat ? pwdata[5:0] : 6'd0)) == ($past(flags) & ~$past(wr_stat ? pwdata[5:0] : 6'd0)))))
    `AP(a_start_pulse, (adc_start |=> !adc_start))

    // ---------------- counter-based rules (delays set by registers)
    int conv_clk = -1, samp_clk = 0; logic [7:0] smp_l, div_l;
    always @(posedge clk) if (rst_n) begin
        if (adc_state == 2'd0 && adc_en && (adc_trig || adc_cont) || (adc_state == 2'd3 && adc_cont && adc_en)) begin
            conv_clk <= 0; samp_clk <= 0; smp_l <= adc_smp; div_l <= adc_div;          // start edge
        end
        else if (conv_clk >= 0) begin
            conv_clk <= conv_clk + 1; if (adc_sample) samp_clk <= samp_clk + 1;
            if (!adc_en) conv_clk <= -1;
        end
        if (adc_eoc && conv_clk >= 0) begin
            `CHK("a_conv_time", conv_clk == (smp_l + 9) * (div_l + 1))
            `CHK("a_sample_width", samp_clk == (smp_l + 1) * (div_l + 1))
        end
    end
endmodule
