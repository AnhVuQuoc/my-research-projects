// =============================================================================
// File        : ex_mem_register.v
// Module      : ex_mem_register
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : EX/MEM pipeline register
// Job         : Carries the ALU result (also the data-memory address), the
//               store data (forwarded Rd value), Rd and the controls still
//               needed in MEM and WB. EX never stalls, so there is no bubble
//               input; rst loads an empty slot.
// Ports       : clk, rst; *_in inputs from EX; outputs to MEM
// Connections : instance EX_MEM in cpu_top; tested by tb_ex_mem_register
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module ex_mem_register (
    input  wire        clk,
    input  wire        rst,
    // ---- from EX ----
    input  wire [3:0]  alu_result_in,
    input  wire [3:0]  store_data_in,
    input  wire [1:0]  rd_in,
    input  wire        reg_we_in,
    input  wire        mem_we_in,
    input  wire        wb_sel_in,
    input  wire [3:0]  pc_in,
    input  wire        valid_in,
    input  wire [11:0] instr_in,
    // ---- to MEM ----
    output reg  [3:0]  alu_result,
    output reg  [3:0]  store_data,
    output reg  [1:0]  rd,
    output reg         reg_we,
    output reg         mem_we,
    output reg         wb_sel,
    output reg  [3:0]  pc,
    output reg         valid,
    output reg  [11:0] instr
);
`include "cpu_defs.vh"

    always @(posedge clk) begin
        if (rst) begin
            alu_result <= 4'd0;
            store_data <= 4'd0;
            rd         <= 2'd0;
            reg_we     <= 1'b0;
            mem_we     <= 1'b0;
            wb_sel     <= 1'b0;
            pc         <= 4'd0;
            valid      <= 1'b0;
            instr      <= `NOP_INSTR;
        end
        else begin
            alu_result <= alu_result_in;
            store_data <= store_data_in;
            rd         <= rd_in;
            reg_we     <= reg_we_in;
            mem_we     <= mem_we_in;
            wb_sel     <= wb_sel_in;
            pc         <= pc_in;
            valid      <= valid_in;
            instr      <= instr_in;
        end
    end

endmodule

`default_nettype wire
