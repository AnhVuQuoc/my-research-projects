// =============================================================================
// File        : mux3.v
// Module      : mux3
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Job         : 3-input, 8-bit forwarding multiplexer.
//               sel = 00 -> d0, 01 -> d1, 10 -> d2, 11 -> d0 (never used).
// Ports       : d0 (register value), d1 (wb_data), d2 (EX/MEM result) [7:0],
//               sel [1:0] in; y [7:0] out
// Connections : instances FWD_A_MUX, FWD_B_MUX in cpu_top; tb_mux3
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module mux3 (
    input  wire [7:0] d0,
    input  wire [7:0] d1,
    input  wire [7:0] d2,
    input  wire [1:0] sel,
    output reg  [7:0] y
);

    always @(*) begin
        case (sel)
            2'b01:   y = d1;
            2'b10:   y = d2;
            default: y = d0;
        endcase
    end

endmodule

`default_nettype wire
