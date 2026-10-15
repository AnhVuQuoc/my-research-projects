// =============================================================================
// File        : program_counter.v
// Module      : program_counter
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : IF
// Job         : Holds the address of the instruction being FETCHED.
//               NEW in the 5-stage design: pc_en is a real control. The
//               hazard unit drives pc_en = 0 during a stall, so the PC keeps
//               its value and the same instruction is fetched again.
// Ports       :
//   clk          in   clock, rising edge
//   rst          in   synchronous reset, PC <- 0
//   pc_en        in   1 = load pc_next, 0 = hold (stall)
//   pc_next[3:0] in   next address from PC_MUX (PC + 1 or branch target)
//   pc_out [3:0] out  current fetch address
// Connections : instance PC in cpu_top; tested by tb_program_counter
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module program_counter (
    input  wire       clk,
    input  wire       rst,
    input  wire       pc_en,
    input  wire [3:0] pc_next,
    output reg  [3:0] pc_out
);

    always @(posedge clk) begin
        if (rst)
            pc_out <= 4'd0;             // start at address 0 after reset
        else if (pc_en)
            pc_out <= pc_next;          // normal step or branch target
        // pc_en = 0: hold the old value (stall)
    end

endmodule

`default_nettype wire
