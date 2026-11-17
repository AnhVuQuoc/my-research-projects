// =============================================================================
// File        : alu.v
// Module      : alu
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : EX
// Job         : 8-bit ALU. ADD and SUB share 1 adder (SUB = a + ~b + 1). The SUB
//               Carry is a BORROW flag (1 when a < b) = NOT carry-out (spec).
//               SHL / SHR shift by 1 and put the bit shifted out into Carry.
//               PASS_A gives the LD/ST address, PASS_B the LDI constant.
// Ports       :
//   a        [7:0] in   operand A (forwarded value of the port-A register)
//   b        [7:0] in   operand B (forwarded port-B value or imm8)
//   alu_ctrl [3:0] in   operation (`ALU_ADD .. `ALU_PASSA)
//   result   [7:0] out  answer
//   carry          out  ADD: carry out; SUB: borrow; SHL: old bit 7; SHR: old bit 0
//   zero           out  1 when result == 8'h00
// Connections : instance ALU in cpu_top; tested by tb_alu
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module alu (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [3:0] alu_ctrl,
    output reg  [7:0] result,
    output reg        carry,
    output wire       zero
);
`include "cpu_defs.vh"

    wire       do_sub = (alu_ctrl == `ALU_SUB);
    wire [7:0] b_mod  = b ^ {8{do_sub}};                     // invert b for SUB
    wire [8:0] sum    = {1'b0, a} + {1'b0, b_mod} + {8'd0, do_sub};  // bit 8 = carry out

    always @(*) begin
        result = 8'h00;                                       // safe defaults
        carry  = 1'b0;
        case (alu_ctrl)
            `ALU_ADD  : begin result = sum[7:0]; carry =  sum[8]; end
            `ALU_SUB  : begin result = sum[7:0]; carry = ~sum[8]; end  // borrow
            `ALU_AND  : result = a & b;
            `ALU_OR   : result = a | b;
            `ALU_XOR  : result = a ^ b;
            `ALU_SHL  : begin result = {a[6:0], 1'b0}; carry = a[7]; end
            `ALU_SHR  : begin result = {1'b0, a[7:1]}; carry = a[0]; end
            `ALU_PASSB: result = b;
            `ALU_PASSA: result = a;
            default   : result = 8'h00;
        endcase
    end

    assign zero = (result == 8'h00);

endmodule

`default_nettype wire
