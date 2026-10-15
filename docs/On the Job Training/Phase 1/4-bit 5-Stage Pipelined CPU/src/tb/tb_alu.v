// =============================================================================
// File        : tb_alu.v
// Module      : tb_alu   (self-checking testbench for alu)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 15 directed cases, one every 10 ns (row t = inputs applied at
//               t, outputs sampled at t + 5 ns). Expected values by hand.
// Part 2      : exhaustive: every a (16) x every b (16) x every alu_ctrl (8)
//               = 2048 cases against an independent integer reference.
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_alu;

    reg  [3:0] a, b;
    reg  [2:0] alu_ctrl;
    wire [3:0] result;
    wire       carry, zero;

    integer errors = 0, n_dir = 0, n_exh = 0;
    integer ia, ib, ic;

    alu DUT (.a(a), .b(b), .alu_ctrl(alu_ctrl), .result(result), .carry(carry), .zero(zero));

    // ---- independent reference: integer arithmetic, no shared adder -------
    reg [3:0] ref_result;
    reg       ref_carry, ref_zero;
    task reference;
        input [3:0] x, y; input [2:0] op;
        integer t;
        begin
            ref_carry = 1'b0;
            case (op)
                3'd0: begin t = x + y; ref_result = t % 16; ref_carry = (t >= 16); end
                3'd1: begin t = x - y; if (t < 0) t = t + 16;
                            ref_result = t; ref_carry = (x >= y); end
                3'd2: ref_result = x & y;
                3'd3: ref_result = x | y;
                3'd4: ref_result = x ^ y;
                3'd5: ref_result = ~x;
                3'd6: ref_result = y;
                default: ref_result = 4'd0;
            endcase
            ref_zero = (ref_result == 4'd0);
        end
    endtask

    function [8*4:1] opname; input [2:0] op;
        case (op)
            3'd0: opname = "ADD "; 3'd1: opname = "SUB "; 3'd2: opname = "AND ";
            3'd3: opname = "OR  "; 3'd4: opname = "XOR "; 3'd5: opname = "NOT ";
            3'd6: opname = "PASS"; default: opname = "7   ";
        endcase
    endfunction

    // ---- one directed case (expected values written by hand) ---------------
    task dcase;
        input [3:0] x, y; input [2:0] op;
        input [3:0] e_res; input e_c; input e_z;
        input [8*22:1] note;
        reg ok;
        begin
            a = x; b = y; alu_ctrl = op;
            #5;
            n_dir = n_dir + 1;
            ok = (result === e_res) && (carry === e_c) && (zero === e_z);
            if (!ok) errors = errors + 1;
            $display("  %t | %b | %b | %s |  %b  | %b | %b |  %b %b %b  | %s | %0s",
                     $time - 5, a, b, opname(op), result, carry, zero,
                     e_res, e_c, e_z, ok ? "PASS" : "FAIL", note);
            #5;
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_alu.vcd"); $dumpvars(0, tb_alu); end
        $display("============================================================================");
        $display(" tb_alu : self-checking testbench for module alu");
        $display(" Student: Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        a = 0; b = 0; alu_ctrl = 0;
        #10;
        $display("\nPART 1: directed cases (row t: inputs applied at t, sampled at t + 5 ns)");
        $display("  time | a    | b    | op   | result| C | Z | exp R  C Z | chk  | note");
        $display("  -----+------+------+------+-------+---+---+------------+------+-----");
        //    a        b        op    result   C  Z  note
        dcase(4'b0101, 4'b0011, 3'd0, 4'b1000, 0, 0, "5 + 3 = 8 fits");
        dcase(4'b1111, 4'b0001, 3'd0, 4'b0000, 1, 1, "15 + 1 overflows to 0");
        dcase(4'b0111, 4'b1000, 3'd0, 4'b1111, 0, 0, "7 + 8 = 15 largest");
        dcase(4'b0101, 4'b0011, 3'd1, 4'b0010, 1, 0, "5 - 3, no borrow");
        dcase(4'b0011, 4'b0101, 3'd1, 4'b1110, 0, 0, "3 - 5, borrow");
        dcase(4'b0111, 4'b0111, 3'd1, 4'b0000, 1, 1, "7 - 7 = 0, no borrow");
        dcase(4'b0000, 4'b0001, 3'd1, 4'b1111, 0, 0, "0 - 1 = 15, borrow");
        dcase(4'b1100, 4'b1010, 3'd2, 4'b1000, 0, 0, "AND");
        dcase(4'b1100, 4'b1010, 3'd3, 4'b1110, 0, 0, "OR");
        dcase(4'b1100, 4'b1010, 3'd4, 4'b0110, 0, 0, "XOR");
        dcase(4'b0110, 4'b0110, 3'd4, 4'b0000, 0, 1, "XOR with itself = 0");
        dcase(4'b0101, 4'b0000, 3'd5, 4'b1010, 0, 0, "NOT uses a only");
        dcase(4'b1111, 4'b0110, 3'd5, 4'b0000, 0, 1, "NOT 1111 = 0");
        dcase(4'b0000, 4'b1001, 3'd6, 4'b1001, 0, 0, "PASS copies b");
        dcase(4'b1010, 4'b0101, 3'd7, 4'b0000, 0, 1, "unused code 7 -> 0");

        $display("\nPART 2: exhaustive check against the integer reference (2048 cases)");
        for (ic = 0; ic < 8; ic = ic + 1)
            for (ia = 0; ia < 16; ia = ia + 1)
                for (ib = 0; ib < 16; ib = ib + 1) begin
                    a = ia; b = ib; alu_ctrl = ic;
                    #1;
                    reference(a, b, alu_ctrl);
                    n_exh = n_exh + 1;
                    if (result !== ref_result || carry !== ref_carry || zero !== ref_zero) begin
                        errors = errors + 1;
                        $display("  FAIL a=%b b=%b op=%0d : got %b C%b Z%b, reference %b C%b Z%b",
                                 a, b, alu_ctrl, result, carry, zero, ref_result, ref_carry, ref_zero);
                    end
                end
        $display("  %0d exhaustive cases compared", n_exh);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_alu (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_exh);
        else
            $display("FAILED: tb_alu (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_exh);
        $finish(0);
    end

endmodule

`default_nettype wire
