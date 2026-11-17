// =============================================================================
// File        : tb_sar_adc_ctrl.v      Module: tb_sar_adc_ctrl
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Part 1      : exhaustive: every input from code 0 to 255 plus every midpoint
//               (511 inputs, in 1/2-LSB steps) at SMP 0, DIV 0; the result must
//               be floor(input), and the conversion must take exactly
//               (SMP + 9) * (DIV + 1) clocks with sample high (SMP + 1) * (DIV + 1)
// Part 2      : random SMP, DIV, channel and input; abort (EN = 0) gives no eoc;
//               triggers while busy give trig_miss; continuous mode restarts
// Model       : comparator in 1/16-LSB units: cmp = (held * 16 >= dac * 16)
// =============================================================================
`timescale 1ns / 1ps
module tb_sar_adc_ctrl;
    reg clk = 0, rst_n = 0, en = 0, trig = 0, cont = 0; reg [1:0] chs = 0; reg [7:0] smp = 0, div = 0;
    wire sample, busy, eoc, miss; wire [1:0] ach, rch; wire [7:0] dac, res;
    integer vin16 [0:3];                      // inputs in 1/16 LSB
    integer held16 = 0;
    always @(posedge clk) if (sample) held16 <= vin16[ach];
    wire cmp = (held16 >= dac * 16);
    always #5 clk = ~clk;
    sar_adc_ctrl #(.N(8)) DUT (.clk(clk), .rst_n(rst_n), .en(en), .trig(trig), .cont(cont), .ch_sel(chs), .smp(smp), .div(div),
        .adc_cmp(cmp), .adc_sample(sample), .adc_ch(ach), .adc_dac(dac), .busy(busy), .eoc(eoc), .result(res), .result_ch(rch), .trig_miss(miss));
    integer wdg = 0;
    integer errors = 0, checks = 0, i, k, t0, ts, seed = 32'h5E203519, c_miss = 0, c_abort = 0, c_cont = 0;
    task fail; input [8*70:1] m; begin errors = errors + 1; if (errors < 12) $display("  FAIL t=%0t %0s", $time, m); end endtask
    // one software-started conversion; checks result, timing, sample width, channel
    task convert; input integer v16; input [1:0] c; input [7:0] s, d; input show;
        integer exp, nsample, tstart, wd;
        begin
            vin16[c] = v16; chs = c; smp = s; div = d; exp = v16 / 16; if (exp > 255) exp = 255;
            @(negedge clk); trig = 1; @(negedge clk); trig = 0; tstart = $time - 10;       // the start edge was 1 clock ago
            nsample = 0; wd = 0;
            while (!eoc && wd < 2000) begin @(negedge clk); wd = wd + 1; if (sample) nsample = nsample + 1; end   // watchdog
            if (wd >= 2000) begin fail("watchdog: no eoc"); disable convert; end
            checks = checks + 4;
            if (res !== exp[7:0]) fail("result != floor(input)");
            if (rch !== c) fail("result channel");
            if (($time - tstart) / 10 != (s + 9) * (d + 1) + 1) fail("conversion time");
            if (nsample != (s + 1) * (d + 1) - 1) fail("sample width");
            if (show) $display("  %6.3f LSB | ch %0d | SMP %0d DIV %0d | result %3d (%h) | expected %3d | %0d clocks | %s",
                               v16 / 16.0, c, s, d, res, res, exp, ($time - tstart) / 10 - 1, (res === exp[7:0]) ? "PASS" : "FAIL");
            @(negedge clk);
        end
    endtask
    initial begin
        $display("============================================================================");
        $display(" tb_sar_adc_ctrl : SAR state machine, timing, abort, trigger miss, continuous");
        $display(" Student: Vu Quoc Anh | Roll number: SE203519");
        $display("============================================================================");
        for (i = 0; i < 4; i = i + 1) vin16[i] = 0;
        #22 rst_n = 1; @(negedge clk); en = 1;
        $display("PART 1: every code and every midpoint (511 inputs), SMP 0, DIV 0; selected rows shown");
        $display("  input     | ch   | settings       | result        | expected     | time      | chk");
        for (k = 0; k <= 255 * 2; k = k + 1) convert(k * 8, k % 4, 0, 0, (k % 64 == 0) || k == 510 || k == 171);
        convert(1379, 1, 2, 0, 1);                                          // 86.19 LSB: the 1.111 V example
        $display("PART 2: 3,000 random conversions with random SMP, DIV, channel; abort, miss, continuous");
        for (k = 0; k < 3000; k = k + 1) convert($unsigned($random(seed)) % (256 * 16), $random(seed), $unsigned($random(seed)) % 6, $unsigned($random(seed)) % 4, 0);
        // abort: EN = 0 in the middle -> no eoc
        for (k = 0; k < 50; k = k + 1) begin
            smp = 3; div = 1; @(negedge clk); trig = 1; @(negedge clk); trig = 0;
            repeat ($unsigned($random(seed)) % 18 + 1) @(negedge clk); en = 0; @(negedge clk); en = 1;
            checks = checks + 1; repeat (30) begin @(negedge clk); if (eoc) fail("eoc after abort"); end
            if (busy) fail("busy after abort"); c_abort = c_abort + 1;
        end
        // trigger while busy -> trig_miss, the running conversion is not disturbed
        for (k = 0; k < 50; k = k + 1) begin
            vin16[0] = 100 * 16; chs = 0; smp = 1; div = 0; @(negedge clk); trig = 1; @(negedge clk); trig = 0;
            repeat ($unsigned($random(seed)) % 9 + 1) @(negedge clk); trig = 1; #1 checks = checks + 1;
            if (!miss) fail("no trig_miss while busy"); else c_miss = c_miss + 1; @(negedge clk); trig = 0;
            wdg = 0; while (!eoc && wdg < 2000) begin @(negedge clk); wdg = wdg + 1; end if (res !== 8'd100) fail("result disturbed by the missed trigger"); @(negedge clk);
        end
        // continuous: back-to-back conversions, period (SMP + 9)(DIV + 1) + 1
        vin16[2] = 77 * 16 + 5; chs = 2; smp = 2; div = 1; cont = 1; @(negedge clk);
        wdg = 0; while (!eoc && wdg < 2000) begin @(negedge clk); wdg = wdg + 1; end t0 = $time;
        for (k = 0; k < 20; k = k + 1) begin
            @(negedge clk); wdg = 0; while (!eoc && wdg < 2000) begin @(negedge clk); wdg = wdg + 1; end if (wdg >= 2000) fail("watchdog");
            checks = checks + 2; if (($time - t0) / 10 != (2 + 9) * 2 + 1) fail("continuous period"); if (res !== 8'd77) fail("continuous result");
            t0 = $time; c_cont = c_cont + 1;
        end
        cont = 0; en = 0; @(negedge clk); en = 1;
        $display("  coverage: aborts %0d, missed triggers %0d, continuous results %0d", c_abort, c_miss, c_cont);
        #1;
        if (errors == 0) $display("PASS: tb_sar_adc_ctrl (Vu Quoc Anh, SE203519) 512 directed + 3000 random conversions, %0d checks, 0 errors", checks);
        else $display("FAILED: tb_sar_adc_ctrl (Vu Quoc Anh, SE203519) %0d errors", errors);
        $finish(0);
    end
endmodule
