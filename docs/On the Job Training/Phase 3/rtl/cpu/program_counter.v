// =============================================================================
// File        : program_counter.v
// Module      : program_counter
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : IF
// Job         : 8-bit fetch address (256 instructions). Holds when pc_en = 0
//               (stall or halt).
// Ports       :
//   clk, rst       in   clock; synchronous reset, PC <- 0
//   pc_en          in   1 = load pc_next, 0 = hold
//   pc_next [7:0]  in   from PC_MUX: PC + 1 or branch target
//   pc_out  [7:0]  out  current fetch address
// Connections : instance PC in cpu_top; tested by tb_program_counter
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module program_counter (
    input  wire       clk,
    input  wire       rst,
    input  wire       pc_en,
    input  wire [7:0] pc_next,
    output reg  [7:0] pc_out
);

    always @(posedge clk) begin
        if (rst)
            pc_out <= 8'd0;
        else if (pc_en)
            pc_out <= pc_next;
        // pc_en = 0: hold (stall or halt)
    end

endmodule

`default_nettype wire
