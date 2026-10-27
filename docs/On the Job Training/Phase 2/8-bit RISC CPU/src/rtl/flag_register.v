// =============================================================================
// File        : flag_register.v
// Module      : flag_register
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : written at the end of EX, read by the branch logic in ID
// Job         : Stores Zero and Carry with separate write enables (AND, OR, XOR
//               change Zero only; ADD, SUB, ADDI, SHL, SHR change both).
// Ports       : clk, rst, zero_we, carry_we, zero_in, carry_in in;
//               zero_flag, carry_flag out
// Connections : instance FLAGS in cpu_top; tested by tb_flag_register
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module flag_register (
    input  wire clk,
    input  wire rst,
    input  wire zero_we,
    input  wire carry_we,
    input  wire zero_in,
    input  wire carry_in,
    output reg  zero_flag,
    output reg  carry_flag
);

    always @(posedge clk) begin
        if (rst) begin
            zero_flag  <= 1'b0;
            carry_flag <= 1'b0;
        end
        else begin
            if (zero_we)  zero_flag  <= zero_in;
            if (carry_we) carry_flag <= carry_in;
        end
    end

endmodule

`default_nettype wire
