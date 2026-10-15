`timescale 1ns / 1ps
// ============================================================================
// logic_unit_4bit.v                                    [Build step 3 / Level 1]
// Author  : Vu Quoc Anh    Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// ----------------------------------------------------------------------------
// Bitwise logic, all four results computed in parallel. result_mux picks one.
// Bit i of every output depends only on bit i of a and b.
//
// Ports
//   a, b    : in  4
//   and_out : out 4   a & b   (masking / clearing bits)
//   or_out  : out 4   a | b   (setting bits)
//   xor_out : out 4   a ^ b   (flipping / comparing)
//   not_out : out 4   ~a      (b is not used)
// ============================================================================
module logic_unit_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] and_out,
    output wire [3:0] or_out,
    output wire [3:0] xor_out,
    output wire [3:0] not_out
);
    assign and_out = a & b;
    assign or_out  = a | b;
    assign xor_out = a ^ b;
    assign not_out = ~a;
endmodule
