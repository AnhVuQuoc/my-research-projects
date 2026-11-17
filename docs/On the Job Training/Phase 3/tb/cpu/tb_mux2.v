// =============================================================================
// File        : tb_mux2.v
// Module      : tb_mux2   (self-checking testbench for mux2)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 6 directed cases, 1 every 10 ns
// Part 2      : exhaustive 256 x 256 x 2 = 131072 cases
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_mux2;
    reg [7:0] d0, d1; reg sel; wire [7:0] y;
    integer errors = 0, n_dir = 0, n_p2 = 0, i, j, s;
    mux2 DUT (.d0(d0), .d1(d1), .sel(sel), .y(y));
    task dcase; input [7:0] x0, x1; input s_in; input [7:0] e; input [8*26:1] note;
        reg ok; begin
            d0 = x0; d1 = x1; sel = s_in; #5; n_dir = n_dir + 1; ok = (y === e); if (!ok) errors = errors + 1;
            $display("  %t |  %h |  %h |  %b  |  %h |  %h  | %s | %0s", $time - 5, d0, d1, sel, y, e, ok ? "PASS" : "FAIL", note); #5;
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_mux2.vcd"); $dumpvars(0, tb_mux2); end
        $display("============================================================================");
        $display(" tb_mux2 : self-checking testbench for module mux2");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        d0 = 0; d1 = 0; sel = 0; #10;
        $display("\nPART 1: directed cases (row t: applied at t, sampled at t + 5 ns)");
        $display("  time | d0  | d1  | sel | y   | exp  | chk  | note");
        dcase(8'h12, 8'hAB, 0, 8'h12, "sel 0 picks d0 (PC + 1)");
        dcase(8'h12, 8'hAB, 1, 8'hAB, "sel 1 picks d1 (target)");
        dcase(8'h00, 8'hFF, 0, 8'h00, "all zeros pass");
        dcase(8'h00, 8'hFF, 1, 8'hFF, "all ones pass");
        dcase(8'h5A, 8'h5A, 0, 8'h5A, "equal inputs, sel 0");
        dcase(8'h5A, 8'h5A, 1, 8'h5A, "equal inputs, sel 1");
        $display("\nPART 2: exhaustive check (131072 cases)");
        for (s = 0; s < 2; s = s + 1) for (i = 0; i < 256; i = i + 1) for (j = 0; j < 256; j = j + 1) begin
            d0 = i; d1 = j; sel = s; #1; n_p2 = n_p2 + 1;
            if (y !== (s ? j[7:0] : i[7:0])) errors = errors + 1;
        end
        $display("  %0d exhaustive cases compared", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_mux2 (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_mux2 (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
