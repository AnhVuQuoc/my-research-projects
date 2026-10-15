// =============================================================================
// File        : tb_id_ex_register.v
// Module      : tb_id_ex_register   (self-checking testbench for id_ex_register)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Clock       : rising edges at 10, 20, 30 ... ns. Row t: inputs applied at
//               t - 5 ns, outputs sampled at t + 5 ns (after the edge at t).
// Part 1      : 6 directed cycles (decoded ADD, LDI, LOAD, bubble ...)
// Part 2      : 1000 random cycles: all 42 output bits against a model
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_id_ex_register;

    reg         clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end

    reg         rst = 1'b1, bubble = 1'b0;
    reg  [41:0] in_vec = 42'd0;      // all *_in inputs packed in port order
    wire [41:0] out_vec;             // all outputs packed in the same order
    localparam [41:0] EMPTY = {3'd0, 6'b000000, 2'd0, 2'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 12'hC00};
    reg  [41:0] model;
    integer     errors = 0, n_dir = 0, n_rnd = 0;
    integer     c, seed = 32'h5E203519;

    // unpack: {alu_ctrl, src, wb, rwe, mwe, zwe, cwe, rd, rs, imm, rd_value, rs_value, pc, valid, instr}
    id_ex_register DUT (
        .clk(clk), .rst(rst), .bubble(bubble),
        .alu_ctrl_in(in_vec[41:39]), .alu_src_sel_in(in_vec[38]), .wb_sel_in(in_vec[37]),
        .reg_we_in(in_vec[36]), .mem_we_in(in_vec[35]), .zero_we_in(in_vec[34]),
        .carry_we_in(in_vec[33]), .rd_in(in_vec[32:31]), .rs_in(in_vec[30:29]),
        .imm_in(in_vec[28:25]), .rd_value_in(in_vec[24:21]), .rs_value_in(in_vec[20:17]),
        .pc_in(in_vec[16:13]), .valid_in(in_vec[12]), .instr_in(in_vec[11:0]),
        .alu_ctrl(out_vec[41:39]), .alu_src_sel(out_vec[38]), .wb_sel(out_vec[37]),
        .reg_we(out_vec[36]), .mem_we(out_vec[35]), .zero_we(out_vec[34]),
        .carry_we(out_vec[33]), .rd(out_vec[32:31]), .rs(out_vec[30:29]),
        .imm(out_vec[28:25]), .rd_value(out_vec[24:21]), .rs_value(out_vec[20:17]),
        .pc(out_vec[16:13]), .valid(out_vec[12]), .instr(out_vec[11:0])
    );

    task show;
        input [41:0] v;
        $write("%0d %b%b%b%b%b%b R%0d R%0d %h %h %h %2d %b %h",
               v[41:39], v[38], v[37], v[36], v[35], v[34], v[33], v[32:31], v[30:29],
               v[28:25], v[24:21], v[20:17], v[16:13], v[12], v[11:0]);
    endtask

    task dcycle;
        input r, b; input [41:0] vin; input [41:0] e_out; input [8*24:1] note;
        reg ok;
        begin
            rst = r; bubble = b; in_vec = vin;
            @(posedge clk); @(negedge clk);
            n_dir = n_dir + 1; ok = (out_vec === e_out); if (!ok) errors = errors + 1;
            $write("  %t |  %b   %b  | ", $time - 5, rst, bubble);
            show(out_vec); $write(" | ");
            $display("%s | %0s", ok ? "PASS" : "FAIL", note);
        end
    endtask

    //            alu   src wb rwe mwe zwe cwe  rd    rs    imm  rdv  rsv  pc   v  instr
    localparam [41:0] V_ADD  = {3'd0, 6'b001011, 2'd1, 2'd2, 4'h0, 4'h5, 4'h3, 4'd2, 1'b1, 12'h060};
    localparam [41:0] V_LDI  = {3'd6, 6'b101000, 2'd3, 2'd0, 4'hA, 4'h0, 4'h0, 4'd3, 1'b1, 12'h6CA};
    localparam [41:0] V_LOAD = {3'd6, 6'b111000, 2'd0, 2'd0, 4'h3, 4'h0, 4'h0, 4'd7, 1'b1, 12'h803};

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_id_ex_register.vcd"); $dumpvars(0, tb_id_ex_register); end
        $display("============================================================================");
        $display(" tb_id_ex_register : self-checking testbench for module id_ex_register");
        $display(" Student           : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado            : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge, sampled at t + 5 ns)");
        $display("  time | rst bub | alu src.wb.rwe.mwe.zwe.cwe rd rs imm rdv rsv pc v instr | chk  | note");
        $display("  -----+---------+---------------------------------------------------------+------+-----");
        dcycle(1'b1, 1'b0, V_ADD,  EMPTY,  "reset: empty slot");
        dcycle(1'b0, 1'b0, V_ADD,  V_ADD,  "ADD R1,R2 passes");
        dcycle(1'b0, 1'b0, V_LDI,  V_LDI,  "LDI R3,10 passes");
        dcycle(1'b0, 1'b1, V_LOAD, EMPTY,  "bubble (stall): NOP");
        dcycle(1'b0, 1'b0, V_LOAD, V_LOAD, "LOAD R0,3 after stall");
        dcycle(1'b1, 1'b0, V_ADD,  EMPTY,  "reset wins");

        $display("\nPART 2: 1000 random cycles against the reference model");
        model = EMPTY;
        for (c = 0; c < 1000; c = c + 1) begin
            rst    = (($unsigned($random(seed)) % 40) == 0);
            bubble = (($unsigned($random(seed)) % 5) == 0);
            in_vec = {$random(seed), $random(seed)};
            @(posedge clk);
            model = (rst || bubble) ? EMPTY : in_vec;
            @(negedge clk);
            n_rnd = n_rnd + 1;
            if (out_vec !== model) begin
                errors = errors + 1;
                $display("  FAIL cycle %0d: out %h model %h", c, out_vec, model);
            end
        end
        $display("  %0d random cycles compared", n_rnd);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_id_ex_register (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_rnd);
        else
            $display("FAILED: tb_id_ex_register (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_rnd);
        $finish(0);
    end

endmodule

`default_nettype wire
