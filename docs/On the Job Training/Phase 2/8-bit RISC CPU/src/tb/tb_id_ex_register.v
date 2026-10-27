// =============================================================================
// File        : tb_id_ex_register.v
// Module      : tb_id_ex_register   (self-checking testbench for id_ex_register)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 5 directed cycles (reset, real instructions, bubble or reset)
// Part 2      : 2000 random cycles; all 68 output bits against a model
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_id_ex_register;
    reg clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end
    reg rst = 1'b1, bubble = 1'b0; reg [67:0] in_vec = 0; wire [67:0] out_vec; reg [67:0] model;
    integer errors = 0, n_dir = 0, n_p2 = 0, c, seed = 32'h5E203519;
    id_ex_register DUT (.clk(clk), .rst(rst), .bubble(bubble), .alu_ctrl_in(in_vec[67:64]), .alu_src_sel_in(in_vec[63]), .wb_sel_in(in_vec[62]), .reg_we_in(in_vec[61]), .mem_we_in(in_vec[60]), .zero_we_in(in_vec[59]), .carry_we_in(in_vec[58]), .rd_in(in_vec[57:55]), .ra_in(in_vec[54:52]), .rb_in(in_vec[51:49]), .imm_in(in_vec[48:41]), .a_value_in(in_vec[40:33]), .b_value_in(in_vec[32:25]), .pc_in(in_vec[24:17]), .valid_in(in_vec[16]), .instr_in(in_vec[15:0]), .alu_ctrl(out_vec[67:64]), .alu_src_sel(out_vec[63]), .wb_sel(out_vec[62]), .reg_we(out_vec[61]), .mem_we(out_vec[60]), .zero_we(out_vec[59]), .carry_we(out_vec[58]), .rd(out_vec[57:55]), .ra(out_vec[54:52]), .rb(out_vec[51:49]), .imm(out_vec[48:41]), .a_value(out_vec[40:33]), .b_value(out_vec[32:25]), .pc(out_vec[24:17]), .valid(out_vec[16]), .instr(out_vec[15:0]));
    task dcycle; input r, b; input [67:0] vin, e; input [8*30:1] note;
        reg ok; begin
            rst = r; bubble = b; in_vec = vin; @(posedge clk); @(negedge clk); n_dir = n_dir + 1;
            ok = (out_vec === e); if (!ok) errors = errors + 1;
            $display("  %t |  %b   %b  | %h | %s | %0s", $time - 5, rst, bubble, out_vec, ok ? "PASS" : "FAIL", note);
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_id_ex_register.vcd"); $dumpvars(0, tb_id_ex_register); end
        $display("============================================================================");
        $display(" tb_id_ex_register : self-checking testbench for module id_ex_register");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge, sampled at t + 5 ns; outputs packed in port order)");
        $display("  time | rst bubble | outputs (hex) | chk  | note");
        dcycle(1, 0, {4'd0,6'b001011,3'd3,3'd1,3'd2,8'd0,8'h05,8'h03,8'd2,1'b1,16'h1650}, 68'd0, "reset: empty slot (all 0)");
        dcycle(0, 0, {4'd0,6'b001011,3'd3,3'd1,3'd2,8'd0,8'h05,8'h03,8'd2,1'b1,16'h1650}, {4'd0,6'b001011,3'd3,3'd1,3'd2,8'd0,8'h05,8'h03,8'd2,1'b1,16'h1650}, "ADD R3,R1,R2 passes");
        dcycle(0, 1, {4'd8,6'b011000,3'd3,3'd1,3'd0,8'h40,8'h80,8'h00,8'd3,1'b1,16'hA640}, 68'd0, "bubble (stall): NOP");
        dcycle(0, 0, {4'd8,6'b011000,3'd3,3'd1,3'd0,8'h40,8'h80,8'h00,8'd3,1'b1,16'hA640}, {4'd8,6'b011000,3'd3,3'd1,3'd0,8'h40,8'h80,8'h00,8'd3,1'b1,16'hA640}, "LD R3,[R1] after the stall");
        dcycle(1, 0, {4'd0,6'b001011,3'd3,3'd1,3'd2,8'd0,8'h05,8'h03,8'd2,1'b1,16'h1650}, 68'd0, "reset wins");
        $display("\nPART 2: 2000 random cycles against the reference model");
        model = 68'd0;
        for (c = 0; c < 2000; c = c + 1) begin
            rst = (($unsigned($random(seed)) % 40) == 0); bubble = (($unsigned($random(seed)) % 5) == 0);
            in_vec = {$random(seed), $random(seed), $random(seed)};
            @(posedge clk); model = (rst || (1 && bubble)) ? 68'd0 : in_vec;
            @(negedge clk); n_p2 = n_p2 + 1; if (out_vec !== model) errors = errors + 1;
        end
        $display("  %0d random cycles compared (rst or bubble -> 0)", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_id_ex_register (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_id_ex_register (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
