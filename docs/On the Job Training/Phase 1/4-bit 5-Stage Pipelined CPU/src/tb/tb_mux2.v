// =============================================================================
// File        : tb_mux2.v
// Module      : tb_mux2   (self-checking testbench for mux2)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 6 directed cases, one every 10 ns (sampled at t + 5 ns)
// Part 2      : exhaustive 16 x 16 x 2 = 512 cases against a reference
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_mux2;

    reg  [3:0] d0, d1;
    reg        sel;
    wire [3:0] y;
    integer errors = 0, n_dir = 0, n_exh = 0;
    integer i, j, s;

    mux2 DUT (.d0(d0), .d1(d1), .sel(sel), .y(y));

    task dcase;
        input [3:0] x0, x1; input s_in; input [3:0] e_y; input [8*28:1] note;
        reg ok;
        begin
            d0 = x0; d1 = x1; sel = s_in; #5;
            n_dir = n_dir + 1; ok = (y === e_y); if (!ok) errors = errors + 1;
            $display("  %t | %b | %b |  %b  | %b |  %b  | %s | %0s",
                     $time - 5, d0, d1, sel, y, e_y, ok ? "PASS" : "FAIL", note);
            #5;
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_mux2.vcd"); $dumpvars(0, tb_mux2); end
        $display("============================================================================");
        $display(" tb_mux2 : self-checking testbench for module mux2");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        d0 = 0; d1 = 0; sel = 0; #10;
        $display("\nPART 1: directed cases (row t: inputs applied at t, sampled at t + 5 ns)");
        $display("  time | d0   | d1   | sel | y    | exp  | chk  | note");
        $display("  -----+------+------+-----+------+------+------+-----");
        dcase(4'b0101, 4'b1010, 1'b0, 4'b0101, "sel 0 picks d0 (PC + 1)");
        dcase(4'b0101, 4'b1010, 1'b1, 4'b1010, "sel 1 picks d1 (target)");
        dcase(4'b0000, 4'b1111, 1'b0, 4'b0000, "all-zero input passes");
        dcase(4'b0000, 4'b1111, 1'b1, 4'b1111, "all-one input passes");
        dcase(4'b1001, 4'b1001, 1'b0, 4'b1001, "equal inputs, sel 0");
        dcase(4'b1001, 4'b1001, 1'b1, 4'b1001, "equal inputs, sel 1");

        $display("\nPART 2: exhaustive check (512 cases)");
        for (s = 0; s < 2; s = s + 1)
            for (i = 0; i < 16; i = i + 1)
                for (j = 0; j < 16; j = j + 1) begin
                    d0 = i; d1 = j; sel = s; #1;
                    n_exh = n_exh + 1;
                    if (y !== (s ? j[3:0] : i[3:0])) begin
                        errors = errors + 1;
                        $display("  FAIL d0=%b d1=%b sel=%b y=%b", d0, d1, sel, y);
                    end
                end
        $display("  %0d exhaustive cases compared", n_exh);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_mux2 (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_exh);
        else
            $display("FAILED: tb_mux2 (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_exh);
        $finish(0);
    end

endmodule

`default_nettype wire
