// =============================================================================
// File        : alu.v
// Module      : alu
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : EX
// Job         : 4-bit arithmetic and logic unit. ADD and SUB share ONE adder:
//               SUB is done as a + ~b + 1 (XOR gates invert b, carry-in = 1).
//               The adder carry-out is then the Carry flag for ADD and the
//               no-borrow flag for SUB, with no extra comparator.
// Ports       :
//   a        [3:0] in   operand A (forwarded value of Rd)
//   b        [3:0] in   operand B (forwarded value of Rs, or the immediate)
//   alu_ctrl [2:0] in   operation code (`ALU_ADD .. `ALU_PASS)
//   result   [3:0] out  4-bit answer
//   carry          out  ADD: carry out of bit 3; SUB: 1 = no borrow (a >= b)
//   zero           out  1 when result == 4'b0000
// Connections : instance ALU in cpu_top (EX stage); tested by tb_alu
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module alu (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [2:0] alu_ctrl,
    output reg  [3:0] result,
    output reg        carry,
    output wire       zero
);
`include "cpu_defs.vh"

    // ---- shared adder / subtractor -----------------------------------------
    wire       do_sub = (alu_ctrl == `ALU_SUB);         // 1 only for SUB
    wire [3:0] b_mod  = b ^ {4{do_sub}};                // SUB: invert every bit of b
    wire [4:0] sum    = {1'b0, a} + {1'b0, b_mod} + {4'b0000, do_sub}; // bit 4 = carry out

    // ---- result multiplexer (safe defaults first, so no latch) -------------
    always @(*) begin
        result = 4'b0000;
        carry  = 1'b0;
        case (alu_ctrl)
            `ALU_ADD : begin result = sum[3:0]; carry = sum[4]; end
            `ALU_SUB : begin result = sum[3:0]; carry = sum[4]; end
            `ALU_AND : result = a & b;
            `ALU_OR  : result = a | b;
            `ALU_XOR : result = a ^ b;
            `ALU_NOT : result = ~a;
            `ALU_PASS: result = b;
            default  : result = 4'b0000;               // code 7 is unused
        endcase
    end

    // ---- zero detector ------------------------------------------------------
    assign zero = (result == 4'b0000);

endmodule

`default_nettype wire
