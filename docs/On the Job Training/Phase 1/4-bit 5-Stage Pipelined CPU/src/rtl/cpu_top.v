// =============================================================================
// File        : cpu_top.v
// Module      : cpu_top
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Job         : Connects every block into a 5-stage pipeline:
//                 IF  : PC -> instruction memory -> IF/ID (IR)
//                 ID  : decode, register read (bypassed), hazard check,
//                       branch decision -> ID/EX
//                 EX  : forwarding MUXes -> operand MUX -> ALU -> flags
//                       -> EX/MEM
//                 MEM : data memory read / write -> MEM/WB
//                 WB  : WB MUX -> register file write port
//               This file only connects modules; it holds no logic except
//               PC + 1, the instruction field split and one reset gate on
//               the data-memory write enable (data_memory has no rst port,
//               so a STORE caught in MEM by a reset must be blocked here).
//               Signal names start with the stage they belong to:
//               if_, id_, ex_, mem_, wb_. A control signal keeps its plan
//               name after the prefix, so mem_mem_we = mem_we in MEM and
//               wb_wb_sel = wb_sel in WB.
// Parameter   : PROGRAM_FILE  program loaded into instruction_memory
// Ports       :
//   clk               in   clock, rising edge
//   rst               in   synchronous reset (hold for at least 1 edge)
//   pc_out     [3:0]  out  fetch address (PC)                  valid always
//   instr_out  [11:0] out  instruction in EX (C00 = empty)     valid always
//   alu_out    [3:0]  out  ALU result in EX                    valid when EX valid
//   wb_data_out[3:0]  out  value on the register write port    valid when WB writes
//   zero_out          out  stored Zero flag                    valid always
//   carry_out         out  stored Carry flag                   valid always
// Connections : top of the design; instance CPU in tb_cpu
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module cpu_top #(
    parameter PROGRAM_FILE = "program.mem"
)(
    input  wire        clk,
    input  wire        rst,
    output wire [3:0]  pc_out,
    output wire [11:0] instr_out,
    output wire [3:0]  alu_out,
    output wire [3:0]  wb_data_out,
    output wire        zero_out,
    output wire        carry_out
);

    // ------------------------------------------------------------------------
    // Nets that cross stages (declared first so every stage can use them)
    // ------------------------------------------------------------------------
    wire        pc_sel, flush;                   // from CU (ID) to IF
    wire        stall, pc_en, ir_load, id_ex_bubble;  // from HU (ID)
    /* verilator lint_off UNUSEDSIGNAL */        // trace-only nets below
    wire        load_use_stall, flag_stall;      // HU reasons (trace only)
    /* verilator lint_on UNUSEDSIGNAL */
    wire [3:0]  id_imm;                          // branch target (ID) to PC_MUX
    wire        zero_flag, carry_flag;           // FLAGS (EX) to CU (ID)
    wire [3:0]  mem_alu_result;                  // EX/MEM to forwarding
    wire [1:0]  mem_rd;
    wire        mem_reg_we;
    wire [3:0]  wb_data;                         // WB to RF and forwarding
    wire [1:0]  wb_rd;
    wire        wb_reg_we;

    // ========================================================================
    // STAGE 1: IF (fetch)
    // ========================================================================
    wire [3:0]  if_pc;
    wire [3:0]  if_pc_plus_1;
    wire [3:0]  if_pc_next;
    wire [11:0] if_instr;

    assign if_pc_plus_1 = if_pc + 4'd1;          // wraps 15 -> 0

    mux2 PC_MUX (
        .d0  (if_pc_plus_1),
        .d1  (id_imm),                           // target decided in ID
        .sel (pc_sel),
        .y   (if_pc_next)
    );

    program_counter PC (
        .clk     (clk),
        .rst     (rst),
        .pc_en   (pc_en),                        // 0 during a stall
        .pc_next (if_pc_next),
        .pc_out  (if_pc)
    );

    instruction_memory #(.PROGRAM_FILE(PROGRAM_FILE)) IMEM (
        .address     (if_pc),
        .instruction (if_instr)
    );

    // ---- IF/ID pipeline register (the IR) ----------------------------------
    wire [11:0] id_instr;
    wire [3:0]  id_pc;
    wire        id_valid;

    instruction_register IR (
        .clk             (clk),
        .rst             (rst),
        .ir_load         (ir_load),              // 0 during a stall
        .flush           (flush),                // 1 after a taken branch
        .instruction_in  (if_instr),
        .pc_in           (if_pc),
        .instruction_out (id_instr),
        .pc_out          (id_pc),
        .valid_out       (id_valid)
    );

    // ========================================================================
    // STAGE 2: ID (decode, register read, hazard check, branch decision)
    // ========================================================================
    wire [3:0]  id_opcode = id_instr[11:8];
    wire [1:0]  id_rd     = id_instr[7:6];
    wire [1:0]  id_rs     = id_instr[5:4];
    assign      id_imm    = id_instr[3:0];

    wire [2:0]  id_alu_ctrl;
    wire        id_alu_src_sel, id_wb_sel, id_reg_we, id_mem_we;
    wire        id_zero_we, id_carry_we;
    wire        id_uses_rd, id_uses_rs, id_is_jz;
    /* verilator lint_off UNUSEDSIGNAL */
    wire        id_is_jmp;                       // trace only (CU uses it inside)
    /* verilator lint_on UNUSEDSIGNAL */
    wire [3:0]  id_rd_value, id_rs_value;

    control_unit CU (
        .opcode      (id_opcode),
        .zero_flag   (zero_flag),
        .stall       (stall),
        .alu_ctrl    (id_alu_ctrl),
        .alu_src_sel (id_alu_src_sel),
        .wb_sel      (id_wb_sel),
        .reg_we      (id_reg_we),
        .mem_we      (id_mem_we),
        .zero_we     (id_zero_we),
        .carry_we    (id_carry_we),
        .uses_rd     (id_uses_rd),
        .uses_rs     (id_uses_rs),
        .is_jmp      (id_is_jmp),
        .is_jz       (id_is_jz),
        .pc_sel      (pc_sel),
        .flush       (flush)
    );

    register_file RF (
        .clk (clk),
        .rst (rst),
        .ra  (id_rd),                            // port A reads Rd
        .rb  (id_rs),                            // port B reads Rs
        .wa  (wb_rd),                            // written by WB
        .wd  (wb_data),
        .we  (wb_reg_we),
        .qa  (id_rd_value),
        .qb  (id_rs_value)
    );

    // ---- ID/EX outputs (declared here because HU needs some of them) -------
    wire [2:0]  ex_alu_ctrl;
    wire        ex_alu_src_sel, ex_wb_sel, ex_reg_we, ex_mem_we;
    wire        ex_zero_we, ex_carry_we;
    wire [1:0]  ex_rd, ex_rs;
    wire [3:0]  ex_imm, ex_rd_value, ex_rs_value, ex_pc;
    wire        ex_valid;
    wire [11:0] ex_instr;

    hazard_unit HU (
        .id_rd          (id_rd),
        .id_rs          (id_rs),
        .id_uses_rd     (id_uses_rd),
        .id_uses_rs     (id_uses_rs),
        .id_is_jz       (id_is_jz),
        .ex_rd          (ex_rd),
        .ex_reg_we      (ex_reg_we),
        .ex_wb_sel      (ex_wb_sel),
        .ex_zero_we     (ex_zero_we),
        .load_use_stall (load_use_stall),
        .flag_stall     (flag_stall),
        .stall          (stall),
        .pc_en          (pc_en),
        .ir_load        (ir_load),
        .id_ex_bubble   (id_ex_bubble)
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
        .rs_in          (id_rs),
        .imm_in         (id_imm),
        .rd_value_in    (id_rd_value),
        .rs_value_in    (id_rs_value),
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
        .rs             (ex_rs),
        .imm            (ex_imm),
        .rd_value       (ex_rd_value),
        .rs_value       (ex_rs_value),
        .pc             (ex_pc),
        .valid          (ex_valid),
        .instr          (ex_instr)
    );

    // ========================================================================
    // STAGE 3: EX (forwarding, ALU, flags)
    // ========================================================================
    wire [1:0]  fwd_a_sel, fwd_b_sel;
    wire [3:0]  ex_op_a;                         // forwarded Rd value
    wire [3:0]  ex_rs_fwd;                       // forwarded Rs value
    wire [3:0]  ex_op_b;                         // ALU operand B
    wire [3:0]  ex_alu_result;
    wire        ex_alu_zero, ex_alu_carry;

    forwarding_unit FU (
        .ex_rd      (ex_rd),
        .ex_rs      (ex_rs),
        .mem_rd     (mem_rd),
        .mem_reg_we (mem_reg_we),
        .wb_rd      (wb_rd),
        .wb_reg_we  (wb_reg_we),
        .fwd_a_sel  (fwd_a_sel),
        .fwd_b_sel  (fwd_b_sel)
    );

    mux3 FWD_A_MUX (
        .d0  (ex_rd_value),                      // `FWD_ID
        .d1  (wb_data),                          // `FWD_WB
        .d2  (mem_alu_result),                   // `FWD_MEM
        .sel (fwd_a_sel),
        .y   (ex_op_a)
    );

    mux3 FWD_B_MUX (
        .d0  (ex_rs_value),
        .d1  (wb_data),
        .d2  (mem_alu_result),
        .sel (fwd_b_sel),
        .y   (ex_rs_fwd)
    );

    mux2 OPERAND_MUX (
        .d0  (ex_rs_fwd),                        // register operand
        .d1  (ex_imm),                           // immediate / address
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

    // ---- EX/MEM pipeline register ------------------------------------------
    wire [3:0]  mem_store_data;
    wire        mem_mem_we, mem_wb_sel;
    wire [3:0]  mem_pc;
    wire        mem_valid;
    wire [11:0] mem_instr;

    ex_mem_register EX_MEM (
        .clk           (clk),
        .rst           (rst),
        .alu_result_in (ex_alu_result),
        .store_data_in (ex_op_a),                // STORE writes the forwarded Rd
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
    wire [3:0]  mem_read_data;
    wire        mem_we_safe = mem_mem_we & ~rst;  // no store during reset

    data_memory DMEM (
        .clk        (clk),
        .address    (mem_alu_result),
        .write_data (mem_store_data),
        .mem_we     (mem_we_safe),
        .read_data  (mem_read_data)
    );

    // ---- MEM/WB pipeline register ------------------------------------------
    wire [3:0]  wb_alu_result, wb_mem_data;
    wire        wb_wb_sel;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [3:0]  wb_pc;                           // trace only: retired address
    wire        wb_valid;                        // trace only: 1 = instruction retires
    wire [11:0] wb_instr;                        // trace only
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
    // wb_data, wb_rd and wb_reg_we go to the RF write port (ID section) and
    // to the forwarding MUXes (EX section).

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
