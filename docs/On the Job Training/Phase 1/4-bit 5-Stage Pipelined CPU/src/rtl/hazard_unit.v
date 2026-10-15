// =============================================================================
// File        : hazard_unit.v
// Module      : hazard_unit
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : ID (looks at ID and EX)
// Job         : Finds the two cases forwarding cannot fix and stalls for
//               1 cycle:
//               (1) load-use: the instruction in EX is LOAD and the
//                   instruction in ID reads the register being loaded. The
//                   loaded value only exists at the END of MEM, too late for
//                   EX in the next cycle.
//               (2) flag: the instruction in ID is JZ and the instruction in
//                   EX writes the Zero flag. The new Zero flag only exists at
//                   the end of EX, too late for the branch decision in ID.
//               A stall freezes PC and IF/ID and puts a bubble into ID/EX.
// Ports       :
//   id_rd    [1:0] in   Rd of the instruction in ID
//   id_rs    [1:0] in   Rs of the instruction in ID
//   id_uses_rd     in   instruction in ID reads Rd
//   id_uses_rs     in   instruction in ID reads Rs
//   id_is_jz       in   instruction in ID is JZ
//   ex_rd    [1:0] in   Rd of the instruction in EX
//   ex_reg_we      in   instruction in EX writes a register
//   ex_wb_sel      in   instruction in EX takes its result from memory (LOAD)
//   ex_zero_we     in   instruction in EX writes the Zero flag
//   load_use_stall out  reason (1) is active
//   flag_stall     out  reason (2) is active
//   stall          out  load_use_stall OR flag_stall
//   pc_en          out  to program_counter  (= ~stall)
//   ir_load        out  to IF/ID register    (= ~stall)
//   id_ex_bubble   out  to ID/EX register    (= stall)
// Connections : instance HU in cpu_top; tested by tb_hazard_unit
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module hazard_unit (
    input  wire [1:0] id_rd,
    input  wire [1:0] id_rs,
    input  wire       id_uses_rd,
    input  wire       id_uses_rs,
    input  wire       id_is_jz,
    input  wire [1:0] ex_rd,
    input  wire       ex_reg_we,
    input  wire       ex_wb_sel,
    input  wire       ex_zero_we,
    output wire       load_use_stall,
    output wire       flag_stall,
    output wire       stall,
    output wire       pc_en,
    output wire       ir_load,
    output wire       id_ex_bubble
);

    wire ex_is_load = ex_reg_we & ex_wb_sel;            // only LOAD has both = 1
    wire rd_match   = id_uses_rd & (id_rd == ex_rd);     // ID reads the loaded Rd
    wire rs_match   = id_uses_rs & (id_rs == ex_rd);     // ID reads it as Rs

    assign load_use_stall = ex_is_load & (rd_match | rs_match);
    assign flag_stall     = id_is_jz & ex_zero_we;
    assign stall          = load_use_stall | flag_stall;

    assign pc_en        = ~stall;       // freeze the PC
    assign ir_load      = ~stall;       // freeze IF/ID
    assign id_ex_bubble =  stall;       // send a NOP into EX

endmodule

`default_nettype wire
