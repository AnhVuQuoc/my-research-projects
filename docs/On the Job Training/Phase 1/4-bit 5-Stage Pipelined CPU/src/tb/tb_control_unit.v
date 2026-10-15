// =============================================================================
// File        : tb_control_unit.v
// Module      : tb_control_unit   (self-checking testbench for control_unit)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 16 decoder rows (every opcode) + 6 branch rows, one every
//               10 ns (sampled at t + 5 ns). Expected rows typed from the
//               decoder truth table in the workbook.
// Part 2      : exhaustive 16 opcodes x zero_flag x stall = 64 cases
//               against a reference written from the ISA table.
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_control_unit;

    reg  [3:0] opcode;
    reg        zero_flag, stall;
    wire [2:0] alu_ctrl;
    wire       alu_src_sel, wb_sel, reg_we, mem_we, zero_we, carry_we;
    wire       uses_rd, uses_rs, is_jmp, is_jz, pc_sel, flush;
    integer    errors = 0, n_dir = 0, n_exh = 0;
    integer    o, z, s;

    control_unit DUT (
        .opcode(opcode), .zero_flag(zero_flag), .stall(stall),
        .alu_ctrl(alu_ctrl), .alu_src_sel(alu_src_sel), .wb_sel(wb_sel),
        .reg_we(reg_we), .mem_we(mem_we), .zero_we(zero_we), .carry_we(carry_we),
        .uses_rd(uses_rd), .uses_rs(uses_rs), .is_jmp(is_jmp), .is_jz(is_jz),
        .pc_sel(pc_sel), .flush(flush)
    );

    // 13 decoder bits, in this order:
    // alu_ctrl[2:0] src wb rwe mwe zwe cwe urd urs jmp jz
    wire [12:0] dec = {alu_ctrl, alu_src_sel, wb_sel, reg_we, mem_we, zero_we,
                       carry_we, uses_rd, uses_rs, is_jmp, is_jz};

    // ---- reference decoder, typed from the ISA table -----------------------
    function [12:0] ref_dec; input [3:0] op;
        case (op) //            alu  src wb  rwe mwe zwe cwe urd urs jmp jz
            4'h0: ref_dec = {3'd0, 1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0}; // ADD
            4'h1: ref_dec = {3'd1, 1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0}; // SUB
            4'h2: ref_dec = {3'd2, 1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0}; // AND
            4'h3: ref_dec = {3'd3, 1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0}; // OR
            4'h4: ref_dec = {3'd4, 1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0}; // XOR
            4'h5: ref_dec = {3'd5, 1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0}; // NOT
            4'h6: ref_dec = {3'd6, 1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}; // LDI
            4'h7: ref_dec = {3'd6, 1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0}; // MOV
            4'h8: ref_dec = {3'd6, 1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}; // LOAD
            4'h9: ref_dec = {3'd6, 1'b1,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0}; // STORE
            4'hA: ref_dec = {3'd0, 1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0}; // JMP
            4'hB: ref_dec = {3'd0, 1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1}; // JZ
            default: ref_dec = 13'd0;                                                 // NOP
        endcase
    endfunction

    function ref_pc_sel; input [3:0] op; input zf; input st;
        ref_pc_sel = ((op == 4'hA) || (op == 4'hB && zf)) && !st;
    endfunction

    function [8*5:1] mn; input [3:0] op;
        case (op)
            4'h0: mn = "ADD  "; 4'h1: mn = "SUB  "; 4'h2: mn = "AND  "; 4'h3: mn = "OR   ";
            4'h4: mn = "XOR  "; 4'h5: mn = "NOT  "; 4'h6: mn = "LDI  "; 4'h7: mn = "MOV  ";
            4'h8: mn = "LOAD "; 4'h9: mn = "STORE"; 4'hA: mn = "JMP  "; 4'hB: mn = "JZ   ";
            default: mn = "NOP  ";
        endcase
    endfunction

    task drow;   // decoder row
        input [3:0] op; input [12:0] e_dec;
        reg ok;
        begin
            opcode = op; zero_flag = 1'b0; stall = 1'b0; #5;
            n_dir = n_dir + 1;
            ok = (dec === e_dec) && (pc_sel === (op == 4'hA)) && (flush === pc_sel);
            if (!ok) errors = errors + 1;
            $display("  %t | %b %s |  %0d  %b   %b   %b   %b   %b   %b   %b   %b   %b   %b |   %b    %b  | %s",
                     $time - 5, op, mn(op), alu_ctrl, alu_src_sel, wb_sel, reg_we, mem_we,
                     zero_we, carry_we, uses_rd, uses_rs, is_jmp, is_jz, pc_sel, flush,
                     ok ? "PASS" : "FAIL");
            #5;
        end
    endtask

    task brow;   // branch row
        input [3:0] op; input zf; input st; input e_pc_sel; input [8*34:1] note;
        reg ok;
        begin
            opcode = op; zero_flag = zf; stall = st; #5;
            n_dir = n_dir + 1;
            ok = (pc_sel === e_pc_sel) && (flush === e_pc_sel);
            if (!ok) errors = errors + 1;
            $display("  %t | %s | %b |   %b   |   %b    %b  |   %b   | %s | %0s",
                     $time - 5, mn(op), zf, st, pc_sel, flush, e_pc_sel, ok ? "PASS" : "FAIL", note);
            #5;
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_control_unit.vcd"); $dumpvars(0, tb_control_unit); end
        $display("============================================================================");
        $display(" tb_control_unit : self-checking testbench for module control_unit");
        $display(" Student         : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado          : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        opcode = 0; zero_flag = 0; stall = 0; #10;
        $display("\nPART 1a: decoder truth table (zero_flag = 0, stall = 0)");
        $display("  time | opcode     | alu src wb rwe mwe zwe cwe urd urs jmp jz | pc_sel flush | chk");
        $display("  -----+------------+-----------------------------------------+--------------+-----");
        //        op     alu  src  wb   rwe  mwe  zwe  cwe  urd  urs  jmp  jz
        drow(4'h0, {3'd0,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0});
        drow(4'h1, {3'd1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b1,1'b1,1'b1,1'b0,1'b0});
        drow(4'h2, {3'd2,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0});
        drow(4'h3, {3'd3,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0});
        drow(4'h4, {3'd4,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b1,1'b0,1'b0});
        drow(4'h5, {3'd5,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0});
        drow(4'h6, {3'd6,1'b1,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});
        drow(4'h7, {3'd6,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0});
        drow(4'h8, {3'd6,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});
        drow(4'h9, {3'd6,1'b1,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0});
        drow(4'hA, {3'd0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0});
        drow(4'hB, {3'd0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1});
        drow(4'hC, 13'd0);
        drow(4'hD, 13'd0);
        drow(4'hE, 13'd0);
        drow(4'hF, 13'd0);

        $display("\nPART 1b: branch decision in ID");
        $display("  time | instr | Z | stall | pc_sel flush | exp | chk  | note");
        $display("  -----+-------+---+-------+--------------+-----+------+-----");
        brow(4'hA, 1'b0, 1'b0, 1'b1, "JMP is always taken");
        brow(4'hA, 1'b0, 1'b1, 1'b0, "JMP not taken while stalled");
        brow(4'hB, 1'b0, 1'b0, 1'b0, "JZ, Zero = 0: not taken");
        brow(4'hB, 1'b1, 1'b0, 1'b1, "JZ, Zero = 1: taken");
        brow(4'hB, 1'b1, 1'b1, 1'b0, "JZ waits (flag stall), decides later");
        brow(4'h0, 1'b1, 1'b0, 1'b0, "ADD with Zero = 1: not a branch");

        $display("\nPART 2: exhaustive check (16 opcodes x Z x stall = 64 cases)");
        for (o = 0; o < 16; o = o + 1)
            for (z = 0; z < 2; z = z + 1)
                for (s = 0; s < 2; s = s + 1) begin
                    opcode = o; zero_flag = z; stall = s; #1;
                    n_exh = n_exh + 1;
                    if (dec !== ref_dec(opcode) || pc_sel !== ref_pc_sel(opcode, zero_flag, stall) ||
                        flush !== pc_sel) begin
                        errors = errors + 1;
                        $display("  FAIL opcode=%h Z=%b stall=%b dec=%b ref=%b pc_sel=%b",
                                 opcode, zero_flag, stall, dec, ref_dec(opcode), pc_sel);
                    end
                end
        $display("  %0d exhaustive cases compared", n_exh);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_control_unit (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_exh);
        else
            $display("FAILED: tb_control_unit (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_exh);
        $finish(0);
    end

endmodule

`default_nettype wire
