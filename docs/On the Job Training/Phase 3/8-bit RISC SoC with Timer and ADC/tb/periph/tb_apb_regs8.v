// =============================================================================
// File        : tb_apb_regs8.v      Module: tb_apb_regs8
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Part 1      : directed, through real 2-phase APB transfers (setup, access):
//               reset values, bit-bash and RO protection, START pulse, prdata = 0
//               when not selected, W1C and the same-clock race, watermark for
//               every threshold and level, pop only on a read of ADC_DATA,
//               channel latch, one-shot clearing EN, irq masking
// Part 2      : 5,000 random APB transfers and random events against a shadow
//               register model; every read is compared
// =============================================================================
`timescale 1ns / 1ps
module tb_apb_regs8;
    reg clk = 0, rst_n = 0, psel = 0, penable = 0, pwrite = 0; reg [3:0] paddr = 0; reg [7:0] pwdata = 0;
    wire [7:0] prdata; wire pready, pslverr;
    reg [7:0] tmr_cnt = 0; reg tmr_ovf = 0, tmr_cmp_ev = 0, osd = 0, busy = 0, eoc = 0, wd = 0, tmiss = 0;
    reg [9:0] fdout = 0; reg [3:0] flevel = 0; reg fovr = 0;
    wire fempty = (flevel == 0), ffull = (flevel == 8);
    wire tmr_en, tmr_os, adc_en, adc_start, fpop, irq; wire [7:0] presc, load, cmp, smp, div, lo, hi; wire [1:0] tsel, ch;
    always #5 clk = ~clk;
    apb_regs8 DUT (.clk(clk), .rst_n(rst_n), .psel(psel), .penable(penable), .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata),
        .prdata(prdata), .pready(pready), .pslverr(pslverr), .tmr_en(tmr_en), .tmr_oneshot(tmr_os), .tmr_presc(presc), .tmr_load(load),
        .tmr_cmp(cmp), .tmr_cnt(tmr_cnt), .tmr_ovf(tmr_ovf), .tmr_cmp_ev(tmr_cmp_ev), .tmr_oneshot_done(osd), .adc_en(adc_en),
        .adc_start(adc_start), .adc_trig_sel(tsel), .adc_ch(ch), .adc_smp(smp), .adc_div(div), .thr_lo(lo), .thr_hi(hi),
        .adc_busy(busy), .adc_eoc(eoc), .adc_wd(wd), .adc_trig_miss(tmiss), .fifo_dout(fdout), .fifo_level(flevel),
        .fifo_empty(fempty), .fifo_full(ffull), .fifo_ovr(fovr), .fifo_pop(fpop), .irq(irq));
    integer errors = 0, checks = 0, i, k, w, seed = 32'h5E203519, pops = 0;
    reg [7:0] rv, sh [0:15];                       // shadow of the RW registers
    reg [5:0] mflags; reg [1:0] mlch; reg mlv;
    always @(posedge clk) if (fpop) pops = pops + 1;
    task chk; input [7:0] got, exp; input [8*40:1] m; begin checks = checks + 1;
        if (got !== exp) begin errors = errors + 1; if (errors < 15) $display("  FAIL %0s: got %h expected %h", m, got, exp); end end endtask
    task apb_w; input [3:0] a; input [7:0] d; begin                     // setup phase, then access phase
        @(negedge clk); psel = 1; penable = 0; pwrite = 1; paddr = a; pwdata = d;
        @(negedge clk); penable = 1; @(negedge clk); psel = 0; penable = 0; pwrite = 0; end endtask
    task apb_r; input [3:0] a; output [7:0] d; begin
        @(negedge clk); psel = 1; penable = 0; pwrite = 0; paddr = a;
        @(negedge clk); penable = 1; #1 d = prdata; @(negedge clk); psel = 0; penable = 0; end endtask
    function [7:0] mask; input [3:0] a; mask = (a == 0) ? 8'h03 : (a == 5) ? 8'hFD : (a == 4'hD) ? 8'h7F : 8'hFF; endfunction
    function is_rw; input [3:0] a; is_rw = (a <= 3) || (a >= 5 && a <= 9) || a == 4'hD; endfunction
    initial begin
        $display("============================================================================");
        $display(" tb_apb_regs8 : 16 registers, W1C flags, watermark, pop, latch, irq");
        $display(" Student: Vu Quoc Anh | Roll number: SE203519");
        $display("============================================================================");
        #22 rst_n = 1;
        $display("PART 1: directed");
        sh[0]=8'h00; sh[1]=8'h00; sh[2]=8'hFF; sh[3]=8'h80; sh[5]=8'h00; sh[6]=8'h04; sh[7]=8'h00; sh[8]=8'h00; sh[9]=8'hFF; sh[13]=8'h00;
        for (i = 0; i < 16; i = i + 1) begin
            apb_r(i, rv);
            case (i) 4: chk(rv, 8'h00, "reset TMR_CNT"); 10, 11, 14: chk(rv, 8'h00, "reset FIFO/flags"); 12: chk(rv, 8'h10, "reset ADC_STAT");
                     15: chk(rv, 8'hA8, "ID"); default: chk(rv, sh[i], "reset value"); endcase
        end
        $display("  reset values: 16 registers read, ID = A8, ADC_STAT = 10");
        for (k = 0; k < 4; k = k + 1) for (i = 0; i < 16; i = i + 1) begin
            w = (k == 0) ? 8'hFF : (k == 1) ? 8'h00 : (k == 2) ? 8'h55 : 8'hAA;
            apb_w(i, w); if (i == 4'hE) apb_w(i, 8'hFF);
            apb_r(i, rv);
            if (is_rw(i)) chk(rv, w & mask(i), "bit-bash RW");
            else if (i == 4'hF) chk(rv, 8'hA8, "ID is read-only");
            else if (i == 4 || i == 4'hA || i == 4'hB) chk(rv, 8'h00, "RO not writable");
            if (i == 5) apb_w(5, 8'h00);
        end
        $display("  bit-bash: 0xFF, 0x00, 0x55, 0xAA into all 16 addresses; masks and RO protection checked");
        apb_w(0, 0); apb_w(5, 0);
        @(negedge clk); psel = 1; penable = 1; pwrite = 1; paddr = 5; pwdata = 8'h03; #1 chk(adc_start, 0, "START not during the write");
        @(negedge clk); psel = 0; penable = 0; #1 chk(adc_start, 1, "START pulse 1 clock after");
        @(negedge clk); #1 chk(adc_start, 0, "START is 1 clock long");
        for (i = 0; i < 16; i = i + 1) begin paddr = i; psel = 0; #1 chk(prdata, 8'h00, "prdata = 0 when not selected"); end
        // W1C and the race
        @(negedge clk); tmr_ovf = 1; eoc = 1; @(negedge clk); tmr_ovf = 0; eoc = 0;
        apb_r(4'hE, rv); chk(rv, 8'h05, "flags set by events");
        apb_w(4'hE, 8'h01); apb_r(4'hE, rv); chk(rv, 8'h04, "W1C clears only bit 0");
        @(negedge clk); psel = 1; penable = 1; pwrite = 1; paddr = 4'hE; pwdata = 8'h04; eoc = 1;   // clear + event, same clock
        @(negedge clk); psel = 0; penable = 0; eoc = 0; apb_r(4'hE, rv); chk(rv, 8'h04, "same-clock event wins over clear");
        apb_w(4'hE, 8'h3F);
        // watermark: every threshold x every level
        for (k = 0; k < 4; k = k + 1) begin apb_w(5, k << 6);
            for (i = 0; i <= 8; i = i + 1) begin flevel = i; apb_r(4'hC, rv); chk(rv[7], (i >= (1 << k)), "ADC_STAT.WM");
                apb_r(4'hE, rv); chk(rv[6], (i >= (1 << k)), "IRQ_STAT.FIFO_WM"); end end
        flevel = 8; apb_w(5, 8'h00); apb_w(4'hE, 8'h40); apb_r(4'hE, rv); chk(rv[6], 1, "FIFO_WM is not W1C");
        apb_w(4'hD, 8'h40); #1 chk(irq, 1, "irq from FIFO_WM"); flevel = 0; #1 chk(irq, 0, "irq follows the level");
        $display("  W1C, race, watermark 4 thresholds x 9 levels, irq from the level flag");
        // pop strobe and latch
        flevel = 2; fdout = 10'h2_5A; k = pops;
        apb_r(4'hA, rv); chk(rv, 8'h5A, "ADC_DATA = head data"); chk(pops - k, 1, "1 pop per read");
        apb_r(4'hB, rv); chk(rv, 8'hE2, "RCH: VALID, LVALID, LCH 2, head ch 2");
        apb_w(4'hA, 8'h00); apb_r(4'hC, rv); chk(pops - k, 1, "no pop on write or other reads");
        @(negedge clk); psel = 1; penable = 0; paddr = 4'hA; #1 chk(fpop, 0, "no pop in the setup phase"); @(negedge clk); psel = 0;
        flevel = 0; apb_r(4'hA, rv); chk(rv, 8'h00, "ADC_DATA empty = 00"); apb_r(4'hB, rv); chk(rv, 8'h60, "latch kept when empty");
        // one-shot clears EN
        apb_w(0, 8'h03); @(negedge clk); osd = 1; @(negedge clk); osd = 0; apb_r(0, rv); chk(rv, 8'h02, "one-shot cleared EN");
        // irq mask: every flag x its enable
        for (i = 0; i < 6; i = i + 1) begin apb_w(4'hD, 0); apb_w(4'hE, 8'h3F);
            @(negedge clk); {tmiss, fovr, wd, eoc, tmr_cmp_ev, tmr_ovf} = 6'd1 << i; @(negedge clk); {tmiss, fovr, wd, eoc, tmr_cmp_ev, tmr_ovf} = 0;
            #1 chk(irq, 0, "masked flag gives no irq"); apb_w(4'hD, 8'd1 << i); #1 chk(irq, 1, "enabled flag gives irq");
            apb_w(4'hE, 8'd1 << i); #1 chk(irq, 0, "W1C removes irq"); end
        $display("  pop strobe, channel latch, one-shot clear, 6 flags x enable -> irq");
        $display("PART 2: 5,000 random APB transfers and events against a shadow model");
        apb_w(4'hD, 0); apb_w(4'hE, 8'h3F); apb_w(0, 0); for (i = 0; i < 16; i = i + 1) if (is_rw(i)) begin apb_r(i, rv); sh[i] = rv; end
        mflags = 0; mlch = 2'd2; mlv = 1; flevel = 0;
        for (k = 0; k < 5000; k = k + 1) begin
            i = $unsigned($random(seed)) % 16; w = $random(seed);
            if ($unsigned($random(seed)) % 2) begin
                if (i != 0 && i != 5) begin apb_w(i, w); if (is_rw(i)) sh[i] = w & mask(i); if (i == 4'hE) mflags = mflags & ~w[5:0]; end
            end
            else begin apb_r(i, rv);
                if (is_rw(i)) chk(rv, sh[i], "random RW read");
                if (i == 4'hE) chk(rv, {1'b0, (flevel >= 1), mflags}, "random IRQ_STAT read");
                if (i == 4'hB) chk(rv, {~fempty, mlv, mlch, 2'b00, fempty ? 2'b00 : fdout[9:8]}, "random RCH read");
                if (i == 4'hA && !fempty) begin mlch = fdout[9:8]; mlv = 1; end
            end
            if ($unsigned($random(seed)) % 4 == 0) begin
                @(negedge clk); {tmiss, fovr, wd, eoc, tmr_cmp_ev, tmr_ovf} = $random(seed); mflags = mflags | {tmiss, fovr, wd, eoc, tmr_cmp_ev, tmr_ovf};
                flevel = $unsigned($random(seed)) % 9; fdout = $random(seed); @(negedge clk); {tmiss, fovr, wd, eoc, tmr_cmp_ev, tmr_ovf} = 0; end
        end
        #1;
        if (errors == 0) $display("PASS: tb_apb_regs8 (Vu Quoc Anh, SE203519) %0d checks, 0 errors", checks);
        else $display("FAILED: tb_apb_regs8 (Vu Quoc Anh, SE203519) %0d errors", errors);
        $finish(0);
    end
endmodule
