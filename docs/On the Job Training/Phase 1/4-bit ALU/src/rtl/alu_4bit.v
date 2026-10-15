`timescale 1ns / 1ps
// ============================================================================
// alu_4bit.v  -- TOP LEVEL                             [Build step 9 / Level 2]
// Author  : Vu Quoc Anh    Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// ----------------------------------------------------------------------------
// 4-bit ALU, 10 operations. MUL and DIV re-use the ONE adder/subtractor by
// shifting, instead of a separate multiplier/divider array.
//
//   opcode: 0000 ADD | 0001 SUB | 0010 AND | 0011 OR
//           0100 XOR | 0101 NOT | 0110 SHL | 0111 SHR
//           1000 MUL | 1001 DIV | 1010-1111 unused (result 0)
//
// Single-cycle ops : result valid combinationally (no clock needed).
// MUL / DIV        : pulse start for 1 clock, wait for done (1 + 4 clocks),
//                    keep opcode = MUL/DIV while reading result.
//
// The top level contains only wiring plus the "glue":
//   * 3 x 2:1 muxes that hand the adder to muldiv_unit while busy = 1
//   * start gating (start & is_muldiv)
//   * div_by_zero gating (is_div & md_dbz)
// ============================================================================
module alu_4bit (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [3:0] opcode,
    output wire [7:0] result,
    output wire       carry,
    output wire       zero,
    output wire       overflow,
    output wire       negative,
    output wire       div_by_zero,
    output wire       busy,
    output wire       done
);
    // ---------------------------------------------------------- control
    wire sub, arith, is_shl, is_shr, is_div, is_muldiv;

    control_unit u_ctrl (
        .opcode(opcode), .sub(sub), .arith(arith),
        .is_shl(is_shl), .is_shr(is_shr),
        .is_div(is_div), .is_muldiv(is_muldiv)
    );

    // ---------------------------------------------------------- shared adder
    wire [3:0] md_add_a, md_add_b;
    wire       md_add_sub;

    wire [3:0] add_in_a  = busy ? md_add_a   : a;     // glue mux 1
    wire [3:0] add_in_b  = busy ? md_add_b   : b;     // glue mux 2
    wire       add_sub   = busy ? md_add_sub : sub;   // glue mux 3

    wire [3:0] sum;
    wire       c3, c4;

    adder_subtractor_4bit u_addsub (
        .a(add_in_a), .b(add_in_b), .sub(add_sub),
        .sum(sum), .c3(c3), .c4(c4)
    );

    // ---------------------------------------------------------- logic, shift
    wire [3:0] and_out, or_out, xor_out, not_out;
    wire [3:0] shl, shr;
    wire       shl_out_bit, shr_out_bit;

    logic_unit_4bit u_logic (
        .a(a), .b(b),
        .and_out(and_out), .or_out(or_out),
        .xor_out(xor_out), .not_out(not_out)
    );

    shifter_4bit u_shift (
        .a(a), .shl(shl), .shr(shr),
        .shl_out_bit(shl_out_bit), .shr_out_bit(shr_out_bit)
    );

    // ---------------------------------------------------------- mul / div
    wire [3:0] md_hi, md_lo;
    wire       md_dbz;

    muldiv_unit u_muldiv (
        .clk(clk), .rst(rst),
        .start(start & is_muldiv), .is_div(is_div),
        .a(a), .b(b),
        .add_a(md_add_a), .add_b(md_add_b), .add_sub(md_add_sub),
        .add_sum(sum), .add_c4(c4),
        .hi(md_hi), .lo(md_lo),
        .busy(busy), .done(done), .div_by_zero(md_dbz)
    );

    assign div_by_zero = is_div & md_dbz;

    // ---------------------------------------------------------- result select
    result_mux u_mux (
        .opcode(opcode), .sum(sum),
        .and_out(and_out), .or_out(or_out),
        .xor_out(xor_out), .not_out(not_out),
        .shl(shl), .shr(shr),
        .md_hi(md_hi), .md_lo(md_lo),
        .result(result)
    );

    // ---------------------------------------------------------- flags
    flag_unit u_flags (
        .result(result), .arith(arith),
        .is_shl(is_shl), .is_shr(is_shr), .is_muldiv(is_muldiv),
        .c3(c3), .c4(c4),
        .shl_out_bit(shl_out_bit), .shr_out_bit(shr_out_bit),
        .carry(carry), .zero(zero), .overflow(overflow), .negative(negative)
    );
endmodule
