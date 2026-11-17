// =============================================================================
// File        : register_file.v
// Module      : register_file
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : read in ID, written by WB
// Job         : 8 general-purpose registers R0..R7 (8 bits each; R0 is an
//               ordinary register), 2 combinational read ports, 1 clocked write
//               port, write-first bypass (a read of the register being written
//               in the same cycle returns the new value wd).
// Ports       :
//   clk, rst          in   clock; synchronous reset clears R0..R7
//   ra [2:0], rb [2:0] in  read addresses (port A, port B), chosen by control_unit
//   wa [2:0]          in   write address (rd of the instruction in WB)
//   wd [7:0]          in   write data (wb_data)
//   we                in   write enable (reg_we of the instruction in WB)
//   qa [7:0], qb [7:0] out values of registers ra, rb (bypassed)
// Connections : instance RF in cpu_top; tb_cpu reads CPU.RF.r0 .. CPU.RF.r7
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module register_file (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] ra,
    input  wire [2:0] rb,
    input  wire [2:0] wa,
    input  wire [7:0] wd,
    input  wire       we,
    output reg  [7:0] qa,
    output reg  [7:0] qb
);

    reg [7:0] r0, r1, r2, r3, r4, r5, r6, r7;

    // ---- write port (clocked) ----------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            r0 <= 8'h00; r1 <= 8'h00; r2 <= 8'h00; r3 <= 8'h00;
            r4 <= 8'h00; r5 <= 8'h00; r6 <= 8'h00; r7 <= 8'h00;
        end
        else if (we) begin
            case (wa)
                3'd0: r0 <= wd;  3'd1: r1 <= wd;  3'd2: r2 <= wd;  3'd3: r3 <= wd;
                3'd4: r4 <= wd;  3'd5: r5 <= wd;  3'd6: r6 <= wd;  default: r7 <= wd;
            endcase
        end
    end

    // ---- read port A (combinational, write-first bypass) -------------------
    always @(*) begin
        if (we && (wa == ra))
            qa = wd;                                  // bypass
        else begin
            case (ra)
                3'd0: qa = r0;  3'd1: qa = r1;  3'd2: qa = r2;  3'd3: qa = r3;
                3'd4: qa = r4;  3'd5: qa = r5;  3'd6: qa = r6;  default: qa = r7;
            endcase
        end
    end

    // ---- read port B (combinational, write-first bypass) -------------------
    always @(*) begin
        if (we && (wa == rb))
            qb = wd;                                  // bypass
        else begin
            case (rb)
                3'd0: qb = r0;  3'd1: qb = r1;  3'd2: qb = r2;  3'd3: qb = r3;
                3'd4: qb = r4;  3'd5: qb = r5;  3'd6: qb = r6;  default: qb = r7;
            endcase
        end
    end

endmodule

`default_nettype wire
