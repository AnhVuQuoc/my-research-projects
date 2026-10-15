// =============================================================================
// File        : tb_instruction_register.v
// Module      : tb_instruction_register   (self-checking testbench, IF/ID)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Clock       : rising edges at 10, 20, 30 ... ns. Row t: inputs applied at
//               t - 5 ns, outputs sampled at t + 5 ns (after the edge at t).
// Part 1      : 9 directed cycles; Part 2: 1000 random cycles vs a model
//               (priority: rst/flush > ir_load > hold)
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_instruction_register;

    reg         clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end

    reg         rst = 1'b1, ir_load = 1'b0, flush = 1'b0;
    reg  [11:0] instruction_in = 12'h000;
    reg  [3:0]  pc_in = 4'd0;
    wire [11:0] instruction_out;
    wire [3:0]  pc_out;
    wire        valid_out;
    reg  [16:0] model;                       // {instruction, pc, valid}
    integer     errors = 0, n_dir = 0, n_rnd = 0;
    integer     c, seed = 32'h5E203519;

    instruction_register DUT (
        .clk(clk), .rst(rst), .ir_load(ir_load), .flush(flush),
        .instruction_in(instruction_in), .pc_in(pc_in),
        .instruction_out(instruction_out), .pc_out(pc_out), .valid_out(valid_out)
    );

    task dcycle;
        input r, ld, fl; input [11:0] ins; input [3:0] pci;
        input [11:0] e_ins; input [3:0] e_pc; input e_v; input [8*30:1] note;
        reg ok;
        begin
            rst = r; ir_load = ld; flush = fl; instruction_in = ins; pc_in = pci;
            @(posedge clk); @(negedge clk);
            n_dir = n_dir + 1;
            ok = (instruction_out === e_ins) && (pc_out === e_pc) && (valid_out === e_v);
            if (!ok) errors = errors + 1;
            $display("  %t |  %b   %b   %b  | %h  %2d |  %h   %2d   %b  | %h %2d %b | %s | %0s",
                     $time - 5, rst, ir_load, flush, instruction_in, pc_in, instruction_out, pc_out,
                     valid_out, e_ins, e_pc, e_v, ok ? "PASS" : "FAIL", note);
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_instruction_register.vcd"); $dumpvars(0, tb_instruction_register); end
        $display("============================================================================");
        $display(" tb_instruction_register : self-checking testbench for module instruction_register");
        $display(" Student                 : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado                  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge, sampled at t + 5 ns)");
        $display("  time | rst ld fl | in   pc | out  pc  v | expected  | chk  | note");
        $display("  -----+-----------+---------+------------+-----------+------+-----");
        dcycle(1'b1,1'b1,1'b0,12'h645,4'd0, 12'hC00,4'd0,1'b0, "reset: empty slot");
        dcycle(1'b0,1'b1,1'b0,12'h645,4'd0, 12'h645,4'd0,1'b1, "load LDI R1,5");
        dcycle(1'b0,1'b1,1'b0,12'h683,4'd1, 12'h683,4'd1,1'b1, "load next word");
        dcycle(1'b0,1'b0,1'b0,12'h060,4'd2, 12'h683,4'd1,1'b1, "ir_load = 0: hold (stall)");
        dcycle(1'b0,1'b1,1'b0,12'h060,4'd2, 12'h060,4'd2,1'b1, "load after the stall");
        dcycle(1'b0,1'b1,1'b1,12'h6CA,4'd3, 12'hC00,4'd0,1'b0, "flush wins over load");
        dcycle(1'b0,1'b0,1'b0,12'h470,4'd4, 12'hC00,4'd0,1'b0, "hold keeps the bubble");
        dcycle(1'b0,1'b1,1'b0,12'h470,4'd4, 12'h470,4'd4,1'b1, "load again");
        dcycle(1'b1,1'b1,1'b0,12'hA05,4'd5, 12'hC00,4'd0,1'b0, "reset wins over load");

        $display("\nPART 2: 1000 random cycles against the reference model");
        model = {12'hC00, 4'd0, 1'b0};
        for (c = 0; c < 1000; c = c + 1) begin
            rst   = (($unsigned($random(seed)) % 40) == 0);
            flush = (($unsigned($random(seed)) % 6) == 0);
            ir_load = $random(seed); instruction_in = $random(seed); pc_in = $random(seed);
            @(posedge clk);
            if (rst || flush) model = {12'hC00, 4'd0, 1'b0};
            else if (ir_load) model = {instruction_in, pc_in, 1'b1};
            @(negedge clk);
            n_rnd = n_rnd + 1;
            if ({instruction_out, pc_out, valid_out} !== model) begin
                errors = errors + 1;
                $display("  FAIL cycle %0d: out=%h/%0d/%b model=%h/%0d/%b", c, instruction_out, pc_out,
                         valid_out, model[16:5], model[4:1], model[0]);
            end
        end
        $display("  %0d random cycles compared", n_rnd);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_instruction_register (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_rnd);
        else
            $display("FAILED: tb_instruction_register (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_rnd);
        $finish(0);
    end

endmodule

`default_nettype wire
