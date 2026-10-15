`timescale 1ns / 1ps
// ============================================================================
// control_unit.v                                       [Build step 5 / Level 1]
// Author  : Vu Quoc Anh    Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// ----------------------------------------------------------------------------
// Opcode decoder: 4-bit opcode -> six 1-bit control lines. Combinational.
//
//   opcode    op     type
//   0000      ADD    single cycle      \  arith     = 000x
//   0001      SUB    single cycle      /  sub       = 0001
//   0010      AND    single cycle
//   0011      OR     single cycle
//   0100      XOR    single cycle
//   0101      NOT A  single cycle
//   0110      SHL    single cycle         is_shl    = 0110
//   0111      SHR    single cycle         is_shr    = 0111
//   1000      MUL    multicycle        \  is_muldiv = 100x
//   1001      DIV    multicycle        /  is_div    = 1001
//   1010-1111 unused -> result 0
// ============================================================================
module control_unit (
    input  wire [3:0] opcode,
    output wire       sub,        // SUB             (0001)
    output wire       arith,      // ADD or SUB      (000x)
    output wire       is_shl,     // shift left      (0110)
    output wire       is_shr,     // shift right     (0111)
    output wire       is_div,     // divide          (1001)
    output wire       is_muldiv   // MUL or DIV      (100x)
);
    assign sub       = (opcode      == 4'b0001);
    assign arith     = (opcode[3:1] == 3'b000);
    assign is_shl    = (opcode      == 4'b0110);
    assign is_shr    = (opcode      == 4'b0111);
    assign is_div    = (opcode      == 4'b1001);
    assign is_muldiv = (opcode[3:1] == 3'b100);
endmodule
