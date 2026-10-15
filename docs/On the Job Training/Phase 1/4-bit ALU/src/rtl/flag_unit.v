`timescale 1ns / 1ps
// ============================================================================
// flag_unit.v                                          [Build step 7 / Level 1]
// Author  : Vu Quoc Anh    Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// ----------------------------------------------------------------------------
// Status flags (Section 8 flag specification):
//   carry    : ADD -> c4 (carry out), SUB -> c4 (1 = no borrow),
//              SHL -> a[3] shifted out, SHR -> a[0] shifted out, others 0
//   overflow : ADD/SUB only -> c3 ^ c4 (signed result outside -8..+7)
//   zero     : all 8 result bits are 0 (NOR of result[7:0])
//   negative : result[3] (4-bit sign bit); forced 0 for MUL/DIV (unsigned)
// ============================================================================
module flag_unit (
    input  wire [7:0] result,
    input  wire       arith,
    input  wire       is_shl,
    input  wire       is_shr,
    input  wire       is_muldiv,
    input  wire       c3,
    input  wire       c4,
    input  wire       shl_out_bit,
    input  wire       shr_out_bit,
    output wire       carry,
    output wire       zero,
    output wire       overflow,
    output wire       negative
);
    assign carry    = (arith  & c4)
                    | (is_shl & shl_out_bit)
                    | (is_shr & shr_out_bit);
    assign overflow = arith & (c3 ^ c4);
    assign zero     = ~|result;
    assign negative = ~is_muldiv & result[3];
endmodule
