// =============================================================================
// File        : tb_program_counter.v
// Module      : tb_program_counter   (self-checking testbench for program_counter)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 8 directed cycles (sampled 5 ns after the edge)
// Part 2      : 2000 random cycles against a 1-line model
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_program_counter;
    reg clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end
    reg rst = 1'b1, pc_en = 1'b0; reg [7:0] pc_next = 0; wire [7:0] pc_out; reg [7:0] model;
    integer errors = 0, n_dir = 0, n_p2 = 0, c, seed = 32'h5E203519;
    program_counter DUT (.clk(clk), .rst(rst), .pc_en(pc_en), .pc_next(pc_next), .pc_out(pc_out));
    task dcycle; input r, en; input [7:0] nx, e; input [8*28:1] note;
        reg ok; begin
            rst = r; pc_en = en; pc_next = nx; @(posedge clk); @(negedge clk);
            n_dir = n_dir + 1; ok = (pc_out === e); if (!ok) errors = errors + 1;
            $display("  %t |  %b  |   %b   |   %3d   |  %3d   |   %3d    | %s | %0s", $time - 5, rst, pc_en, pc_next, pc_out, e, ok ? "PASS" : "FAIL", note);
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_program_counter.vcd"); $dumpvars(0, tb_program_counter); end
        $display("============================================================================");
        $display(" tb_program_counter : self-checking testbench for module program_counter");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge, sampled at t + 5 ns)");
        $display("  time | rst | pc_en | pc_next | pc_out | expected | chk  | note");
        dcycle(1,0,8'd0,8'd0,"reset -> 0");
        dcycle(0,1,8'd1,8'd1,"step to PC + 1");
        dcycle(0,1,8'd2,8'd2,"step again");
        dcycle(0,0,8'd99,8'd2,"pc_en = 0: hold (stall, halt)");
        dcycle(0,1,8'd200,8'd200,"branch target 200");
        dcycle(0,1,8'd255,8'd255,"highest address");
        dcycle(0,1,8'd0,8'd0,"PC + 1 of 255 wraps to 0");
        dcycle(1,1,8'd7,8'd0,"reset wins over pc_en");
        $display("\nPART 2: 2000 random cycles against the reference model");
        model = 8'd0;
        for (c = 0; c < 2000; c = c + 1) begin
            rst = (($unsigned($random(seed)) % 40) == 0); pc_en = $random(seed); pc_next = $random(seed);
            @(posedge clk); if (rst) model = 8'd0; else if (pc_en) model = pc_next;
            @(negedge clk); n_p2 = n_p2 + 1; if (pc_out !== model) errors = errors + 1;
        end
        $display("  %0d random cycles compared", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_program_counter (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_program_counter (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
