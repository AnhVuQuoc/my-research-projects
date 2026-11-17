// =============================================================================
// File        : mem_wb_register.v
// Module      : mem_wb_register
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : MEM/WB pipeline register
// Job         : Both possible results (ALU result, memory data), rd, reg_we,
//               wb_sel, address, valid, instruction. An instruction RETIRES in
//               the cycle it sits here with valid = 1.
// Ports       : clk, rst; *_in from MEM; outputs to WB
// Connections : instance MEM_WB in cpu_top; tested by tb_mem_wb_register
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module mem_wb_register (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  alu_result_in,
    input  wire [7:0]  mem_data_in,
    input  wire [2:0]  rd_in,
    input  wire        reg_we_in,
    input  wire        wb_sel_in,
    input  wire [7:0]  pc_in,
    input  wire        valid_in,
    input  wire [15:0] instr_in,
    output reg  [7:0]  alu_result,
    output reg  [7:0]  mem_data,
    output reg  [2:0]  rd,
    output reg         reg_we,
    output reg         wb_sel,
    output reg  [7:0]  pc,
    output reg         valid,
    output reg  [15:0] instr
);
`include "cpu_defs.vh"

    always @(posedge clk) begin
        if (rst) begin
            alu_result <= 8'd0; mem_data <= 8'd0; rd <= 3'd0; reg_we <= 1'b0;
            wb_sel <= 1'b0; pc <= 8'd0; valid <= 1'b0; instr <= `NOP_INSTR;
        end
        else begin
            alu_result <= alu_result_in; mem_data <= mem_data_in; rd <= rd_in;
            reg_we <= reg_we_in; wb_sel <= wb_sel_in; pc <= pc_in;
            valid <= valid_in; instr <= instr_in;
        end
    end

endmodule

`default_nettype wire
