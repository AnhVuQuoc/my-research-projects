`timescale 1ns / 1ps
// ============================================================================
// result_mux.v                                         [Build step 6 / Level 1]
// Author  : Vu Quoc Anh    Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// ----------------------------------------------------------------------------
// Selects which unit's output becomes the 8-bit ALU result.
//   single-cycle ops : result = {4'b0000, 4-bit answer}  (zero-extended)
//   MUL              : result = {product[7:4], product[3:0]} = {md_hi, md_lo}
//   DIV              : result = {remainder, quotient}        = {md_hi, md_lo}
//   unused 1010-1111 : result = 0
// Note: every case assigns 'result', so no latch is inferred.
// ============================================================================
module result_mux (
    input  wire [3:0] opcode,
    input  wire [3:0] sum,
    input  wire [3:0] and_out,
    input  wire [3:0] or_out,
    input  wire [3:0] xor_out,
    input  wire [3:0] not_out,
    input  wire [3:0] shl,
    input  wire [3:0] shr,
    input  wire [3:0] md_hi,
    input  wire [3:0] md_lo,
    output reg  [7:0] result
);
    always @(*) begin
        case (opcode)
            4'b0000, 4'b0001: result = {4'b0000, sum};
            4'b0010:          result = {4'b0000, and_out};
            4'b0011:          result = {4'b0000, or_out};
            4'b0100:          result = {4'b0000, xor_out};
            4'b0101:          result = {4'b0000, not_out};
            4'b0110:          result = {4'b0000, shl};
            4'b0111:          result = {4'b0000, shr};
            4'b1000, 4'b1001: result = {md_hi, md_lo};
            default:          result = 8'b0000_0000;
        endcase
    end
endmodule
