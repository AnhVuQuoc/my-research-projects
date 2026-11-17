// =============================================================================
// File        : sv/timer_adc_bind.sv   (SIMULATION ONLY)
// Job         : attaches the checker timer_adc_sva to every timer_adc8_top. Kept
//               apart from the checker so that a simulator that handles bind badly
//               (seen on Vivado 2018.3) can use the direct instance instead.
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
bind timer_adc8_top timer_adc_sva u_sva (
    .clk(clk), .rst_n(rst_n), .psel(psel), .penable(penable), .pwrite(pwrite), .pready(pready), .pslverr(pslverr), .irq(irq),
    .paddr(paddr), .pwdata(pwdata), .prdata(prdata),
    .tmr_en(tmr_en), .tmr_oneshot(tmr_oneshot), .tmr_ovf(tmr_ovf), .tmr_cmp_ev(tmr_cmp_ev), .tmr_oneshot_done(tmr_oneshot_done),
    .tmr_tick(tmr_tick), .pwm_out(pwm_out), .tmr_cnt(tmr_cnt), .tmr_load(tmr_load), .tmr_cmp(tmr_cmp),
    .adc_en(adc_en), .adc_trig(adc_trig), .adc_cont(adc_cont), .adc_busy(adc_busy), .adc_eoc(adc_eoc), .adc_sample(adc_sample),
    .adc_trig_miss(adc_trig_miss), .adc_start(adc_start), .adc_wd(adc_wd), .adc_smp(adc_smp), .adc_div(adc_div), .adc_dac(adc_dac),
    .adc_result(adc_result), .thr_lo(thr_lo), .thr_hi(thr_hi), .adc_state(u_adc.state), .adc_wm(u_regs.adc_wm),
    .fifo_level(fifo_level), .fifo_empty(fifo_empty), .fifo_full(fifo_full), .fifo_ovr(fifo_ovr), .fifo_pop(fifo_pop),
    .flags(u_regs.flags), .irq_en(u_regs.irq_en));
