// =============================================================================
// File        : mux3.v
// Module      : mux3
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Job         : 3-input, 4-bit multiplexer for operand forwarding.
//               sel = 00 -> d0, 01 -> d1, 10 -> d2, 11 -> d0 (never used).
//               Used 2 times: FWD_A_MUX and FWD_B_MUX (EX stage).
// Ports       :
//   d0  [3:0] in   register-file value from ID/EX (`FWD_ID)
//   d1  [3:0] in   wb_data from the WB stage      (`FWD_WB)
//   d2  [3:0] in   ALU result from EX/MEM         (`FWD_MEM)
//   sel [1:0] in   select from forwarding_unit
//   y   [3:0] out  forwarded operand
// Connections : instances FWD_A_MUX, FWD_B_MUX in cpu_top; tb_mux3
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module mux3 (
    input  wire [3:0] d0,
    input  wire [3:0] d1,
    input  wire [3:0] d2,
    input  wire [1:0] sel,
    output reg  [3:0] y
);

    always @(*) begin
        case (sel)
            2'b01:   y = d1;
            2'b10:   y = d2;
            default: y = d0;            // 00 and the unused 11
        endcase
    end

endmodule

`default_nettype wire
