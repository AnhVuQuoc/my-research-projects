`timescale 1ns / 1ps
// ============================================================================
// full_adder.v                                         [Build step 1 / Level 0]
// Author  : Vu Quoc Anh    Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// ----------------------------------------------------------------------------
// 1-bit full adder built from primitive gates (5 gates: 2 XOR, 2 AND, 1 OR).
//
//   p    = a ^ b          (propagate)
//   g    = a & b          (generate)
//   sum  = p ^ cin
//   cout = g | (p & cin)
//
// Ports
//   a, b, cin : in  1   operand bits and carry-in
//   sum       : out 1   sum bit
//   cout      : out 1   carry-out
// ============================================================================
module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    wire p;     // propagate
    wire g;     // generate
    wire pc;    // p AND cin

    xor x1 (p,    a, b);
    xor x2 (sum,  p, cin);
    and a1 (g,    a, b);
    and a2 (pc,   p, cin);
    or  o1 (cout, g, pc);
endmodule
