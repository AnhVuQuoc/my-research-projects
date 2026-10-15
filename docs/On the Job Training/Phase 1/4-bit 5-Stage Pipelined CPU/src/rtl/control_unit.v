// =============================================================================
// File        : control_unit.v
// Module      : control_unit
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : ID
// Job         : Hardwired control. Part 1 decodes the opcode into datapath
//               controls (safe defaults, reserved opcodes = NOP). Part 2
//               decides branches IN THE ID STAGE: a taken JMP or JZ loads the
//               target into the PC and flushes only the IF/ID register, so a
//               taken branch costs 1 cycle (the 3-stage design paid 2).
//               It also reports which registers the instruction READS
//               (uses_rd, uses_rs) so the hazard unit stalls only when needed.
// Ports       :
//   opcode   [3:0] in   instruction bits [11:8] of the instruction in ID
//   zero_flag      in   stored Zero flag (flag_register)
//   stall          in   1 = the instruction in ID must wait (hazard_unit)
//   alu_ctrl [2:0] out  ALU operation                     (used in EX)
//   alu_src_sel    out  operand MUX: 0 = Rs, 1 = imm      (used in EX)
//   wb_sel         out  WB MUX: 0 = ALU, 1 = memory       (used in WB)
//   reg_we         out  write Rd                          (used in WB)
//   mem_we         out  write data memory                 (used in MEM)
//   zero_we        out  update Zero flag                  (used in EX)
//   carry_we       out  update Carry flag                 (used in EX)
//   uses_rd        out  instruction reads Rd              (hazard_unit)
//   uses_rs        out  instruction reads Rs              (hazard_unit)
//   is_jmp         out  instruction is JMP
//   is_jz          out  instruction is JZ                 (hazard_unit)
//   pc_sel         out  PC MUX: 0 = PC + 1, 1 = branch target
//   flush          out  1 = empty the IF/ID register
// Connections : instance CU in cpu_top; tested by tb_control_unit
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module control_unit (
    input  wire [3:0] opcode,
    input  wire       zero_flag,
    input  wire       stall,
    output reg  [2:0] alu_ctrl,
    output reg        alu_src_sel,
    output reg        wb_sel,
    output reg        reg_we,
    output reg        mem_we,
    output reg        zero_we,
    output reg        carry_we,
    output reg        uses_rd,
    output reg        uses_rs,
    output reg        is_jmp,
    output reg        is_jz,
    output wire       pc_sel,
    output wire       flush
);
`include "cpu_defs.vh"

    // ---- Part 1: decoder ----------------------------------------------------
    always @(*) begin
        // Step 1: safe defaults = "do nothing" (NOP)
        alu_ctrl    = `ALU_ADD;
        alu_src_sel = 1'b0;
        wb_sel      = 1'b0;
        reg_we      = 1'b0;
        mem_we      = 1'b0;
        zero_we     = 1'b0;
        carry_we    = 1'b0;
        uses_rd     = 1'b0;
        uses_rs     = 1'b0;
        is_jmp      = 1'b0;
        is_jz       = 1'b0;
        // Step 2: turn on only what this opcode needs
        case (opcode)
            `OP_ADD: begin alu_ctrl = `ALU_ADD; reg_we = 1'b1; zero_we = 1'b1;
                           carry_we = 1'b1; uses_rd = 1'b1; uses_rs = 1'b1; end
            `OP_SUB: begin alu_ctrl = `ALU_SUB; reg_we = 1'b1; zero_we = 1'b1;
                           carry_we = 1'b1; uses_rd = 1'b1; uses_rs = 1'b1; end
            `OP_AND: begin alu_ctrl = `ALU_AND; reg_we = 1'b1; zero_we = 1'b1;
                           uses_rd = 1'b1; uses_rs = 1'b1; end
            `OP_OR : begin alu_ctrl = `ALU_OR;  reg_we = 1'b1; zero_we = 1'b1;
                           uses_rd = 1'b1; uses_rs = 1'b1; end
            `OP_XOR: begin alu_ctrl = `ALU_XOR; reg_we = 1'b1; zero_we = 1'b1;
                           uses_rd = 1'b1; uses_rs = 1'b1; end
            `OP_NOT: begin alu_ctrl = `ALU_NOT; reg_we = 1'b1; zero_we = 1'b1;
                           uses_rd = 1'b1; end
            `OP_LDI: begin alu_ctrl = `ALU_PASS; alu_src_sel = 1'b1; reg_we = 1'b1; end
            `OP_MOV: begin alu_ctrl = `ALU_PASS; reg_we = 1'b1; uses_rs = 1'b1; end
            `OP_LOAD: begin alu_ctrl = `ALU_PASS; alu_src_sel = 1'b1; wb_sel = 1'b1;
                            reg_we = 1'b1; end
            `OP_STORE: begin alu_ctrl = `ALU_PASS; alu_src_sel = 1'b1; mem_we = 1'b1;
                             uses_rd = 1'b1; end
            `OP_JMP: is_jmp = 1'b1;
            `OP_JZ : is_jz  = 1'b1;
            default: ;                  // reserved 1100..1111: keep the NOP defaults
        endcase
    end

    // ---- Part 2: branch decision in ID -------------------------------------
    // A branch is only taken when the instruction is NOT stalled: a stalled
    // JZ is still waiting for its Zero flag and will decide next cycle.
    assign pc_sel = (is_jmp | (is_jz & zero_flag)) & ~stall;
    assign flush  = pc_sel;             // taken branch -> drop the instruction in IF

endmodule

`default_nettype wire
