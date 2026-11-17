// =============================================================================
// File        : tb_sync_fifo.v      Module: tb_sync_fifo
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Part 1      : directed: fill to full, overflow drop, push + pop while full,
//               pop while empty, pointer wrap-around
// Part 2      : 30,000 random clocks against a queue model; push and pop
//               probabilities change every 1,000 clocks so that the FIFO
//               spends time empty, half full and full
// =============================================================================
`timescale 1ns / 1ps
module tb_sync_fifo;
    reg clk = 0, rst_n = 0, push = 0, pop = 0; reg [9:0] din = 0;
    wire [9:0] dout; wire [3:0] level; wire empty, full, ovf;
    always #5 clk = ~clk;
    sync_fifo #(.W(10), .DEPTH(8), .AW(3)) DUT (.clk(clk), .rst_n(rst_n), .push(push), .din(din), .pop(pop),
        .dout(dout), .level(level), .empty(empty), .full(full), .overflow(ovf));
    reg [9:0] q [0:7]; integer qn = 0, qh = 0, errors = 0, checks = 0, i, k, pp = 50, pq = 50, seed = 32'h5E203519;
    integer c_full = 0, c_empty = 0, c_ovf = 0, c_pushpopfull = 0, c_popempty = 0;
    task check; begin checks = checks + 1;
        if (level !== qn || empty !== (qn == 0) || full !== (qn == 8) || (qn > 0 && dout !== q[qh]) || (qn == 0 && dout !== 10'd0) ||
            ovf !== (push && qn == 8 && !pop)) begin errors = errors + 1; if (errors < 10) $display("  FAIL t=%0t level %0d/%0d dout %h", $time, level, qn, dout); end
        if (qn == 8) c_full = c_full + 1; if (qn == 0) c_empty = c_empty + 1; if (ovf) c_ovf = c_ovf + 1;
        if (push && pop && qn == 8) c_pushpopfull = c_pushpopfull + 1; if (pop && qn == 0) c_popempty = c_popempty + 1;
    end endtask
    task model_edge; reg dp, dq; begin
        dq = pop && qn > 0; dp = push && (qn < 8 || dq);
        if (dq) begin qh = (qh + 1) % 8; qn = qn - 1; end
        if (dp) begin q[(qh + qn) % 8] = din; qn = qn + 1; end
    end endtask
    task step; input p, r; input [9:0] d; begin push = p; pop = r; din = d; #1 check; @(posedge clk); model_edge; @(negedge clk); end endtask
    initial begin
        $display("============================================================================");
        $display(" tb_sync_fifo : 8 x 10-bit first-word-fall-through FIFO");
        $display(" Student: Vu Quoc Anh | Roll number: SE203519");
        $display("============================================================================");
        #22 rst_n = 1; @(negedge clk);
        $display("PART 1: directed corner cases");
        for (i = 0; i < 9; i = i + 1) step(1, 0, 10'h100 + i);                   // 9th push overflows
        $display("  filled: level %0d full %b, 9th push dropped (overflow seen %0d)", level, full, c_ovf);
        step(1, 1, 10'h1AA);                                                         // push + pop while full
        $display("  push + pop while full: level %0d, head %h (the oldest)", level, dout);
        for (i = 0; i < 10; i = i + 1) step(0, 1, 0);                               // drain + pop while empty
        $display("  drained: level %0d empty %b, pops while empty %0d", level, empty, c_popempty);
        for (k = 0; k < 20; k = k + 1) begin step(1, 0, k); step(0, 1, 0); end      // pointer wrap
        $display("PART 2: 30,000 random clocks with changing push / pop rates");
        for (k = 0; k < 30000; k = k + 1) begin
            if (k % 1000 == 0) begin pp = $unsigned($random(seed)) % 100; pq = $unsigned($random(seed)) % 100; end
            step(($unsigned($random(seed)) % 100) < pp, ($unsigned($random(seed)) % 100) < pq, $random(seed));
        end
        $display("  coverage: full %0d, empty %0d, overflow %0d, push+pop while full %0d, pop while empty %0d", c_full, c_empty, c_ovf, c_pushpopfull, c_popempty);
        if (!c_full || !c_empty || !c_ovf || !c_pushpopfull || !c_popempty) begin errors = errors + 1; $display("  FAIL coverage goal missed"); end
        #1;
        if (errors == 0) $display("PASS: tb_sync_fifo (Vu Quoc Anh, SE203519) %0d cycle checks, 0 errors", checks);
        else $display("FAILED: tb_sync_fifo (Vu Quoc Anh, SE203519) %0d errors", errors);
        $finish(0);
    end
endmodule
