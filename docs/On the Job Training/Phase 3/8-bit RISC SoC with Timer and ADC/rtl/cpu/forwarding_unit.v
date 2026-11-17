// =============================================================================
// File        : forwarding_unit.v
// Module      : forwarding_unit
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : EX
// Job         : For each ALU operand, choose the newest copy of the register it
//               READS (ex_ra, ex_rb: chosen in ID by control_unit, so rs1 or rd,
//               rs2 or rd). Priority: MEM (newer) > WB (older) > value read in ID.
// Ports       :
//   ex_ra, ex_rb [2:0]     in   registers the EX instruction reads
//   mem_rd [2:0], mem_reg_we  in   instruction in MEM
//   wb_rd [2:0],  wb_reg_we   in   instruction in WB
//   fwd_a_sel, fwd_b_sel [1:0] out  selects of FWD_A_MUX, FWD_B_MUX
// Connections : instance FU in cpu_top; tested by tb_forwarding_unit
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module forwarding_unit (
    input  wire [2:0] ex_ra,
    input  wire [2:0] ex_rb,
    input  wire [2:0] mem_rd,
    input  wire       mem_reg_we,
    input  wire [2:0] wb_rd,
    input  wire       wb_reg_we,
    output reg  [1:0] fwd_a_sel,
    output reg  [1:0] fwd_b_sel
);
`include "cpu_defs.vh"

    // ---- operand A ----------------------------------------------------------
    always @(*) begin
        if (mem_reg_we && (mem_rd == ex_ra))      fwd_a_sel = `FWD_MEM;
        else if (wb_reg_we && (wb_rd == ex_ra))   fwd_a_sel = `FWD_WB;
        else                                      fwd_a_sel = `FWD_ID;
    end

    // ---- operand B ----------------------------------------------------------
    always @(*) begin
        if (mem_reg_we && (mem_rd == ex_rb))      fwd_b_sel = `FWD_MEM;
        else if (wb_reg_we && (wb_rd == ex_rb))   fwd_b_sel = `FWD_WB;
        else                                      fwd_b_sel = `FWD_ID;
    end

endmodule

`default_nettype wire
