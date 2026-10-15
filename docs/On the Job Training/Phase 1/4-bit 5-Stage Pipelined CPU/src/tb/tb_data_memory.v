// =============================================================================
// File        : tb_data_memory.v
// Module      : tb_data_memory   (self-checking testbench for data_memory)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Clock       : rising edges at 10, 20, 30 ... ns. Row t: inputs applied at
//               t - 5 ns, read_data sampled at t - 1 ns ("before" the edge)
//               and t + 5 ns ("after"): a write shows only after the edge.
// Part 1      : 8 directed cycles; Part 2: initial-zero check of all 16
//               words + 2000 random cycles against a reference array
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_data_memory;

    reg        clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end

    reg  [3:0] address = 0, write_data = 0;
    reg        mem_we = 1'b0;
    wire [3:0] read_data;
    reg  [3:0] model [0:15];
    reg  [3:0] before;
    integer    errors = 0, n_dir = 0, n_rnd = 0;
    integer    c, i, seed = 32'h5E203519;

    data_memory DUT (.clk(clk), .address(address), .write_data(write_data),
                     .mem_we(mem_we), .read_data(read_data));

    task dcycle;
        input [3:0] ad, wdat; input we_in; input [3:0] e_before, e_after; input [8*32:1] note;
        reg ok;
        begin
            address = ad; write_data = wdat; mem_we = we_in;
            #4; before = read_data;
            @(posedge clk); @(negedge clk);
            n_dir = n_dir + 1; ok = (before === e_before) && (read_data === e_after);
            if (!ok) errors = errors + 1;
            $display("  %t |   %2d    |  %b  |   %b    |  %b  |  %b  |  %b  %b  | %s | %0s",
                     $time - 5, address, write_data, mem_we, before, read_data, e_before, e_after,
                     ok ? "PASS" : "FAIL", note);
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_data_memory.vcd"); $dumpvars(0, tb_data_memory); end
        $display("============================================================================");
        $display(" tb_data_memory : self-checking testbench for module data_memory");
        $display(" Student        : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado         : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge; before = t-1 ns, after = t+5 ns)");
        $display("  time | address | wdata | mem_we | before| after | expected  | chk  | note");
        $display("  -----+---------+-------+--------+-------+-------+-----------+------+-----");
        dcycle(4'd0,  4'b0000, 1'b0, 4'b0000, 4'b0000, "word 0 starts at 0");
        dcycle(4'd3,  4'b1010, 1'b1, 4'b0000, 4'b1010, "STORE: new value after edge");
        dcycle(4'd3,  4'b1111, 1'b0, 4'b1010, 4'b1010, "mem_we = 0: no write");
        dcycle(4'd15, 4'b0110, 1'b1, 4'b0000, 4'b0110, "last word");
        dcycle(4'd3,  4'b0000, 1'b0, 4'b1010, 4'b1010, "LOAD reads word 3");
        dcycle(4'd0,  4'b1111, 1'b1, 4'b0000, 4'b1111, "write word 0");
        dcycle(4'd3,  4'b0001, 1'b1, 4'b1010, 4'b0001, "overwrite word 3");
        dcycle(4'd15, 4'b0000, 1'b0, 4'b0110, 4'b0110, "word 15 kept its value");

        $display("\nPART 2: all words start at 0 (fresh instance), then 2000 random cycles");
        for (i = 0; i < 16; i = i + 1) begin
            n_rnd = n_rnd + 1;
            if (FRESH.mem[i] !== 4'b0000) begin
                errors = errors + 1; $display("  FAIL fresh word %0d = %b", i, FRESH.mem[i]);
            end
        end
        for (i = 0; i < 16; i = i + 1) model[i] = DUT.mem[i];   // continue from Part 1
        for (c = 0; c < 2000; c = c + 1) begin
            address = $random(seed); write_data = $random(seed); mem_we = $random(seed);
            #1;
            n_rnd = n_rnd + 1;
            if (read_data !== model[address]) begin
                errors = errors + 1;
                $display("  FAIL cycle %0d: addr %0d read %b model %b", c, address, read_data, model[address]);
            end
            @(posedge clk);
            if (mem_we) model[address] = write_data;
            @(negedge clk);
        end
        $display("  16 initial words + %0d random cycles compared", n_rnd - 16);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_data_memory (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_rnd);
        else
            $display("FAILED: tb_data_memory (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_rnd);
        $finish(0);
    end

    // a second, never-written instance to prove the power-up value
    wire [3:0] fresh_q;
    data_memory FRESH (.clk(clk), .address(4'd0), .write_data(4'd0), .mem_we(1'b0), .read_data(fresh_q));

endmodule

`default_nettype wire
