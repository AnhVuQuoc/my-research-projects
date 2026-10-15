// =============================================================================
// File        : forwarding_unit.v
// Module      : forwarding_unit
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : EX
// Job         : Chooses where each ALU operand comes from, so an instruction
//               can use a result that has not been written to the register
//               file yet. Priority: the NEWEST value wins.
//                 1st  MEM stage writes this register -> `FWD_MEM (EX/MEM ALU result)
//                 2nd  WB  stage writes this register -> `FWD_WB  (wb_data)
//                 else value read from the register file in ID -> `FWD_ID
//               The MEM-stage value is never a LOAD result: the hazard unit
//               makes sure a LOAD is in WB (not MEM) when its user is in EX.
// Ports       :
//   ex_rd     [1:0] in   Rd of the instruction in EX (operand A)
//   ex_rs     [1:0] in   Rs of the instruction in EX (operand B)
//   mem_rd    [1:0] in   Rd of the instruction in MEM
//   mem_reg_we      in   instruction in MEM writes a register
//   wb_rd     [1:0] in   Rd of the instruction in WB
//   wb_reg_we       in   instruction in WB writes a register
//   fwd_a_sel [1:0] out  select for FWD_A_MUX
//   fwd_b_sel [1:0] out  select for FWD_B_MUX
// Connections : instance FU in cpu_top; tested by tb_forwarding_unit
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module forwarding_unit (
    input  wire [1:0] ex_rd,
    input  wire [1:0] ex_rs,
    input  wire [1:0] mem_rd,
    input  wire       mem_reg_we,
    input  wire [1:0] wb_rd,
    input  wire       wb_reg_we,
    output reg  [1:0] fwd_a_sel,
    output reg  [1:0] fwd_b_sel
);
`include "cpu_defs.vh"

    // ---- operand A (Rd) -----------------------------------------------------
    always @(*) begin
        if (mem_reg_we && (mem_rd == ex_rd))
            fwd_a_sel = `FWD_MEM;       // newest value: instruction in MEM
        else if (wb_reg_we && (wb_rd == ex_rd))
            fwd_a_sel = `FWD_WB;        // older value: instruction in WB
        else
            fwd_a_sel = `FWD_ID;        // no hazard: register file value
    end

    // ---- operand B (Rs) -----------------------------------------------------
    always @(*) begin
        if (mem_reg_we && (mem_rd == ex_rs))
            fwd_b_sel = `FWD_MEM;
        else if (wb_reg_we && (wb_rd == ex_rs))
            fwd_b_sel = `FWD_WB;
        else
            fwd_b_sel = `FWD_ID;
    end

endmodule

`default_nettype wire
