// =============================================================================
// File        : tb_soc.v
// Module      : tb_soc_sva   (tb_soc + the 34 assertions, instanced without bind)
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Method      : Runs asm/soc_demo.asm on soc_top with afe_model (ch0..ch3 =
//               0.40, 1.111, 2.0, 3.0 V), then checks every result the firmware
//               stored in RAM against the ideal ADC code, plus the irq pin, the
//               interrupts taken, the cycles spent asleep and the PWM duty.
// =============================================================================
`timescale 1ns / 1ps
module tb_soc_sva;
    reg clk = 1'b0, rst = 1'b1;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end
    wire halted, irq, pwm, smp, cmp; wire [7:0] pc, dac; wire [1:0] ch;
    soc_top #(.PROGRAM_FILE("soc_demo.mem")) DUT (.clk(clk), .rst(rst), .halted(halted), .pc_out(pc), .irq(irq),
        .pwm_out(pwm), .adc_sample(smp), .adc_ch(ch), .adc_dac(dac), .adc_cmp(cmp));
    // direct checker instance: same connections as the bind, through hierarchical names
    timer_adc_sva u_sva (
        .clk(DUT.TADC.u_periph.clk),
        .rst_n(DUT.TADC.u_periph.rst_n),
        .psel(DUT.TADC.u_periph.psel),
        .penable(DUT.TADC.u_periph.penable),
        .pwrite(DUT.TADC.u_periph.pwrite),
        .pready(DUT.TADC.u_periph.pready),
        .pslverr(DUT.TADC.u_periph.pslverr),
        .irq(DUT.TADC.u_periph.irq),
        .paddr(DUT.TADC.u_periph.paddr),
        .pwdata(DUT.TADC.u_periph.pwdata),
        .prdata(DUT.TADC.u_periph.prdata),
        .tmr_en(DUT.TADC.u_periph.tmr_en),
        .tmr_oneshot(DUT.TADC.u_periph.tmr_oneshot),
        .tmr_ovf(DUT.TADC.u_periph.tmr_ovf),
        .tmr_cmp_ev(DUT.TADC.u_periph.tmr_cmp_ev),
        .tmr_oneshot_done(DUT.TADC.u_periph.tmr_oneshot_done),
        .tmr_tick(DUT.TADC.u_periph.tmr_tick),
        .pwm_out(DUT.TADC.u_periph.pwm_out),
        .tmr_cnt(DUT.TADC.u_periph.tmr_cnt),
        .tmr_load(DUT.TADC.u_periph.tmr_load),
        .tmr_cmp(DUT.TADC.u_periph.tmr_cmp),
        .adc_en(DUT.TADC.u_periph.adc_en),
        .adc_trig(DUT.TADC.u_periph.adc_trig),
        .adc_cont(DUT.TADC.u_periph.adc_cont),
        .adc_busy(DUT.TADC.u_periph.adc_busy),
        .adc_eoc(DUT.TADC.u_periph.adc_eoc),
        .adc_sample(DUT.TADC.u_periph.adc_sample),
        .adc_trig_miss(DUT.TADC.u_periph.adc_trig_miss),
        .adc_start(DUT.TADC.u_periph.adc_start),
        .adc_wd(DUT.TADC.u_periph.adc_wd),
        .adc_smp(DUT.TADC.u_periph.adc_smp),
        .adc_div(DUT.TADC.u_periph.adc_div),
        .adc_dac(DUT.TADC.u_periph.adc_dac),
        .adc_result(DUT.TADC.u_periph.adc_result),
        .thr_lo(DUT.TADC.u_periph.thr_lo),
        .thr_hi(DUT.TADC.u_periph.thr_hi),
        .adc_state(DUT.TADC.u_periph.u_adc.state),
        .adc_wm(DUT.TADC.u_periph.u_regs.adc_wm),
        .fifo_level(DUT.TADC.u_periph.fifo_level),
        .fifo_empty(DUT.TADC.u_periph.fifo_empty),
        .fifo_full(DUT.TADC.u_periph.fifo_full),
        .fifo_ovr(DUT.TADC.u_periph.fifo_ovr),
        .fifo_pop(DUT.TADC.u_periph.fifo_pop),
        .flags(DUT.TADC.u_periph.u_regs.flags),
        .irq_en(DUT.TADC.u_periph.u_regs.irq_en)
    );
    afe_model #(.VREF(3.3)) AFE (.clk(clk), .sample(smp), .ch(ch), .dac(dac), .cmp(cmp));

    integer errors = 0, checks = 0, cycles = 0, io_acc = 0, takes = 0, sleep_cyc = 0, irq_rise = 0, i, hi, n;
    reg irq_q = 1'b0;
    always @(posedge clk) if (!rst && !halted) begin
        cycles = cycles + 1;
        if (DUT.io_cs) io_acc = io_acc + 1;
        if (DUT.CPU.irq_take) takes = takes + 1;
        if (DUT.CPU.IRQ.sleeping) sleep_cyc = sleep_cyc + 1;
        if (irq && !irq_q) irq_rise = irq_rise + 1;
        irq_q = irq;
    end
    task check; input [7:0] a, exp; input [8*44:1] what;
        begin checks = checks + 1;
            if (DUT.CPU.DMEM.mem[a] === exp) $display("  PASS | M[%h] = %h  %0s", a, exp, what);
            else begin errors = errors + 1; $display("  FAIL | M[%h] = %h, expected %h  %0s", a, DUT.CPU.DMEM.mem[a], exp, what); end
        end
    endtask
    task check_int; input integer got, lo, hi_; input [8*44:1] what;
        begin checks = checks + 1;
            if (got >= lo && got <= hi_) $display("  PASS | %0s = %0d", what, got);
            else begin errors = errors + 1; $display("  FAIL | %0s = %0d (expected %0d..%0d)", what, got, lo, hi_); end
        end
    endtask
    initial begin
        $display("============================================================================");
        $display(" tb_soc_sva : system test, RISC-8 CPU + Timer/SAR ADC (firmware asm/soc_demo.asm)");
        $display(" Student: Vu Quoc Anh | Roll number: SE203519");
        $display("============================================================================");
        AFE.vin0 = 0.40; AFE.vin1 = 1.111; AFE.vin2 = 2.0; AFE.vin3 = 3.0;
        repeat (3) @(posedge clk); @(negedge clk); rst = 1'b0;
        i = 0; while (!halted && i < 20000) begin @(posedge clk); i = i + 1; end
        $display("  CPU halted after %0d cycles, %0d I/O accesses, %0d interrupts, %0d cycles asleep", cycles, io_acc, takes, sleep_cyc);
        check(8'h80, 8'hA8, "A: ID register");
        check(8'h81, 8'h81, "B: ADC_RCH before pop = VALID, ch1");
        check(8'h82, AFE.ideal_code(1.111), "B: ch1 code (1.111 V)");
        check(8'h83, 8'h50, "B: ADC_RCH after pop = LVALID, LCH 1");
        for (n = 8'h90; n < 8'h98; n = n + 1) check(n, AFE.ideal_code(2.0), "C: ch2 sample via watermark ISR");
        check(8'h98, 8'h00, "C: nothing stored past the 8th sample");
        check(8'h84, 8'h4C, "D: IRQ_STAT = FIFO_WM | ADC_WD | ADC_EOC");
        check(8'h85, AFE.ideal_code(3.0), "D: ch3 code (3.0 V)");
        check(8'h86, AFE.ideal_code(0.40), "F: 1st pop, ch0 (0.40 V)");
        check(8'h87, AFE.ideal_code(1.111), "F: 2nd pop, ch1");
        check(8'h88, 8'h10, "F: ADC_STAT empty after 2 pops");
        check(8'h89, 8'h54, "G: IRQ_STAT = FIFO_WM | FIFO_OVR | ADC_EOC");
        check(8'h8A, 8'hA8, "G: ADC_STAT = WM | FULL | LEVEL 8");
        n = 0; for (i = 8'hF0; i <= 8'hFF; i = i + 1) if (DUT.CPU.DMEM.mem[i] !== 8'h00) n = n + 1;
        check_int(n, 0, 0, "RAM words of the I/O page that were written");
        check_int(takes, 2, 2, "C: interrupts taken");
        check_int(irq_rise, 2, 2, "C: irq rising edges");
        check_int(sleep_cyc, 300, 900, "C: cycles asleep in WFI");
        hi = 0; for (n = 0; n < 100; n = n + 1) begin @(posedge clk); if (pwm) hi = hi + 1; end
        check_int(hi, 30, 30, "E: PWM high clocks out of 100");
        $display("============================================================================");
        if (errors == 0) $display("PASS: tb_soc_sva (Vu Quoc Anh, SE203519) %0d checks, 0 errors", checks);
        else $display("FAILED: tb_soc_sva (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, checks);
        $finish(0);
    end
endmodule
