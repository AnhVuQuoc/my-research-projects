// =============================================================================
// File        : instruction_register.v
// Module      : instruction_register
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : IF/ID pipeline register (the IR)
// Job         : Captures the fetched word, its address and a valid bit.
//               Priority: (1) rst or flush -> empty slot (0000 = NOP, valid 0),
//               (2) ir_load = 1 -> capture, (3) ir_load = 0 -> hold (stall).
//               flush comes from halt_unit: taken branch OR halt.
// Ports       :
//   clk, rst                in   clock, synchronous reset
//   ir_load                 in   1 = capture, 0 = hold (= ~stall)
//   flush                   in   1 = throw the fetched word away
//   instruction_in  [15:0]  in   word from IMEM
//   pc_in           [7:0]   in   its address
//   instruction_out [15:0]  out  instruction in ID
//   pc_out          [7:0]   out  its address
//   valid_out               out  1 = real instruction, 0 = bubble
// Connections : instance IR in cpu_top; tested by tb_instruction_register
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module instruction_register (
    input  wire        clk,
    input  wire        rst,
    input  wire        ir_load,
    input  wire        flush,
    input  wire [15:0] instruction_in,
    input  wire [7:0]  pc_in,
    output reg  [15:0] instruction_out,
    output reg  [7:0]  pc_out,
    output reg         valid_out
);
`include "cpu_defs.vh"

    always @(posedge clk) begin
        if (rst || flush) begin
            instruction_out <= `NOP_INSTR;
            pc_out          <= 8'd0;
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
