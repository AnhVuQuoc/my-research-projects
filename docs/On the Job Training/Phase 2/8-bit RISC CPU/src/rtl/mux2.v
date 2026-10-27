// =============================================================================
// File        : mux2.v
// Module      : mux2
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Job         : 2-input, 8-bit multiplexer: y = sel ? d1 : d0.
//               Used 3 times: PC_MUX (IF), OPERAND_MUX (EX), WB_MUX (WB).
// Ports       : d0 [7:0], d1 [7:0], sel in; y [7:0] out
// Connections : instances PC_MUX, OPERAND_MUX, WB_MUX in cpu_top; tb_mux2
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module mux2 (
    input  wire [7:0] d0,
    input  wire [7:0] d1,
    input  wire       sel,
    output wire [7:0] y
);

    assign y = sel ? d1 : d0;

endmodule

`default_nettype wire
