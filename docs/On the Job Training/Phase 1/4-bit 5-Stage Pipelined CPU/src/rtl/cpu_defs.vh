// =============================================================================
// File        : cpu_defs.vh
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Job         : One shared place for every encoding used by more than one
//               file: opcodes, ALU control codes, forwarding select codes and
//               the NOP word. Each RTL file includes it, so a code can never
//               be different in two places.
// Usage       : `include "cpu_defs.vh"  (include path = rtl/)
// =============================================================================
`ifndef CPU_DEFS_VH
`define CPU_DEFS_VH

// ---- Opcodes, instruction bits [11:8] (project plan, Section 4) -------------
`define OP_ADD     4'b0000   // Rd <- Rd + Rs        (Zero, Carry)
`define OP_SUB     4'b0001   // Rd <- Rd - Rs        (Zero, Carry = no borrow)
`define OP_AND     4'b0010   // Rd <- Rd & Rs        (Zero)
`define OP_OR      4'b0011   // Rd <- Rd | Rs        (Zero)
`define OP_XOR     4'b0100   // Rd <- Rd ^ Rs        (Zero)
`define OP_NOT     4'b0101   // Rd <- ~Rd            (Zero)
`define OP_LDI     4'b0110   // Rd <- imm
`define OP_MOV     4'b0111   // Rd <- Rs
`define OP_LOAD    4'b1000   // Rd <- dmem[imm]
`define OP_STORE   4'b1001   // dmem[imm] <- Rd
`define OP_JMP     4'b1010   // PC <- imm
`define OP_JZ      4'b1011   // if (Zero) PC <- imm
// 4'b1100 .. 4'b1111 are reserved and behave as NOP

// ---- The NOP word used for empty pipeline slots (reserved opcode C) ---------
`define NOP_INSTR  12'hC00

// ---- ALU control codes (alu_ctrl) -------------------------------------------
`define ALU_ADD    3'd0
`define ALU_SUB    3'd1
`define ALU_AND    3'd2
`define ALU_OR     3'd3
`define ALU_XOR    3'd4
`define ALU_NOT    3'd5
`define ALU_PASS   3'd6      // result = b (LDI, MOV, LOAD and STORE address)

// ---- Forwarding select codes (fwd_a_sel, fwd_b_sel) -------------------------
`define FWD_ID     2'b00     // use the value read from the register file in ID
`define FWD_WB     2'b01     // use wb_data (instruction now in WB)
`define FWD_MEM    2'b10     // use the ALU result of the instruction in MEM

`endif
