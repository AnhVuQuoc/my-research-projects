`timescale 1ns / 1ps
// ============================================================================
// shifter_4bit.v                                       [Build step 4 / Level 1]
// Author  : Vu Quoc Anh    Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// ----------------------------------------------------------------------------
// Logical shift by one position. Pure wiring: no gates are generated.
//   shl = {a[2:0], 0}   (a * 2, a[3] falls out)
//   shr = {0, a[3:1]}   (a / 2, a[0] falls out)
// The bit that falls out goes to flag_unit to become the carry flag.
//
// Ports
//   a           : in  4
//   shl, shr    : out 4
//   shl_out_bit : out 1   = a[3]
//   shr_out_bit : out 1   = a[0]
// ============================================================================
module shifter_4bit (
    input  wire [3:0] a,
    output wire [3:0] shl,
    output wire [3:0] shr,
    output wire       shl_out_bit,
    output wire       shr_out_bit
);
    assign shl         = {a[2:0], 1'b0};
    assign shr         = {1'b0, a[3:1]};
    assign shl_out_bit = a[3];
    assign shr_out_bit = a[0];
endmodule
