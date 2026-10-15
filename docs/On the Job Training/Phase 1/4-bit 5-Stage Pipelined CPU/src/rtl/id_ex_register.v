// =============================================================================
// File        : id_ex_register.v
// Module      : id_ex_register
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : ID/EX pipeline register
// Job         : Carries everything EX, MEM and WB will need for one
//               instruction: control signals, register numbers, immediate,
//               the two register values read in ID, address, valid bit and
//               the instruction word (for tracing). rst or bubble loads an
//               empty slot: every write enable 0, so nothing changes later.
// Ports       : clk, rst, bubble; *_in inputs from ID; same names without
//               _in as outputs to EX (see the port list below)
// Connections : instance ID_EX in cpu_top; tested by tb_id_ex_register
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module id_ex_register (
    input  wire        clk,
    input  wire        rst,
    input  wire        bubble,          // 1 = insert a NOP (stall)
    // ---- from ID ----
    input  wire [2:0]  alu_ctrl_in,
    input  wire        alu_src_sel_in,
    input  wire        wb_sel_in,
    input  wire        reg_we_in,
    input  wire        mem_we_in,
    input  wire        zero_we_in,
    input  wire        carry_we_in,
    input  wire [1:0]  rd_in,
    input  wire [1:0]  rs_in,
    input  wire [3:0]  imm_in,
    input  wire [3:0]  rd_value_in,
    input  wire [3:0]  rs_value_in,
    input  wire [3:0]  pc_in,
    input  wire        valid_in,
    input  wire [11:0] instr_in,
    // ---- to EX ----
    output reg  [2:0]  alu_ctrl,
    output reg         alu_src_sel,
    output reg         wb_sel,
    output reg         reg_we,
    output reg         mem_we,
    output reg         zero_we,
    output reg         carry_we,
    output reg  [1:0]  rd,
    output reg  [1:0]  rs,
    output reg  [3:0]  imm,
    output reg  [3:0]  rd_value,
    output reg  [3:0]  rs_value,
    output reg  [3:0]  pc,
    output reg         valid,
    output reg  [11:0] instr
);
`include "cpu_defs.vh"

    always @(posedge clk) begin
        if (rst || bubble) begin
            alu_ctrl    <= `ALU_ADD;
            alu_src_sel <= 1'b0;
            wb_sel      <= 1'b0;
            reg_we      <= 1'b0;        // no register write
            mem_we      <= 1'b0;        // no memory write
            zero_we     <= 1'b0;        // no flag write
            carry_we    <= 1'b0;
            rd          <= 2'd0;
            rs          <= 2'd0;
            imm         <= 4'd0;
            rd_value    <= 4'd0;
            rs_value    <= 4'd0;
            pc          <= 4'd0;
            valid       <= 1'b0;        // empty slot
            instr       <= `NOP_INSTR;
        end
        else begin
            alu_ctrl    <= alu_ctrl_in;
            alu_src_sel <= alu_src_sel_in;
            wb_sel      <= wb_sel_in;
            reg_we      <= reg_we_in;
            mem_we      <= mem_we_in;
            zero_we     <= zero_we_in;
            carry_we    <= carry_we_in;
            rd          <= rd_in;
            rs          <= rs_in;
            imm         <= imm_in;
            rd_value    <= rd_value_in;
            rs_value    <= rs_value_in;
            pc          <= pc_in;
            valid       <= valid_in;
            instr       <= instr_in;
        end
    end

endmodule

`default_nettype wire
