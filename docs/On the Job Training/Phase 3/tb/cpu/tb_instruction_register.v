// =============================================================================
// File        : tb_instruction_register.v
// Module      : tb_instruction_register   (self-checking testbench for instruction_register)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 9 directed cycles (reset, load, hold, flush over load, reset over load)
// Part 2      : 2000 random cycles vs a model (rst/flush > ir_load > hold)
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_instruction_register;
    reg clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end
    reg rst = 1'b1, ir_load = 1'b0, flush = 1'b0; reg [15:0] instruction_in = 0; reg [7:0] pc_in = 0;
    wire [15:0] instruction_out; wire [7:0] pc_out; wire valid_out; reg [24:0] model;
    integer errors = 0, n_dir = 0, n_p2 = 0, c, seed = 32'h5E203519;
    instruction_register DUT (.clk(clk), .rst(rst), .ir_load(ir_load), .flush(flush), .instruction_in(instruction_in),
        .pc_in(pc_in), .instruction_out(instruction_out), .pc_out(pc_out), .valid_out(valid_out));
    task dcycle; input r, ld, fl; input [15:0] ins; input [7:0] pci; input [15:0] e_i; input [7:0] e_p; input e_v; input [8*26:1] note;
        reg ok; begin
            rst = r; ir_load = ld; flush = fl; instruction_in = ins; pc_in = pci; @(posedge clk); @(negedge clk);
            n_dir = n_dir + 1; ok = (instruction_out === e_i) && (pc_out === e_p) && (valid_out === e_v); if (!ok) errors = errors + 1;
            $display("  %t |  %b  %b  %b | %h %3d | %h %3d %b | %h %3d %b | %s | %0s", $time - 5, rst, ir_load, flush,
                     instruction_in, pc_in, instruction_out, pc_out, valid_out, e_i, e_p, e_v, ok ? "PASS" : "FAIL", note);
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_instruction_register.vcd"); $dumpvars(0, tb_instruction_register); end
        $display("============================================================================");
        $display(" tb_instruction_register : self-checking testbench for module instruction_register");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge, sampled at t + 5 ns)");
        $display("  time | rst ld fl | in   pc  | out  pc  v | expected   | chk  | note");
        dcycle(1,1,0,16'h8205,8'd0, 16'h0000,8'd0,0, "reset: empty slot (0000)");
        dcycle(0,1,0,16'h8205,8'd0, 16'h8205,8'd0,1, "load LDI R1,5");
        dcycle(0,1,0,16'h8403,8'd1, 16'h8403,8'd1,1, "load next word");
        dcycle(0,0,0,16'h1650,8'd2, 16'h8403,8'd1,1, "ir_load = 0: hold (stall)");
        dcycle(0,1,0,16'h1650,8'd2, 16'h1650,8'd2,1, "load after the stall");
        dcycle(0,1,1,16'h2850,8'd3, 16'h0000,8'd0,0, "flush (branch or halt) wins");
        dcycle(0,0,0,16'h5AE0,8'd4, 16'h0000,8'd0,0, "hold keeps the bubble");
        dcycle(0,1,0,16'h5AE0,8'd4, 16'h5AE0,8'd4,1, "load again");
        dcycle(1,1,0,16'hF000,8'd7, 16'h0000,8'd0,0, "reset wins over load");
        $display("\nPART 2: 2000 random cycles against the reference model");
        model = 25'd0;
        for (c = 0; c < 2000; c = c + 1) begin
            rst = (($unsigned($random(seed)) % 40) == 0); flush = (($unsigned($random(seed)) % 6) == 0);
            ir_load = $random(seed); instruction_in = $random(seed); pc_in = $random(seed);
            @(posedge clk);
            if (rst || flush) model = 25'd0; else if (ir_load) model = {instruction_in, pc_in, 1'b1};
            @(negedge clk); n_p2 = n_p2 + 1;
            if ({instruction_out, pc_out, valid_out} !== model) errors = errors + 1;
        end
        $display("  %0d random cycles compared", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_instruction_register (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_instruction_register (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
