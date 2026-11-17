// =============================================================================
// File        : tb_cpu_if.v      Module: tb_cpu_if
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Part 1      : CPU-style accesses on timer_adc8_cpu_if (1 clock each, as the MEM
//               stage makes them): ID, write then read in consecutive clocks,
//               rdata = 0 when cs = 0, a conversion through the analog model,
//               exactly 1 pop per LD, back-to-back LDs, irq, PWM duty
// =============================================================================
`timescale 1ns / 1ps
module tb_cpu_if;
    reg clk = 0, rst_n = 0, cs = 0, we = 0; reg [3:0] addr = 0; reg [7:0] wdata = 0;
    wire [7:0] rdata, dac; wire irq, pwm, smp, cmp; wire [1:0] ch;
    always #5 clk = ~clk;
    timer_adc8_cpu_if DUT (.clk(clk), .rst_n(rst_n), .cs(cs), .we(we), .addr(addr), .wdata(wdata), .rdata(rdata), .irq(irq),
        .pwm_out(pwm), .adc_sample(smp), .adc_ch(ch), .adc_dac(dac), .adc_cmp(cmp));
    afe_model #(.VREF(3.3)) AFE (.clk(clk), .sample(smp), .ch(ch), .dac(dac), .cmp(cmp));
    integer errors = 0, checks = 0, n, hi;
    reg [7:0] v;
    task chk; input [7:0] got, exp; input [8*44:1] m; begin checks = checks + 1;
        if (got === exp) $display("  PASS | %-44s | %h", m, got); else begin errors = errors + 1; $display("  FAIL | %-44s | %h, expected %h", m, got, exp); end end endtask
    task st; input [3:0] a; input [7:0] d; begin @(negedge clk); cs = 1; we = 1; addr = a; wdata = d; @(negedge clk); cs = 0; we = 0; end endtask
    task ld; input [3:0] a; output [7:0] d; begin @(negedge clk); cs = 1; we = 0; addr = a; #1 d = rdata; @(negedge clk); cs = 0; end endtask
    initial begin
        $display("============================================================================");
        $display(" tb_cpu_if : the 1-clock CPU bus of timer_adc8_cpu_if");
        $display(" Student: Vu Quoc Anh | Roll number: SE203519");
        $display("============================================================================");
        AFE.vin0 = 0.40; AFE.vin1 = 1.111; AFE.vin2 = 2.0; AFE.vin3 = 3.0;
        #22 rst_n = 1;
        ld(4'hF, v); chk(v, 8'hA8, "LD ID");
        @(negedge clk); cs = 1; we = 1; addr = 2; wdata = 8'h31; @(negedge clk); we = 0; #1 chk(rdata, 8'h31, "ST TMR_LOAD then LD in the next clock"); cs = 0;
        #1 chk(rdata, 8'h00, "rdata = 0 when cs = 0");
        ld(4'hC, v); chk(v, 8'h10, "ADC_STAT after reset");
        st(6, 2); st(5, 8'h13); n = 0; while (!DUT.u_periph.adc_eoc && n < 2000) begin @(negedge clk); n = n + 1; end   // watchdog
        $display("  info | conversion of ch1 finished %0d clocks after the ST", n + 1);
        @(negedge clk); ld(4'hB, v); chk(v, 8'h81, "ADC_RCH before the pop");
        ld(4'hA, v); chk(v, AFE.ideal_code(1.111), "ADC_DATA = code of 1.111 V");
        ld(4'hC, v); chk(v, 8'h10, "1 LD popped exactly 1 result");
        ld(4'hB, v); chk(v, 8'h50, "ADC_RCH after the pop: LCH = 1");
        st(5, 8'h03); n = 0; while (!DUT.u_periph.adc_eoc && n < 2000) begin @(negedge clk); n = n + 1; end @(negedge clk);
        st(5, 8'h33); n = 0; while (!DUT.u_periph.adc_eoc && n < 2000) begin @(negedge clk); n = n + 1; end @(negedge clk);
        ld(4'hC, v); chk(v, 8'h82, "2 results queued (WM | LEVEL 2)");
        @(negedge clk); cs = 1; we = 0; addr = 4'hA; #1 v = rdata; @(negedge clk); #1 chk(v, AFE.ideal_code(0.40), "back-to-back LD 1 (ch0)");
        v = rdata; @(negedge clk); cs = 0; chk(v, AFE.ideal_code(3.0), "back-to-back LD 2 (ch3)");
        ld(4'hC, v); chk(v, 8'h10, "empty after 2 back-to-back pops");
        ld(4'hE, v); chk(v, 8'h04, "IRQ_STAT = ADC_EOC");
        #1 chk(irq, 0, "irq low while IRQ_EN = 0");
        st(4'hD, 8'h04); #1 chk(irq, 1, "irq high after IRQ_EN = ADC_EOC");
        st(4'hE, 8'h04); #1 chk(irq, 0, "irq low after the W1C clear");
        st(1, 0); st(2, 9); st(3, 3); st(0, 1); repeat (5) @(negedge clk);
        hi = 0; for (n = 0; n < 100; n = n + 1) begin @(posedge clk); #1 if (pwm) hi = hi + 1; end
        chk(hi, 30, "PWM high clocks out of 100 (CMP 3, LOAD 9)");
        #1;
        if (errors == 0) $display("PASS: tb_cpu_if (Vu Quoc Anh, SE203519) %0d checks, 0 errors", checks);
        else $display("FAILED: tb_cpu_if (Vu Quoc Anh, SE203519) %0d errors", errors);
        $finish(0);
    end
endmodule
