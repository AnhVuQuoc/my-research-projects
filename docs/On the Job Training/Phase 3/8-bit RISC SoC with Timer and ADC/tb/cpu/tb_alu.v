// =============================================================================
// File        : tb_alu.v
// Module      : tb_alu   (self-checking testbench for alu)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 18 directed cases, 1 every 10 ns (applied at t, sampled at t + 5 ns)
// Part 2      : exhaustive: every a (256) x every b (256) x alu_ctrl 0..9 = 655360 cases vs an integer reference
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_alu;
    reg  [7:0] a, b;
    reg  [3:0] alu_ctrl;
    wire [7:0] result;
    wire       carry, zero;
    integer errors = 0, n_dir = 0, n_p2 = 0, ia, ib, ic, t;
    reg [7:0] rr; reg rc, rz;
    alu DUT (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .carry(carry), .zero(zero));

    task reference; input [7:0] x, y; input [3:0] op;
        begin
            rc = 1'b0;
            case (op)
                4'd0: begin t = x + y; rr = t % 256; rc = (t > 255); end
                4'd1: begin t = x - y; if (t < 0) t = t + 256; rr = t; rc = (x < y); end
                4'd2: rr = x & y;  4'd3: rr = x | y;  4'd4: rr = x ^ y;
                4'd5: begin rr = (x * 2) % 256; rc = (x >= 128); end
                4'd6: begin rr = x / 2; rc = x % 2; end
                4'd7: rr = y;  4'd8: rr = x;
                default: rr = 8'd0;
            endcase
            rz = (rr == 8'd0);
        end
    endtask
    task dcase; input [7:0] x, y; input [3:0] op; input [7:0] e_r; input e_c, e_z; input [8*26:1] note;
        reg ok;
        begin
            a = x; b = y; alu_ctrl = op; #5;
            n_dir = n_dir + 1; ok = (result === e_r) && (carry === e_c) && (zero === e_z);
            if (!ok) errors = errors + 1;
            $display("  %t |  %h |  %h |  %0d  |   %h   | %b | %b |  %h %b %b  | %s | %0s", $time - 5, a, b, op,
                     result, carry, zero, e_r, e_c, e_z, ok ? "PASS" : "FAIL", note);
            #5;
        end
    endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_alu.vcd"); $dumpvars(0, tb_alu); end
        $display("============================================================================");
        $display(" tb_alu : self-checking testbench for module alu");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        a = 0; b = 0; alu_ctrl = 0; #10;
        $display("\nPART 1: directed cases (row t: applied at t, sampled at t + 5 ns)");
        $display("  time |  a  |  b  | op | result | C | Z | exp R  C Z | chk  | note");
        $display("  -----+-----+-----+----+--------+---+---+------------+------+-----");
        dcase(8'd5,   8'd3,   4'd0, 8'd8,   0, 0, "ADD 5 + 3");
        dcase(8'd200, 8'd100, 4'd0, 8'd44,  1, 0, "ADD 200 + 100 carries");
        dcase(8'd255, 8'd1,   4'd0, 8'd0,   1, 1, "ADD 255 + 1 = 0");
        dcase(8'd100, 8'd30,  4'd1, 8'd70,  0, 0, "SUB 100 - 30, no borrow");
        dcase(8'd100, 8'd200, 4'd1, 8'd156, 1, 0, "SUB 100 - 200, borrow");
        dcase(8'd77,  8'd77,  4'd1, 8'd0,   0, 1, "SUB equal: Z = 1, C = 0");
        dcase(8'd0,   8'd1,   4'd1, 8'd255, 1, 0, "SUB 0 - 1 = 255, borrow");
        dcase(8'hF0,  8'h3C,  4'd2, 8'h30,  0, 0, "AND");
        dcase(8'hF0,  8'h3C,  4'd3, 8'hFC,  0, 0, "OR");
        dcase(8'hF0,  8'h3C,  4'd4, 8'hCC,  0, 0, "XOR");
        dcase(8'h5A,  8'h5A,  4'd4, 8'h00,  0, 1, "XOR with itself = 0");
        dcase(8'hF0,  8'h00,  4'd5, 8'hE0,  1, 0, "SHL: C = old bit 7");
        dcase(8'h80,  8'h00,  4'd5, 8'h00,  1, 1, "SHL 80 = 0, C = 1");
        dcase(8'h3C,  8'h00,  4'd6, 8'h1E,  0, 0, "SHR: C = old bit 0 = 0");
        dcase(8'h01,  8'h00,  4'd6, 8'h00,  1, 1, "SHR 01 = 0, C = 1");
        dcase(8'h11,  8'hA5,  4'd7, 8'hA5,  0, 0, "PASS_B (LDI)");
        dcase(8'h81,  8'hA5,  4'd8, 8'h81,  0, 0, "PASS_A (LD/ST address)");
        dcase(8'h12,  8'h34,  4'd9, 8'h00,  0, 1, "unused code 9 -> 0");
        $display("\nPART 2: exhaustive check against the integer reference (655360 cases)");
        for (ic = 0; ic < 10; ic = ic + 1)
            for (ia = 0; ia < 256; ia = ia + 1)
                for (ib = 0; ib < 256; ib = ib + 1) begin
                    a = ia; b = ib; alu_ctrl = ic; #1; reference(a, b, alu_ctrl); n_p2 = n_p2 + 1;
                    if (result !== rr || carry !== rc || zero !== rz) begin
                        errors = errors + 1;
                        if (errors < 10) $display("  FAIL a=%h b=%h op=%0d got %h C%b Z%b ref %h C%b Z%b", a, b, alu_ctrl, result, carry, zero, rr, rc, rz);
                    end
                end
        $display("  %0d exhaustive cases compared", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_alu (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_alu (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
