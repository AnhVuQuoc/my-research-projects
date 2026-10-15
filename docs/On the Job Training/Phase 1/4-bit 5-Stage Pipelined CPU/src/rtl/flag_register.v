// =============================================================================
// File        : flag_register.v
// Module      : flag_register
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : written at the end of EX, read by the branch logic in ID
// Job         : Stores Zero and Carry with separate write enables, because
//               AND, OR, XOR and NOT change Zero only, while ADD and SUB
//               change both. Instructions that do not compute (LDI, MOV,
//               LOAD, STORE, JMP, JZ, NOP) leave both flags unchanged.
// Ports       :
//   clk         in   clock, rising edge
//   rst         in   synchronous reset, both flags <- 0
//   zero_we     in   1 = store a new Zero flag
//   carry_we    in   1 = store a new Carry flag
//   zero_in     in   zero output of the ALU
//   carry_in    in   carry output of the ALU
//   zero_flag   out  stored Zero
//   carry_flag  out  stored Carry
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
