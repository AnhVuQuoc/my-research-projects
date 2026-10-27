// =============================================================================
// File        : tb_control_unit.v
// Module      : tb_control_unit   (self-checking testbench for control_unit)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 16 decoder rows (fields rd = R1, rs1 = R2, rs2 = R3) + 8 branch rows
// Part 2      : exhaustive: 16 opcodes x Z x stall x every rd, rs1, rs2 = 32768 cases vs the ISA table
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_control_unit;
    reg [3:0] opcode = 0; reg [2:0] rd = 0, rs1 = 0, rs2 = 0; reg zero_flag = 0, stall = 0;
    wire [3:0] alu_ctrl; wire alu_src_sel, wb_sel, reg_we, mem_we, zero_we, carry_we, uses_a, uses_b;
    wire [2:0] ra, rb; wire is_jmp, is_bz, is_bnz, is_hlt, pc_sel, flush;
    integer errors = 0, n_dir = 0, n_p2 = 0, o, z, s, f;
    control_unit DUT (.opcode(opcode), .rd(rd), .rs1(rs1), .rs2(rs2), .zero_flag(zero_flag), .stall(stall),
        .alu_ctrl(alu_ctrl), .alu_src_sel(alu_src_sel), .wb_sel(wb_sel), .reg_we(reg_we), .mem_we(mem_we),
        .zero_we(zero_we), .carry_we(carry_we), .uses_a(uses_a), .uses_b(uses_b), .ra(ra), .rb(rb),
        .is_jmp(is_jmp), .is_bz(is_bz), .is_bnz(is_bnz), .is_hlt(is_hlt), .pc_sel(pc_sel), .flush(flush));
    // alu[3:0] src wb rwe mwe zwe cwe ua ub jmp bz bnz hlt
    wire [15:0] dec = {alu_ctrl, alu_src_sel, wb_sel, reg_we, mem_we, zero_we, carry_we, uses_a, uses_b,
                       is_jmp, is_bz, is_bnz, is_hlt};
    function [15:0] ref_dec; input [3:0] op;
        case (op) //           alu    src wb  rwe mwe zwe cwe ua  ub  jmp bz  bnz hlt
            4'h1: ref_dec = {4'd0, 12'b0_0_1_0_1_1_1_1_0_0_0_0};
            4'h2: ref_dec = {4'd1, 12'b0_0_1_0_1_1_1_1_0_0_0_0};
            4'h3: ref_dec = {4'd2, 12'b0_0_1_0_1_0_1_1_0_0_0_0};
            4'h4: ref_dec = {4'd3, 12'b0_0_1_0_1_0_1_1_0_0_0_0};
            4'h5: ref_dec = {4'd4, 12'b0_0_1_0_1_0_1_1_0_0_0_0};
            4'h6: ref_dec = {4'd5, 12'b0_0_1_0_1_1_1_0_0_0_0_0};
            4'h7: ref_dec = {4'd6, 12'b0_0_1_0_1_1_1_0_0_0_0_0};
            4'h8: ref_dec = {4'd7, 12'b1_0_1_0_0_0_0_0_0_0_0_0};
            4'h9: ref_dec = {4'd0, 12'b1_0_1_0_1_1_1_0_0_0_0_0};
            4'hA: ref_dec = {4'd8, 12'b0_1_1_0_0_0_1_0_0_0_0_0};
            4'hB: ref_dec = {4'd8, 12'b0_0_0_1_0_0_1_1_0_0_0_0};
            4'hC: ref_dec = {4'd0, 12'b0_0_0_0_0_0_0_0_1_0_0_0};
            4'hD: ref_dec = {4'd0, 12'b0_0_0_0_0_0_0_0_0_1_0_0};
            4'hE: ref_dec = {4'd0, 12'b0_0_0_0_0_0_0_0_0_0_1_0};
            4'hF: ref_dec = {4'd0, 12'b0_0_0_0_0_0_0_0_0_0_0_1};
            default: ref_dec = 16'd0;
        endcase
    endfunction
    function [2:0] ref_ra; input [3:0] op; ref_ra = (op == 4'h9) ? rd : rs1; endfunction
    function [2:0] ref_rb; input [3:0] op; ref_rb = (op == 4'hB) ? rd : rs2; endfunction
    function ref_pc; input [3:0] op; input zf, st;
        ref_pc = ((op == 4'hC) || (op == 4'hD && zf) || (op == 4'hE && !zf)) && !st;
    endfunction
    function [8*5:1] mn; input [3:0] op;
        case (op) 4'h0: mn="NOP  "; 4'h1: mn="ADD  "; 4'h2: mn="SUB  "; 4'h3: mn="AND  "; 4'h4: mn="OR   ";
            4'h5: mn="XOR  "; 4'h6: mn="SHL  "; 4'h7: mn="SHR  "; 4'h8: mn="LDI  "; 4'h9: mn="ADDI ";
            4'hA: mn="LD   "; 4'hB: mn="ST   "; 4'hC: mn="JMP  "; 4'hD: mn="BZ   "; 4'hE: mn="BNZ  "; default: mn="HLT  "; endcase
    endfunction
    task drow; input [3:0] op;
        reg ok; begin
            opcode = op; rd = 3'd1; rs1 = 3'd2; rs2 = 3'd3; zero_flag = 0; stall = 0; #5; n_dir = n_dir + 1;
            ok = (dec === ref_dec(op)) && (ra === ref_ra(op)) && (rb === ref_rb(op)) && (pc_sel === ref_pc(op, 1'b0, 1'b0));
            if (!ok) errors = errors + 1;
            $display("  %t | %h %s | %2d  %b  %b  %b   %b   %b   %b   %b  %b  | R%0d R%0d | %b%b%b%b |   %b    | %s", $time - 5, op, mn(op),
                     alu_ctrl, alu_src_sel, wb_sel, reg_we, mem_we, zero_we, carry_we, uses_a, uses_b, ra, rb,
                     is_jmp, is_bz, is_bnz, is_hlt, pc_sel, ok ? "PASS" : "FAIL"); #5;
        end endtask
    task brow; input [3:0] op; input zf, st, e; input [8*34:1] note;
        reg ok; begin
            opcode = op; zero_flag = zf; stall = st; #5; n_dir = n_dir + 1; ok = (pc_sel === e) && (flush === e);
            if (!ok) errors = errors + 1;
            $display("  %t | %s | %b |   %b   |   %b    %b  |  %b  | %s | %0s", $time - 5, mn(op), zf, st, pc_sel, flush, e, ok ? "PASS" : "FAIL", note); #5;
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_control_unit.vcd"); $dumpvars(0, tb_control_unit); end
        $display("============================================================================");
        $display(" tb_control_unit : self-checking testbench for module control_unit");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        #10;
        $display("\nPART 1a: decoder truth table (rd = R1, rs1 = R2, rs2 = R3, Z = 0, stall = 0)");
        $display("  time | opcode  | alu src wb rwe mwe zwe cwe ua ub | ra rb | j/bz/bnz/hlt | pc_sel | chk");
        for (o = 0; o < 16; o = o + 1) drow(o);
        $display("\nPART 1b: branch decision in ID");
        $display("  time | instr | Z | stall | pc_sel flush | exp | chk  | note");
        brow(4'hC, 0, 0, 1, "JMP is always taken");
        brow(4'hC, 0, 1, 0, "JMP not taken while stalled");
        brow(4'hD, 1, 0, 1, "BZ, Z = 1: taken");
        brow(4'hD, 0, 0, 0, "BZ, Z = 0: not taken");
        brow(4'hD, 1, 1, 0, "BZ waits (flag stall)");
        brow(4'hE, 0, 0, 1, "BNZ, Z = 0: taken");
        brow(4'hE, 1, 0, 0, "BNZ, Z = 1: not taken");
        brow(4'hF, 1, 0, 0, "HLT is not a branch");
        $display("\nPART 2: exhaustive check (32768 cases)");
        for (o = 0; o < 16; o = o + 1) for (z = 0; z < 2; z = z + 1) for (s = 0; s < 2; s = s + 1)
            for (f = 0; f < 512; f = f + 1) begin
                opcode = o; zero_flag = z; stall = s; {rd, rs1, rs2} = f; #1; n_p2 = n_p2 + 1;
                if (dec !== ref_dec(opcode) || ra !== ref_ra(opcode) || rb !== ref_rb(opcode) ||
                    pc_sel !== ref_pc(opcode, zero_flag, stall) || flush !== pc_sel) errors = errors + 1;
            end
        $display("  %0d exhaustive cases compared", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_control_unit (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_control_unit (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
