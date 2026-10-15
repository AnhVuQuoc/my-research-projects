// =============================================================================
// File        : instruction_register.v
// Module      : instruction_register
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : IF/ID pipeline register (the Instruction Register, IR)
// Job         : Captures the fetched instruction, its address and a valid
//               bit. Priority: (1) rst or flush -> empty slot (NOP, valid 0),
//               (2) ir_load = 1 -> capture, (3) ir_load = 0 -> hold (stall).
// Ports       :
//   clk                    in   clock, rising edge
//   rst                    in   synchronous reset
//   ir_load                in   1 = capture, 0 = hold (driven by ~stall)
//   flush                  in   1 = throw away the fetched instruction
//   instruction_in  [11:0] in   word from instruction_memory
//   pc_in           [3:0]  in   its address
//   instruction_out [11:0] out  instruction now in ID
//   pc_out          [3:0]  out  its address
//   valid_out              out  1 = real instruction, 0 = bubble
// Connections : instance IR in cpu_top; tested by tb_instruction_register
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module instruction_register (
    input  wire        clk,
    input  wire        rst,
    input  wire        ir_load,
    input  wire        flush,
    input  wire [11:0] instruction_in,
    input  wire [3:0]  pc_in,
    output reg  [11:0] instruction_out,
    output reg  [3:0]  pc_out,
    output reg         valid_out
);
`include "cpu_defs.vh"

    always @(posedge clk) begin
        if (rst || flush) begin
            instruction_out <= `NOP_INSTR;  // empty slot
            pc_out          <= 4'd0;
            valid_out       <= 1'b0;
        end
        else if (ir_load) begin
            instruction_out <= instruction_in;
            pc_out          <= pc_in;
            valid_out       <= 1'b1;
        end
        // ir_load = 0: hold everything (stall)
    end

endmodule

`default_nettype wire
