`timescale 1ns / 1ps
// ============================================================================
// adder_subtractor_4bit.v                              [Build step 2 / Level 1]
// Author  : Vu Quoc Anh    Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// ----------------------------------------------------------------------------
// 4-bit ripple-carry adder/subtractor.
//   sub = 0 : sum = a + b
//   sub = 1 : sum = a - b = a + ~b + 1   (two's complement)
// Each b bit is XORed with 'sub' (conditional inversion) and 'sub' is also the
// carry-in c[0] (the "+1").
//
// This is the ONLY adder in the whole ALU. It is shared: ADD/SUB use it
// normally, and muldiv_unit borrows it while busy = 1 (see alu_4bit.v).
//
// Ports
//   a, b : in  4   operands
//   sub  : in  1   0 = add, 1 = subtract
//   sum  : out 4   result bits
//   c3   : out 1   carry INTO bit 3  (for overflow = c3 ^ c4)
//   c4   : out 1   carry OUT of bit 3 (ADD: carry, SUB: 1 = no borrow)
// ============================================================================
module adder_subtractor_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       sub,
    output wire [3:0] sum,
    output wire       c3,
    output wire       c4
);
    wire [3:0] b_x;     // b after conditional inversion
    wire [4:0] c;       // carry chain, c[0] = carry-in

    assign c[0] = sub;

    xor xb0 (b_x[0], b[0], sub);
    xor xb1 (b_x[1], b[1], sub);
    xor xb2 (b_x[2], b[2], sub);
    xor xb3 (b_x[3], b[3], sub);

    full_adder fa0 (.a(a[0]), .b(b_x[0]), .cin(c[0]), .sum(sum[0]), .cout(c[1]));
    full_adder fa1 (.a(a[1]), .b(b_x[1]), .cin(c[1]), .sum(sum[1]), .cout(c[2]));
    full_adder fa2 (.a(a[2]), .b(b_x[2]), .cin(c[2]), .sum(sum[2]), .cout(c[3]));
    full_adder fa3 (.a(a[3]), .b(b_x[3]), .cin(c[3]), .sum(sum[3]), .cout(c[4]));

    assign c3 = c[3];
    assign c4 = c[4];
endmodule
