// =============================================================================
// File        : register_file.v
// Module      : register_file
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : read in ID, written by WB
// Job         : 4 general-purpose registers R0..R3 (4 bits each), 2
//               combinational read ports and 1 clocked write port.
//               NEW in the 5-stage design: write-first bypass. When WB writes
//               register X in the same clock in which ID reads X, the read
//               port returns the NEW value wd (it would otherwise return the
//               old value, because the write only happens at the clock edge).
//               This removes the "distance 3" data hazard.
// Ports       :
//   clk          in   clock, rising edge
//   rst          in   synchronous reset, clears R0..R3
//   ra     [1:0] in   read address A (Rd of the instruction in ID)
//   rb     [1:0] in   read address B (Rs of the instruction in ID)
//   wa     [1:0] in   write address (Rd of the instruction in WB)
//   wd     [3:0] in   write data (wb_data)
//   we           in   write enable (reg_we of the instruction in WB)
//   qa     [3:0] out  value of register ra (bypassed)
//   qb     [3:0] out  value of register rb (bypassed)
// Connections : instance RF in cpu_top; tested by tb_register_file;
//               tb_cpu reads CPU.RF.r0 .. CPU.RF.r3 (simulation only)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module register_file (
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] ra,
    input  wire [1:0] rb,
    input  wire [1:0] wa,
    input  wire [3:0] wd,
    input  wire       we,
    output reg  [3:0] qa,
    output reg  [3:0] qb
);

    reg [3:0] r0, r1, r2, r3;          // the four architectural registers

    // ---- write port (clocked) ----------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            r0 <= 4'b0000;
            r1 <= 4'b0000;
            r2 <= 4'b0000;
            r3 <= 4'b0000;
        end
        else if (we) begin
            case (wa)
                2'd0: r0 <= wd;
                2'd1: r1 <= wd;
                2'd2: r2 <= wd;
                2'd3: r3 <= wd;
            endcase
        end
    end

    // ---- read port A (combinational, write-first bypass) -------------------
    always @(*) begin
        if (we && (wa == ra))
            qa = wd;                    // bypass: value being written this clock
        else begin
            case (ra)
                2'd0: qa = r0;
                2'd1: qa = r1;
                2'd2: qa = r2;
                default: qa = r3;
            endcase
        end
    end

    // ---- read port B (combinational, write-first bypass) -------------------
    always @(*) begin
        if (we && (wa == rb))
            qb = wd;                    // bypass: value being written this clock
        else begin
            case (rb)
                2'd0: qb = r0;
                2'd1: qb = r1;
                2'd2: qb = r2;
                default: qb = r3;
            endcase
        end
    end

endmodule

`default_nettype wire
