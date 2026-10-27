// =============================================================================
// File        : cpu_defs.vh
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Job         : One shared place for every encoding used by more than one file.
//               Instruction (16 bits): [15:12] opcode | [11:9] rd | [8:6] rs1 |
//               [5:3] rs2 | [7:0] imm8/addr8 (imm8 overlaps rs1 and rs2)
// =============================================================================
`ifndef CPU_DEFS_VH
`define CPU_DEFS_VH

// ---- Opcodes, instruction bits [15:12] ---------------------------------------
`define OP_NOP   4'h0   // do nothing (also the bubble word)
`define OP_ADD   4'h1   // rd = rs1 + rs2            Z, C (carry)
`define OP_SUB   4'h2   // rd = rs1 - rs2            Z, C (borrow)
`define OP_AND   4'h3   // rd = rs1 & rs2            Z
`define OP_OR    4'h4   // rd = rs1 | rs2            Z
`define OP_XOR   4'h5   // rd = rs1 ^ rs2            Z
`define OP_SHL   4'h6   // rd = rs1 << 1             Z, C = old bit 7
`define OP_SHR   4'h7   // rd = rs1 >> 1             Z, C = old bit 0
`define OP_LDI   4'h8   // rd = imm8
`define OP_ADDI  4'h9   // rd = rd + imm8            Z, C (carry)
`define OP_LD    4'hA   // rd = dmem[rs1]
`define OP_ST    4'hB   // dmem[rs1] = rd
`define OP_JMP   4'hC   // PC = addr8
`define OP_BZ    4'hD   // if (Z == 1) PC = addr8
`define OP_BNZ   4'hE   // if (Z == 0) PC = addr8
`define OP_HLT   4'hF   // stop fetching; the pipeline drains

// ---- Empty pipeline slot ------------------------------------------------------
`define NOP_INSTR 16'h0000

// ---- ALU control codes (4 bits: 9 operations) -----------------------------------
`define ALU_ADD    4'd0
`define ALU_SUB    4'd1
`define ALU_AND    4'd2
`define ALU_OR     4'd3
`define ALU_XOR    4'd4
`define ALU_SHL    4'd5
`define ALU_SHR    4'd6
`define ALU_PASSB  4'd7   // result = b (LDI)
`define ALU_PASSA  4'd8   // result = a (address of LD and ST)

// ---- Forwarding select codes -------------------------------------------------------
`define FWD_ID   2'b00    // value read from the register file in ID
`define FWD_WB   2'b01    // wb_data (instruction now in WB)
`define FWD_MEM  2'b10    // ALU result of the instruction now in MEM

`endif
