// =============================================================================
// File        : cpu_top.v
// Module      : cpu_top
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Job         : Connects every block into the 5-stage pipeline:
//                 IF  : PC -> instruction memory -> IF/ID (IR)
//                 ID  : decode + read-register select, register read (bypassed),
//                       hazard check, branch decision, HLT -> ID/EX
//                 EX  : forwarding MUXes -> operand MUX -> ALU -> flags -> EX/MEM
//                 MEM : data memory (address = ALU result) -> MEM/WB
//                 WB  : WB MUX -> register-file write port
//               Logic kept here: PC + 1, the field split, the reset gate on the
//               memory write enable. Net names: stage prefix + plan name.
// Parameter   : PROGRAM_FILE  program loaded into instruction_memory
// Ports       :
//   clk, rst                in   clock; synchronous reset
//   pc_out      [7:0]       out  fetch address                    valid always
//   instr_out   [15:0]      out  instruction in EX (0000 = empty)  valid always
//   alu_out     [7:0]       out  ALU result in EX
//   wb_data_out [7:0]       out  register write data              when WB writes
//   zero_out, carry_out     out  stored flags                     valid always
//   halted                  out  1 after HLT (until reset)
// Connections : top of the design; instance CPU in tb_cpu
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module cpu_top #(
    parameter PROGRAM_FILE = "program.mem"
)(
    input  wire        clk,
    input  wire        rst,
    output wire [7:0]  pc_out,
    output wire [15:0] instr_out,
    output wire [7:0]  alu_out,
    output wire [7:0]  wb_data_out,
    output wire        zero_out,
    output wire        carry_out,
    output wire        halted
);

    // ------------------------------------------------------------------------
    // Nets that cross stages
    // ------------------------------------------------------------------------
    wire        pc_sel, flush, stall, ir_load, id_ex_bubble;
    wire        pc_en, if_id_flush;
    /* verilator lint_off UNUSEDSIGNAL */
    wire        load_use_stall, flag_stall, halt;        // trace only
    /* verilator lint_on UNUSEDSIGNAL */
    wire [7:0]  id_imm;
    wire        zero_flag, carry_flag;
    wire [7:0]  mem_alu_result;
    wire [2:0]  mem_rd;
    wire        mem_reg_we;
    wire [7:0]  wb_data;
    wire [2:0]  wb_rd;
    wire        wb_reg_we;

    // ========================================================================
    // STAGE 1: IF (fetch)
    // ========================================================================
    wire [7:0]  if_pc;
    wire [7:0]  if_pc_plus_1;
    wire [7:0]  if_pc_next;
    wire [15:0] if_instr;

    assign if_pc_plus_1 = if_pc + 8'd1;                   // wraps 255 -> 0

    mux2 PC_MUX (
        .d0  (if_pc_plus_1),
        .d1  (id_imm),                                    // addr8, decided in ID
        .sel (pc_sel),
        .y   (if_pc_next)
    );

    program_counter PC (
        .clk     (clk),
        .rst     (rst),
        .pc_en   (pc_en),                                 // 0 on stall or halt
        .pc_next (if_pc_next),
        .pc_out  (if_pc)
    );

    instruction_memory #(.PROGRAM_FILE(PROGRAM_FILE)) IMEM (
        .address     (if_pc),
        .instruction (if_instr)
    );

    // ---- IF/ID pipeline register (the IR) ----------------------------------
    wire [15:0] id_instr;
    wire [7:0]  id_pc;
    wire        id_valid;

    instruction_register IR (
        .clk             (clk),
        .rst             (rst),
        .ir_load         (ir_load),
        .flush           (if_id_flush),                   // taken branch or halt
        .instruction_in  (if_instr),
        .pc_in           (if_pc),
        .instruction_out (id_instr),
        .pc_out          (id_pc),
        .valid_out       (id_valid)
    );

    // ========================================================================
    // STAGE 2: ID (decode, read-register select, register read, hazards,
    //              branch decision, halt)
    // ========================================================================
    wire [3:0]  id_opcode = id_instr[15:12];
    wire [2:0]  id_rd     = id_instr[11:9];
    wire [2:0]  id_rs1    = id_instr[8:6];
    wire [2:0]  id_rs2    = id_instr[5:3];
    assign      id_imm    = id_instr[7:0];                // overlaps rs1 and rs2

    wire [3:0]  id_alu_ctrl;
    wire        id_alu_src_sel, id_wb_sel, id_reg_we, id_mem_we, id_zero_we, id_carry_we;
    wire        id_uses_a, id_uses_b, id_is_bz, id_is_bnz, id_is_hlt;
    /* verilator lint_off UNUSEDSIGNAL */
    wire        id_is_jmp;                                // trace only
    /* verilator lint_on UNUSEDSIGNAL */
    wire [2:0]  id_ra, id_rb;                             // registers really read
    wire [7:0]  id_a_value, id_b_value;

    control_unit CU (
        .opcode      (id_opcode),
        .rd          (id_rd),
        .rs1         (id_rs1),
        .rs2         (id_rs2),
        .zero_flag   (zero_flag),
        .stall       (stall),
        .alu_ctrl    (id_alu_ctrl),
        .alu_src_sel (id_alu_src_sel),
        .wb_sel      (id_wb_sel),
        .reg_we      (id_reg_we),
        .mem_we      (id_mem_we),
        .zero_we     (id_zero_we),
        .carry_we    (id_carry_we),
        .uses_a      (id_uses_a),
        .uses_b      (id_uses_b),
        .ra          (id_ra),
        .rb          (id_rb),
        .is_jmp      (id_is_jmp),
        .is_bz       (id_is_bz),
        .is_bnz      (id_is_bnz),
        .is_hlt      (id_is_hlt),
        .pc_sel      (pc_sel),
        .flush       (flush)
    );

    register_file RF (
        .clk (clk),
        .rst (rst),
        .ra  (id_ra),                                     // rs1, or rd for ADDI
        .rb  (id_rb),                                     // rs2, or rd for ST
        .wa  (wb_rd),
        .wd  (wb_data),
        .we  (wb_reg_we),
        .qa  (id_a_value),
        .qb  (id_b_value)
    );

    // ---- ID/EX outputs (declared here because HU needs some of them) -------
    wire [3:0]  ex_alu_ctrl;
    wire        ex_alu_src_sel, ex_wb_sel, ex_reg_we, ex_mem_we, ex_zero_we, ex_carry_we;
    wire [2:0]  ex_rd, ex_ra, ex_rb;
    wire [7:0]  ex_imm, ex_a_value, ex_b_value, ex_pc;
    wire        ex_valid;
    wire [15:0] ex_instr;

    hazard_unit HU (
        .id_ra          (id_ra),
        .id_rb          (id_rb),
        .id_uses_a      (id_uses_a),
        .id_uses_b      (id_uses_b),
        .id_is_bz       (id_is_bz),
        .id_is_bnz      (id_is_bnz),
        .ex_rd          (ex_rd),
        .ex_reg_we      (ex_reg_we),
        .ex_wb_sel      (ex_wb_sel),
        .ex_zero_we     (ex_zero_we),
        .load_use_stall (load_use_stall),
        .flag_stall     (flag_stall),
        .stall          (stall),
        .ir_load        (ir_load),
        .id_ex_bubble   (id_ex_bubble)
    );

    halt_unit HALT (
        .clk          (clk),
        .rst          (rst),
        .id_is_hlt    (id_is_hlt),
        .stall        (stall),
        .branch_flush (flush),
        .halted       (halted),
        .halt         (halt),
        .pc_en        (pc_en),
        .if_id_flush  (if_id_flush)
    );

    // ---- ID/EX pipeline register -------------------------------------------
    id_ex_register ID_EX (
        .clk            (clk),
        .rst            (rst),
        .bubble         (id_ex_bubble),
        .alu_ctrl_in    (id_alu_ctrl),
        .alu_src_sel_in (id_alu_src_sel),
        .wb_sel_in      (id_wb_sel),
        .reg_we_in      (id_reg_we),
        .mem_we_in      (id_mem_we),
        .zero_we_in     (id_zero_we),
        .carry_we_in    (id_carry_we),
        .rd_in          (id_rd),
        .ra_in          (id_ra),
        .rb_in          (id_rb),
        .imm_in         (id_imm),
        .a_value_in     (id_a_value),
        .b_value_in     (id_b_value),
        .pc_in          (id_pc),
        .valid_in       (id_valid),
        .instr_in       (id_instr),
        .alu_ctrl       (ex_alu_ctrl),
        .alu_src_sel    (ex_alu_src_sel),
        .wb_sel         (ex_wb_sel),
        .reg_we         (ex_reg_we),
        .mem_we         (ex_mem_we),
        .zero_we        (ex_zero_we),
        .carry_we       (ex_carry_we),
        .rd             (ex_rd),
        .ra             (ex_ra),
        .rb             (ex_rb),
        .imm            (ex_imm),
        .a_value        (ex_a_value),
        .b_value        (ex_b_value),
        .pc             (ex_pc),
        .valid          (ex_valid),
        .instr          (ex_instr)
    );

    // ========================================================================
    // STAGE 3: EX (forwarding, ALU, flags)
    // ========================================================================
    wire [1:0]  fwd_a_sel, fwd_b_sel;
    wire [7:0]  ex_op_a;                                  // forwarded port-A value
    wire [7:0]  ex_b_fwd;                                 // forwarded port-B value
    wire [7:0]  ex_op_b;                                  // ALU operand B
    wire [7:0]  ex_alu_result;
    wire        ex_alu_zero, ex_alu_carry;

    forwarding_unit FU (
        .ex_ra      (ex_ra),
        .ex_rb      (ex_rb),
        .mem_rd     (mem_rd),
        .mem_reg_we (mem_reg_we),
        .wb_rd      (wb_rd),
        .wb_reg_we  (wb_reg_we),
        .fwd_a_sel  (fwd_a_sel),
        .fwd_b_sel  (fwd_b_sel)
    );

    mux3 FWD_A_MUX (
        .d0  (ex_a_value),
        .d1  (wb_data),
        .d2  (mem_alu_result),
        .sel (fwd_a_sel),
        .y   (ex_op_a)
    );

    mux3 FWD_B_MUX (
        .d0  (ex_b_value),
        .d1  (wb_data),
        .d2  (mem_alu_result),
        .sel (fwd_b_sel),
        .y   (ex_b_fwd)
    );

    mux2 OPERAND_MUX (
        .d0  (ex_b_fwd),                                  // register operand
        .d1  (ex_imm),                                    // imm8 (LDI, ADDI)
        .sel (ex_alu_src_sel),
        .y   (ex_op_b)
    );

    alu ALU (
        .a        (ex_op_a),
        .b        (ex_op_b),
        .alu_ctrl (ex_alu_ctrl),
        .result   (ex_alu_result),
        .carry    (ex_alu_carry),
        .zero     (ex_alu_zero)
    );

    flag_register FLAGS (
        .clk        (clk),
        .rst        (rst),
        .zero_we    (ex_zero_we),
        .carry_we   (ex_carry_we),
        .zero_in    (ex_alu_zero),
        .carry_in   (ex_alu_carry),
        .zero_flag  (zero_flag),
        .carry_flag (carry_flag)
    );

    // ---- EX/MEM pipeline register -------------------------------------------
    wire [7:0]  mem_store_data;
    wire        mem_mem_we, mem_wb_sel;
    wire [7:0]  mem_pc;
    wire        mem_valid;
    wire [15:0] mem_instr;

    ex_mem_register EX_MEM (
        .clk           (clk),
        .rst           (rst),
        .alu_result_in (ex_alu_result),                   // value, or LD/ST address
        .store_data_in (ex_b_fwd),                        // ST data = forwarded rd (port B)
        .rd_in         (ex_rd),
        .reg_we_in     (ex_reg_we),
        .mem_we_in     (ex_mem_we),
        .wb_sel_in     (ex_wb_sel),
        .pc_in         (ex_pc),
        .valid_in      (ex_valid),
        .instr_in      (ex_instr),
        .alu_result    (mem_alu_result),
        .store_data    (mem_store_data),
        .rd            (mem_rd),
        .reg_we        (mem_reg_we),
        .mem_we        (mem_mem_we),
        .wb_sel        (mem_wb_sel),
        .pc            (mem_pc),
        .valid         (mem_valid),
        .instr         (mem_instr)
    );

    // ========================================================================
    // STAGE 4: MEM (data memory)
    // ========================================================================
    wire [7:0]  mem_read_data;
    wire        mem_we_safe = mem_mem_we & ~rst;          // no store during reset

    data_memory DMEM (
        .clk        (clk),
        .address    (mem_alu_result),
        .write_data (mem_store_data),
        .mem_we     (mem_we_safe),
        .read_data  (mem_read_data)
    );

    // ---- MEM/WB pipeline register --------------------------------------------
    wire [7:0]  wb_alu_result, wb_mem_data;
    wire        wb_wb_sel;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [7:0]  wb_pc;                                    // trace only
    wire        wb_valid;                                 // trace only: 1 = retires
    wire [15:0] wb_instr;                                 // trace only
    /* verilator lint_on UNUSEDSIGNAL */

    mem_wb_register MEM_WB (
        .clk           (clk),
        .rst           (rst),
        .alu_result_in (mem_alu_result),
        .mem_data_in   (mem_read_data),
        .rd_in         (mem_rd),
        .reg_we_in     (mem_reg_we),
        .wb_sel_in     (mem_wb_sel),
        .pc_in         (mem_pc),
        .valid_in      (mem_valid),
        .instr_in      (mem_instr),
        .alu_result    (wb_alu_result),
        .mem_data      (wb_mem_data),
        .rd            (wb_rd),
        .reg_we        (wb_reg_we),
        .wb_sel        (wb_wb_sel),
        .pc            (wb_pc),
        .valid         (wb_valid),
        .instr         (wb_instr)
    );

    // ========================================================================
    // STAGE 5: WB (write back)
    // ========================================================================
    mux2 WB_MUX (
        .d0  (wb_alu_result),
        .d1  (wb_mem_data),
        .sel (wb_wb_sel),
        .y   (wb_data)
    );

    // ========================================================================
    // Debug outputs
    // ========================================================================
    assign pc_out      = if_pc;
    assign instr_out   = ex_instr;
    assign alu_out     = ex_alu_result;
    assign wb_data_out = wb_data;
    assign zero_out    = zero_flag;
    assign carry_out   = carry_flag;

endmodule

`default_nettype wire
