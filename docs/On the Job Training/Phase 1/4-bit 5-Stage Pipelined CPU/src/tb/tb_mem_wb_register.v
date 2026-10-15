// =============================================================================
// File        : tb_mem_wb_register.v
// Module      : tb_mem_wb_register   (self-checking testbench for mem_wb_register)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Clock       : rising edges at 10, 20, 30 ... ns. Row t: inputs applied at
//               t - 5 ns, outputs sampled at t + 5 ns (after the edge at t).
// Part 1      : 5 directed cycles; Part 2: 1000 random cycles, 29 bits vs model
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_mem_wb_register;

    reg         clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end

    reg         rst = 1'b1;
    reg  [28:0] in_vec = 29'd0;  // {alu_result, mem_data, rd, reg_we, wb_sel, pc, valid, instr}
    wire [28:0] out_vec;
    localparam [28:0] EMPTY = {4'd0, 4'd0, 2'd0, 2'b00, 4'd0, 1'b0, 12'hC00};
    reg  [28:0] model;
    integer     errors = 0, n_dir = 0, n_rnd = 0;
    integer     c, seed = 32'h5E203519;

    mem_wb_register DUT (
        .clk(clk), .rst(rst),
        .alu_result_in(in_vec[28:25]), .mem_data_in(in_vec[24:21]), .rd_in(in_vec[20:19]),
        .reg_we_in(in_vec[18]), .wb_sel_in(in_vec[17]), .pc_in(in_vec[16:13]),
        .valid_in(in_vec[12]), .instr_in(in_vec[11:0]),
        .alu_result(out_vec[28:25]), .mem_data(out_vec[24:21]), .rd(out_vec[20:19]),
        .reg_we(out_vec[18]), .wb_sel(out_vec[17]), .pc(out_vec[16:13]),
        .valid(out_vec[12]), .instr(out_vec[11:0])
    );

    //               alu   mem   rd    we wbs pc    v     instr
    localparam [28:0] V_ADD  = {4'h8, 4'h0, 2'd1, 2'b10, 4'd2, 1'b1, 12'h060};
    localparam [28:0] V_LOAD = {4'h0, 4'h8, 2'd0, 2'b11, 4'd7, 1'b1, 12'h800};
    localparam [28:0] V_JMP  = {4'h0, 4'h0, 2'd0, 2'b00, 4'd9, 1'b1, 12'hA09};

    task dcycle;
        input r; input [28:0] vin; input [28:0] e_out; input [8*26:1] note;
        reg ok;
        begin
            rst = r; in_vec = vin;
            @(posedge clk); @(negedge clk);
            n_dir = n_dir + 1; ok = (out_vec === e_out); if (!ok) errors = errors + 1;
            $display("  %t |  %b  |  %b  %b  R%0d  %b  %b  %2d %b %h | %s | %0s",
                     $time - 5, rst, out_vec[28:25], out_vec[24:21], out_vec[20:19], out_vec[18],
                     out_vec[17], out_vec[16:13], out_vec[12], out_vec[11:0],
                     ok ? "PASS" : "FAIL", note);
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_mem_wb_register.vcd"); $dumpvars(0, tb_mem_wb_register); end
        $display("============================================================================");
        $display(" tb_mem_wb_register : self-checking testbench for module mem_wb_register");
        $display(" Student            : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado             : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge, sampled at t + 5 ns)");
        $display("  time | rst | alu  mem  rd  we wbs pc v instr | chk  | note");
        $display("  -----+-----+---------------------------------+------+-----");
        dcycle(1'b1, V_ADD,  EMPTY,  "reset: empty slot");
        dcycle(1'b0, V_ADD,  V_ADD,  "ADD retires: R1 = 1000");
        dcycle(1'b0, V_LOAD, V_LOAD, "LOAD retires: mem data");
        dcycle(1'b0, V_JMP,  V_JMP,  "JMP retires: no write");
        dcycle(1'b1, V_LOAD, EMPTY,  "reset wins");

        $display("\nPART 2: 1000 random cycles against the reference model");
        model = EMPTY;
        for (c = 0; c < 1000; c = c + 1) begin
            rst = (($unsigned($random(seed)) % 40) == 0);
            in_vec = $random(seed);
            @(posedge clk);
            model = rst ? EMPTY : in_vec;
            @(negedge clk);
            n_rnd = n_rnd + 1;
            if (out_vec !== model) begin
                errors = errors + 1;
                $display("  FAIL cycle %0d: out %h model %h", c, out_vec, model);
            end
        end
        $display("  %0d random cycles compared", n_rnd);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_mem_wb_register (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_rnd);
        else
            $display("FAILED: tb_mem_wb_register (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_rnd);
        $finish(0);
    end

endmodule

`default_nettype wire
