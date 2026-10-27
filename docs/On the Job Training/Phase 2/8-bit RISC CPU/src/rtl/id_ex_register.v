// =============================================================================
// File        : id_ex_register.v
// Module      : id_ex_register
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : ID/EX pipeline register
// Job         : Carries the controls, rd, the 2 READ register numbers (ra, rb,
//               needed by the forwarding unit), imm8, the 2 values read in ID,
//               address, valid and the instruction word. rst or bubble loads an
//               empty slot (every write enable 0, instr = 0000).
// Ports       : clk, rst, bubble; *_in from ID; same names without _in to EX
// Connections : instance ID_EX in cpu_top; tested by tb_id_ex_register
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module id_ex_register (
    input  wire        clk,
    input  wire        rst,
    input  wire        bubble,
    input  wire [3:0]  alu_ctrl_in,
    input  wire        alu_src_sel_in,
    input  wire        wb_sel_in,
    input  wire        reg_we_in,
    input  wire        mem_we_in,
    input  wire        zero_we_in,
    input  wire        carry_we_in,
    input  wire [2:0]  rd_in,
    input  wire [2:0]  ra_in,
    input  wire [2:0]  rb_in,
    input  wire [7:0]  imm_in,
    input  wire [7:0]  a_value_in,
    input  wire [7:0]  b_value_in,
    input  wire [7:0]  pc_in,
    input  wire        valid_in,
    input  wire [15:0] instr_in,
    output reg  [3:0]  alu_ctrl,
    output reg         alu_src_sel,
    output reg         wb_sel,
    output reg         reg_we,
    output reg         mem_we,
    output reg         zero_we,
    output reg         carry_we,
    output reg  [2:0]  rd,
    output reg  [2:0]  ra,
    output reg  [2:0]  rb,
    output reg  [7:0]  imm,
    output reg  [7:0]  a_value,
    output reg  [7:0]  b_value,
    output reg  [7:0]  pc,
    output reg         valid,
    output reg  [15:0] instr
);
`include "cpu_defs.vh"

    always @(posedge clk) begin
        if (rst || bubble) begin
            alu_ctrl <= `ALU_ADD; alu_src_sel <= 1'b0; wb_sel <= 1'b0;
            reg_we <= 1'b0; mem_we <= 1'b0; zero_we <= 1'b0; carry_we <= 1'b0;
            rd <= 3'd0; ra <= 3'd0; rb <= 3'd0; imm <= 8'd0;
            a_value <= 8'd0; b_value <= 8'd0; pc <= 8'd0;
            valid <= 1'b0; instr <= `NOP_INSTR;
        end
        else begin
            alu_ctrl <= alu_ctrl_in; alu_src_sel <= alu_src_sel_in; wb_sel <= wb_sel_in;
            reg_we <= reg_we_in; mem_we <= mem_we_in; zero_we <= zero_we_in; carry_we <= carry_we_in;
            rd <= rd_in; ra <= ra_in; rb <= rb_in; imm <= imm_in;
            a_value <= a_value_in; b_value <= b_value_in; pc <= pc_in;
            valid <= valid_in; instr <= instr_in;
        end
    end

endmodule

`default_nettype wire
