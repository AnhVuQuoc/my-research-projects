// =============================================================================
// File        : tb_timer8.v      Module: tb_timer8
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Part 1      : directed: the guide example (PRESC 1, LOAD 4, CMP 2) cycle by cycle,
//               LOAD = 0, CMP = 0, CMP > LOAD, one-shot, enable off
// Part 2      : 20,000 random clocks against an independent cycle model, with
//               random settings changed while running (constrained: small values
//               most of the time so that wraps and matches happen often)
// =============================================================================
`timescale 1ns / 1ps
module tb_timer8;
    reg clk = 0, rst_n = 0, en = 0, oneshot = 0; reg [7:0] presc = 0, load = 8'hFF, cmp = 8'h80;
    wire [7:0] cnt; wire tick, ovf, cmpp, osd, pwm;
    always #5 clk = ~clk;
    timer8 DUT (.clk(clk), .rst_n(rst_n), .en(en), .oneshot(oneshot), .presc(presc), .load(load), .cmp(cmp),
                .cnt(cnt), .tick(tick), .ovf_pulse(ovf), .cmp_pulse(cmpp), .oneshot_done(osd), .pwm_out(pwm));
    // ---------------- independent model (written from the specification)
    integer mp = 0, mc = 0, mpwm = 0, errors = 0, checks = 0, i, seed = 32'h5E203519;
    integer c_ovf = 0, c_cmp = 0, c_os = 0, c_load0 = 0, c_cmpgt = 0;
    reg m_tick, m_ovf, m_cmp;
    always @(*) begin
        m_tick = en && (mp >= presc); m_ovf = m_tick && (mc >= load); m_cmp = m_tick && (mc == cmp);
    end
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin mp <= 0; mc <= 0; mpwm <= 0; end
        else if (!en) begin mp <= 0; mc <= 0; mpwm <= 0; end
        else begin mp <= m_tick ? 0 : mp + 1; if (m_tick) mc <= m_ovf ? 0 : mc + 1; mpwm <= (mc < cmp); end
    task cmpnow; input [8*30:1] w; begin
        checks = checks + 1;
        if (cnt !== mc[7:0] || tick !== m_tick || ovf !== m_ovf || cmpp !== m_cmp || osd !== (m_ovf & oneshot) || pwm !== mpwm[0]) begin
            errors = errors + 1; if (errors < 10) $display("  FAIL %0s t=%0t cnt %0d/%0d ovf %b/%b cmp %b/%b pwm %b/%b", w, $time, cnt, mc, ovf, m_ovf, cmpp, m_cmp, pwm, mpwm[0]); end
        if (ovf) c_ovf = c_ovf + 1; if (cmpp) c_cmp = c_cmp + 1; if (osd) c_os = c_os + 1;
        if (ovf && load == 0) c_load0 = c_load0 + 1; if (en && cmp > load) c_cmpgt = c_cmpgt + 1;
    end endtask
    always @(negedge clk) if (rst_n) #2 cmpnow("cycle");     // sample after the stimulus has settled
    always @(posedge clk) if (osd) en <= 1'b0;                 // the register block clears EN
    reg [8*12:1] lineb;
    initial begin
        $display("============================================================================");
        $display(" tb_timer8 : prescaler, counter, compare, PWM, one-shot");
        $display(" Student: Vu Quoc Anh | Roll number: SE203519");
        $display("============================================================================");
        #22 rst_n = 1;
        $display("PART 1: guide example PRESC = 1, LOAD = 4, CMP = 2 (period 10 clocks)");
        $display("  clk | cnt | tick | cmp_pulse | ovf_pulse | pwm_out");
        @(negedge clk); presc = 1; load = 4; cmp = 2; en = 1;
        for (i = 1; i <= 12; i = i + 1) begin @(negedge clk); #1 $display("  %3d | %3d |  %b   |     %b     |     %b     |    %b", i, cnt, tick, cmpp, ovf, pwm); end
        en = 0; @(negedge clk); load = 0; cmp = 0; presc = 0; en = 1; repeat (6) @(negedge clk);     // LOAD = 0: overflow every tick
        en = 0; @(negedge clk); load = 5; cmp = 9; en = 1; repeat (14) @(negedge clk);              // CMP > LOAD: PWM always high
        en = 0; @(negedge clk); load = 3; cmp = 1; oneshot = 1; en = 1; repeat (12) @(negedge clk); oneshot = 0;
        $display("PART 2: 20,000 random clocks, settings changed while running");
        for (i = 0; i < 20000; i = i + 1) begin
            @(negedge clk);
            if (($unsigned($random(seed)) % 200) == 0) presc = ($unsigned($random(seed)) % 8 == 0) ? $random(seed) : $unsigned($random(seed)) % 4;
            if (($unsigned($random(seed)) % 150) == 0) load  = ($unsigned($random(seed)) % 8 == 0) ? $random(seed) : $unsigned($random(seed)) % 12;
            if (($unsigned($random(seed)) % 100) == 0) cmp   = $unsigned($random(seed)) % 14;
            if (($unsigned($random(seed)) % 300) == 0) oneshot = $random(seed);
            if (($unsigned($random(seed)) % 250) == 0 || !en) en = ($unsigned($random(seed)) % 4) != 0;
        end
        $display("  coverage: overflows %0d, compares %0d, one-shot stops %0d, LOAD = 0 wraps %0d, clocks with CMP > LOAD %0d", c_ovf, c_cmp, c_os, c_load0, c_cmpgt);
        if (c_ovf == 0 || c_cmp == 0 || c_os == 0 || c_load0 == 0 || c_cmpgt == 0) begin errors = errors + 1; $display("  FAIL coverage goal missed"); end
        #1;
        if (errors == 0) $display("PASS: tb_timer8 (Vu Quoc Anh, SE203519) %0d cycle checks, 0 errors", checks);
        else $display("FAILED: tb_timer8 (Vu Quoc Anh, SE203519) %0d errors", errors);
        $finish(0);
    end
endmodule
