// =============================================================================
// File        : tb_mux3.v
// Module      : tb_mux3   (self-checking testbench for mux3)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 5 directed cases, 1 every 10 ns
// Part 2      : 100000 random cases vs a reference (256^3 x 4 = 67 million is too many to test exhaustively)
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_mux3;
    reg [7:0] d0, d1, d2; reg [1:0] sel; wire [7:0] y; reg [7:0] ry;
    integer errors = 0, n_dir = 0, n_p2 = 0, i, seed = 32'h5E203519;
    mux3 DUT (.d0(d0), .d1(d1), .d2(d2), .sel(sel), .y(y));
    task dcase; input [7:0] x0, x1, x2; input [1:0] s_in; input [7:0] e; input [8*28:1] note;
        reg ok; begin
            d0 = x0; d1 = x1; d2 = x2; sel = s_in; #5; n_dir = n_dir + 1; ok = (y === e); if (!ok) errors = errors + 1;
            $display("  %t |  %h |  %h |  %h |  %b  |  %h |  %h  | %s | %0s", $time - 5, d0, d1, d2, sel, y, e, ok ? "PASS" : "FAIL", note); #5;
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_mux3.vcd"); $dumpvars(0, tb_mux3); end
        $display("============================================================================");
        $display(" tb_mux3 : self-checking testbench for module mux3");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        d0 = 0; d1 = 0; d2 = 0; sel = 0; #10;
        $display("\nPART 1: directed cases (row t: applied at t, sampled at t + 5 ns)");
        $display("  time | d0  | d1  | d2  | sel | y   | exp  | chk  | note");
        dcase(8'h11, 8'h22, 8'h44, 2'b00, 8'h11, "00 = FWD_ID, register value");
        dcase(8'h11, 8'h22, 8'h44, 2'b01, 8'h22, "01 = FWD_WB, wb_data");
        dcase(8'h11, 8'h22, 8'h44, 2'b10, 8'h44, "10 = FWD_MEM, EX/MEM result");
        dcase(8'h11, 8'h22, 8'h44, 2'b11, 8'h11, "11 unused, safe default d0");
        dcase(8'hFF, 8'h00, 8'hA5, 2'b10, 8'hA5, "other data, sel 10");
        $display("\nPART 2: 100000 random cases");
        for (i = 0; i < 100000; i = i + 1) begin
            d0 = $random(seed); d1 = $random(seed); d2 = $random(seed); sel = $random(seed); #1;
            ry = (sel == 2'b01) ? d1 : (sel == 2'b10) ? d2 : d0; n_p2 = n_p2 + 1;
            if (y !== ry) errors = errors + 1;
        end
        $display("  %0d random cases compared", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_mux3 (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_mux3 (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
