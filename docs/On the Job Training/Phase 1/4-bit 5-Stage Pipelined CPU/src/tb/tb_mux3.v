// =============================================================================
// File        : tb_mux3.v
// Module      : tb_mux3   (self-checking testbench for mux3)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 5 directed cases, one every 10 ns (sampled at t + 5 ns)
// Part 2      : exhaustive 16 x 16 x 16 x 4 = 16384 cases against a reference
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_mux3;

    reg  [3:0] d0, d1, d2;
    reg  [1:0] sel;
    wire [3:0] y;
    integer errors = 0, n_dir = 0, n_exh = 0;
    integer i, j, m, s;
    reg [3:0] ref_y;

    mux3 DUT (.d0(d0), .d1(d1), .d2(d2), .sel(sel), .y(y));

    task dcase;
        input [3:0] x0, x1, x2; input [1:0] s_in; input [3:0] e_y; input [8*30:1] note;
        reg ok;
        begin
            d0 = x0; d1 = x1; d2 = x2; sel = s_in; #5;
            n_dir = n_dir + 1; ok = (y === e_y); if (!ok) errors = errors + 1;
            $display("  %t | %b | %b | %b | %b  | %b |  %b  | %s | %0s",
                     $time - 5, d0, d1, d2, sel, y, e_y, ok ? "PASS" : "FAIL", note);
            #5;
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_mux3.vcd"); $dumpvars(0, tb_mux3); end
        $display("============================================================================");
        $display(" tb_mux3 : self-checking testbench for module mux3");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        d0 = 0; d1 = 0; d2 = 0; sel = 0; #10;
        $display("\nPART 1: directed cases (row t: inputs applied at t, sampled at t + 5 ns)");
        $display("  time | d0   | d1   | d2   | sel | y    | exp  | chk  | note");
        $display("  -----+------+------+------+-----+------+------+------+-----");
        dcase(4'b0001, 4'b0010, 4'b0100, 2'b00, 4'b0001, "00 = FWD_ID, register value");
        dcase(4'b0001, 4'b0010, 4'b0100, 2'b01, 4'b0010, "01 = FWD_WB, wb_data");
        dcase(4'b0001, 4'b0010, 4'b0100, 2'b10, 4'b0100, "10 = FWD_MEM, EX/MEM result");
        dcase(4'b0001, 4'b0010, 4'b0100, 2'b11, 4'b0001, "11 unused, safe default d0");
        dcase(4'b1111, 4'b0000, 4'b1010, 2'b10, 4'b1010, "other data, sel 10");

        $display("\nPART 2: exhaustive check (16384 cases)");
        for (s = 0; s < 4; s = s + 1)
            for (i = 0; i < 16; i = i + 1)
                for (j = 0; j < 16; j = j + 1)
                    for (m = 0; m < 16; m = m + 1) begin
                        d0 = i; d1 = j; d2 = m; sel = s; #1;
                        if (s == 1) ref_y = j; else if (s == 2) ref_y = m; else ref_y = i;
                        n_exh = n_exh + 1;
                        if (y !== ref_y) begin
                            errors = errors + 1;
                            $display("  FAIL d0=%b d1=%b d2=%b sel=%b y=%b", d0, d1, d2, sel, y);
                        end
                    end
        $display("  %0d exhaustive cases compared", n_exh);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_mux3 (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_exh);
        else
            $display("FAILED: tb_mux3 (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_exh);
        $finish(0);
    end

endmodule

`default_nettype wire
