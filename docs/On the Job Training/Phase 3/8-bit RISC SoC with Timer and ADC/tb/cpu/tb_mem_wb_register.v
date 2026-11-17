// =============================================================================
// File        : tb_mem_wb_register.v
// Module      : tb_mem_wb_register   (self-checking testbench for mem_wb_register)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 3 directed cycles (reset, real instructions, bubble or reset)
// Part 2      : 2000 random cycles; all 46 output bits against a model
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_mem_wb_register;
    reg clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end
    reg rst = 1'b1, bubble = 1'b0; reg [45:0] in_vec = 0; wire [45:0] out_vec; reg [45:0] model;
    integer errors = 0, n_dir = 0, n_p2 = 0, c, seed = 32'h5E203519;
    mem_wb_register DUT (.clk(clk), .rst(rst), .alu_result_in(in_vec[45:38]), .mem_data_in(in_vec[37:30]), .rd_in(in_vec[29:27]), .reg_we_in(in_vec[26]), .wb_sel_in(in_vec[25]), .pc_in(in_vec[24:17]), .valid_in(in_vec[16]), .instr_in(in_vec[15:0]), .alu_result(out_vec[45:38]), .mem_data(out_vec[37:30]), .rd(out_vec[29:27]), .reg_we(out_vec[26]), .wb_sel(out_vec[25]), .pc(out_vec[24:17]), .valid(out_vec[16]), .instr(out_vec[15:0]));
    task dcycle; input r, b; input [45:0] vin, e; input [8*30:1] note;
        reg ok; begin
            rst = r; bubble = b; in_vec = vin; @(posedge clk); @(negedge clk); n_dir = n_dir + 1;
            ok = (out_vec === e); if (!ok) errors = errors + 1;
            $display("  %t |  %b   %b  | %h | %s | %0s", $time - 5, rst, bubble, out_vec, ok ? "PASS" : "FAIL", note);
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_mem_wb_register.vcd"); $dumpvars(0, tb_mem_wb_register); end
        $display("============================================================================");
        $display(" tb_mem_wb_register : self-checking testbench for module mem_wb_register");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge, sampled at t + 5 ns; outputs packed in port order)");
        $display("  time | rst bubble | outputs (hex) | chk  | note");
        dcycle(1, 0, {8'h80,8'h5A,3'd3,2'b11,8'd3,1'b1,16'hA640}, 46'd0, "reset: empty slot");
        dcycle(0, 0, {8'h80,8'h5A,3'd3,2'b11,8'd3,1'b1,16'hA640}, {8'h80,8'h5A,3'd3,2'b11,8'd3,1'b1,16'hA640}, "LD R3 retires: memory data 5A");
        dcycle(1, 0, {8'h80,8'h5A,3'd3,2'b11,8'd3,1'b1,16'hA640}, 46'd0, "reset wins");
        $display("\nPART 2: 2000 random cycles against the reference model");
        model = 46'd0;
        for (c = 0; c < 2000; c = c + 1) begin
            rst = (($unsigned($random(seed)) % 40) == 0); bubble = (($unsigned($random(seed)) % 5) == 0);
            in_vec = {$random(seed), $random(seed), $random(seed)};
            @(posedge clk); model = (rst || (0 && bubble)) ? 46'd0 : in_vec;
            @(negedge clk); n_p2 = n_p2 + 1; if (out_vec !== model) errors = errors + 1;
        end
        $display("  %0d random cycles compared (rst -> 0)", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_mem_wb_register (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_mem_wb_register (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
