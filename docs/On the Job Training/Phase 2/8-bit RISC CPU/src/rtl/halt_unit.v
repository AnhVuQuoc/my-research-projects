// =============================================================================
// File        : halt_unit.v
// Module      : halt_unit
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : ID (front-end control)
// Job         : NEW. Implements HLT and owns the 2 front-end controls:
//               halt         = halted OR (HLT in ID and not stalled)
//               pc_en        = NOT stall AND NOT halt   (PC holds)
//               if_id_flush  = branch_flush OR halt     (no new instruction enters ID)
//               halted is set at the edge after HLT leaves ID and stays 1 until
//               reset. HLT itself and every older instruction continue and
//               retire: the pipeline DRAINS. A wrong-path HLT can never halt the
//               CPU, because wrong-path words are flushed before they reach ID.
// Ports       :
//   clk, rst           in   clock, synchronous reset (clears halted)
//   id_is_hlt          in   HLT is in ID
//   stall              in   from hazard_unit
//   branch_flush       in   taken branch (control_unit flush)
//   halted             out  1 = CPU halted (debug output)
//   halt, pc_en, if_id_flush   out  see Job
// Connections : instance HALT in cpu_top; tested by tb_halt_unit
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module halt_unit (
    input  wire clk,
    input  wire rst,
    input  wire id_is_hlt,
    input  wire stall,
    input  wire branch_flush,
    output reg  halted,
    output wire halt,
    output wire pc_en,
    output wire if_id_flush
);

    wire hlt_now = id_is_hlt & ~stall;

    always @(posedge clk) begin
        if (rst)          halted <= 1'b0;
        else if (hlt_now) halted <= 1'b1;   // stays 1 until reset
    end

    assign halt        = halted | hlt_now;
    assign pc_en       = ~stall & ~halt;
    assign if_id_flush = branch_flush | halt;

endmodule

`default_nettype wire
