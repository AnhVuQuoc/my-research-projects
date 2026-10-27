// =============================================================================
// File        : control_unit.v
// Module      : control_unit
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : ID
// Job         : Hardwired control.
//               Part 1 decodes the opcode (safe defaults, then a case).
//               Part 2 chooses WHICH registers the instruction reads: port A is
//               rs1, except ADDI (rd); port B is rs2, except ST (rd = store data).
//               Part 3 decides branches in ID: JMP always, BZ if Z = 1,
//               BNZ if Z = 0, never while stalled; a taken branch flushes IF/ID.
// Ports       :
//   opcode [3:0], rd, rs1, rs2 [2:0]  in   fields of the instruction in ID
//   zero_flag, stall                  in   stored Zero flag; stall from hazard_unit
//   alu_ctrl [3:0], alu_src_sel, wb_sel, reg_we, mem_we, zero_we, carry_we
//                                     out  datapath controls (used in EX, MEM, WB)
//   ra, rb [2:0]                      out  register-file read addresses
//   uses_a, uses_b                    out  the instruction really reads port A / B
//   is_jmp, is_bz, is_bnz, is_hlt     out  instruction type
//   pc_sel, flush                     out  taken branch: PC <- addr8, empty IF/ID
// Connections : instance CU in cpu_top; tested by tb_control_unit
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module control_unit (
    input  wire [3:0] opcode,
    input  wire [2:0] rd,
    input  wire [2:0] rs1,
    input  wire [2:0] rs2,
    input  wire       zero_flag,
    input  wire       stall,
    output reg  [3:0] alu_ctrl,
    output reg        alu_src_sel,
    output reg        wb_sel,
    output reg        reg_we,
    output reg        mem_we,
    output reg        zero_we,
    output reg        carry_we,
    output reg        uses_a,
    output reg        uses_b,
    output wire [2:0] ra,
    output wire [2:0] rb,
    output reg        is_jmp,
    output reg        is_bz,
    output reg        is_bnz,
    output reg        is_hlt,
    output wire       pc_sel,
    output wire       flush
);
`include "cpu_defs.vh"

    reg ra_is_rd;      // 1: port A reads rd (ADDI)
    reg rb_is_rd;      // 1: port B reads rd (ST data)

    // ---- Part 1: decoder ----------------------------------------------------
    always @(*) begin
        // Step 1: safe defaults = NOP
        alu_ctrl = `ALU_ADD; alu_src_sel = 1'b0; wb_sel = 1'b0; reg_we = 1'b0;
        mem_we = 1'b0; zero_we = 1'b0; carry_we = 1'b0; uses_a = 1'b0; uses_b = 1'b0;
        ra_is_rd = 1'b0; rb_is_rd = 1'b0;
        is_jmp = 1'b0; is_bz = 1'b0; is_bnz = 1'b0; is_hlt = 1'b0;
        // Step 2: turn on only what the opcode needs
        case (opcode)
            `OP_ADD : begin alu_ctrl = `ALU_ADD; reg_we = 1'b1; zero_we = 1'b1; carry_we = 1'b1;
                            uses_a = 1'b1; uses_b = 1'b1; end
            `OP_SUB : begin alu_ctrl = `ALU_SUB; reg_we = 1'b1; zero_we = 1'b1; carry_we = 1'b1;
                            uses_a = 1'b1; uses_b = 1'b1; end
            `OP_AND : begin alu_ctrl = `ALU_AND; reg_we = 1'b1; zero_we = 1'b1;
                            uses_a = 1'b1; uses_b = 1'b1; end
            `OP_OR  : begin alu_ctrl = `ALU_OR;  reg_we = 1'b1; zero_we = 1'b1;
                            uses_a = 1'b1; uses_b = 1'b1; end
            `OP_XOR : begin alu_ctrl = `ALU_XOR; reg_we = 1'b1; zero_we = 1'b1;
                            uses_a = 1'b1; uses_b = 1'b1; end
            `OP_SHL : begin alu_ctrl = `ALU_SHL; reg_we = 1'b1; zero_we = 1'b1; carry_we = 1'b1;
                            uses_a = 1'b1; end
            `OP_SHR : begin alu_ctrl = `ALU_SHR; reg_we = 1'b1; zero_we = 1'b1; carry_we = 1'b1;
                            uses_a = 1'b1; end
            `OP_LDI : begin alu_ctrl = `ALU_PASSB; alu_src_sel = 1'b1; reg_we = 1'b1; end
            `OP_ADDI: begin alu_ctrl = `ALU_ADD; alu_src_sel = 1'b1; reg_we = 1'b1;
                            zero_we = 1'b1; carry_we = 1'b1; uses_a = 1'b1; ra_is_rd = 1'b1; end
            `OP_LD  : begin alu_ctrl = `ALU_PASSA; wb_sel = 1'b1; reg_we = 1'b1; uses_a = 1'b1; end
            `OP_ST  : begin alu_ctrl = `ALU_PASSA; mem_we = 1'b1; uses_a = 1'b1;
                            uses_b = 1'b1; rb_is_rd = 1'b1; end
            `OP_JMP : is_jmp = 1'b1;
            `OP_BZ  : is_bz  = 1'b1;
            `OP_BNZ : is_bnz = 1'b1;
            `OP_HLT : is_hlt = 1'b1;
            default : ;                                     // OP_NOP: keep the defaults
        endcase
    end

    // ---- Part 2: which registers are read ------------------------------------
    assign ra = ra_is_rd ? rd : rs1;
    assign rb = rb_is_rd ? rd : rs2;

    // ---- Part 3: branch decision in ID --------------------------------------
    assign pc_sel = (is_jmp | (is_bz & zero_flag) | (is_bnz & ~zero_flag)) & ~stall;
    assign flush  = pc_sel;

endmodule

`default_nettype wire
