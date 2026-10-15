// =============================================================================
// File        : tb_program_counter.v
// Module      : tb_program_counter   (self-checking testbench for program_counter)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Clock       : rising edges at 10, 20, 30 ... ns. Row t: inputs applied at
//               t - 5 ns, pc_out sampled at t + 5 ns (after the edge at t).
// Part 1      : 8 directed cycles; Part 2: 1000 random cycles vs a model
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_program_counter;

    reg        clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end

    reg        rst = 1'b1, pc_en = 1'b0;
    reg  [3:0] pc_next = 4'd0;
    wire [3:0] pc_out;
    reg  [3:0] model;
    integer    errors = 0, n_dir = 0, n_rnd = 0;
    integer    c, seed = 32'h5E203519;

    program_counter DUT (.clk(clk), .rst(rst), .pc_en(pc_en), .pc_next(pc_next), .pc_out(pc_out));

    task dcycle;
        input r; input en; input [3:0] nxt; input [3:0] e_pc; input [8*30:1] note;
        reg ok;
        begin
            rst = r; pc_en = en; pc_next = nxt;
            @(posedge clk); @(negedge clk);
            n_dir = n_dir + 1; ok = (pc_out === e_pc); if (!ok) errors = errors + 1;
            $display("  %t |  %b   |   %b   |   %2d    |   %2d   |   %2d    | %s | %0s",
                     $time - 5, rst, pc_en, pc_next, pc_out, e_pc, ok ? "PASS" : "FAIL", note);
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_program_counter.vcd"); $dumpvars(0, tb_program_counter); end
        $display("============================================================================");
        $display(" tb_program_counter : self-checking testbench for module program_counter");
        $display(" Student            : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado             : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge, sampled at t + 5 ns)");
        $display("  time | rst | pc_en | pc_next | pc_out | expected | chk  | note");
        $display("  -----+-----+-------+---------+--------+----------+------+-----");
        dcycle(1'b1, 1'b0, 4'd0,  4'd0,  "reset -> 0");
        dcycle(1'b0, 1'b1, 4'd1,  4'd1,  "step to PC + 1");
        dcycle(1'b0, 1'b1, 4'd2,  4'd2,  "step again");
        dcycle(1'b0, 1'b0, 4'd9,  4'd2,  "pc_en = 0: hold (stall)");
        dcycle(1'b0, 1'b1, 4'd9,  4'd9,  "branch target 9");
        dcycle(1'b0, 1'b1, 4'd15, 4'd15, "highest address");
        dcycle(1'b0, 1'b1, 4'd0,  4'd0,  "PC + 1 of 15 wraps to 0");
        dcycle(1'b1, 1'b1, 4'd7,  4'd0,  "reset wins over pc_en");

        $display("\nPART 2: 1000 random cycles against the reference model");
        model = 4'd0;
        for (c = 0; c < 1000; c = c + 1) begin
            rst = (($unsigned($random(seed)) % 40) == 0);
            pc_en = $random(seed); pc_next = $random(seed);
            @(posedge clk);
            if (rst) model = 4'd0; else if (pc_en) model = pc_next;
            @(negedge clk);
            n_rnd = n_rnd + 1;
            if (pc_out !== model) begin
                errors = errors + 1;
                $display("  FAIL cycle %0d: pc_out=%0d model=%0d", c, pc_out, model);
            end
        end
        $display("  %0d random cycles compared", n_rnd);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_program_counter (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_rnd);
        else
            $display("FAILED: tb_program_counter (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_rnd);
        $finish(0);
    end

endmodule

`default_nettype wire
