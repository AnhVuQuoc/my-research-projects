// =============================================================================
// File        : tb_data_memory.v
// Module      : tb_data_memory   (self-checking testbench for data_memory)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 8 directed cycles; read_data 1 ns before and 5 ns after the edge
// Part 2      : power-up value of all 256 words + 4000 random cycles vs an array model
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_data_memory;
    reg clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end
    reg [7:0] address = 0, write_data = 0; reg mem_we = 0; wire [7:0] read_data; reg [7:0] model [0:255]; reg [7:0] before;
    integer errors = 0, n_dir = 0, n_p2 = 0, c, i, seed = 32'h5E203519;
    data_memory DUT (.clk(clk), .address(address), .write_data(write_data), .mem_we(mem_we), .read_data(read_data));
    wire [7:0] fresh_q;
    data_memory FRESH (.clk(clk), .address(8'd0), .write_data(8'd0), .mem_we(1'b0), .read_data(fresh_q));
    task dcycle; input [7:0] ad, wd; input we_in; input [7:0] eb, ea; input [8*30:1] note;
        reg ok; begin
            address = ad; write_data = wd; mem_we = we_in; #4; before = read_data; @(posedge clk); @(negedge clk);
            n_dir = n_dir + 1; ok = (before === eb) && (read_data === ea); if (!ok) errors = errors + 1;
            $display("  %t |   %h    |  %h   |   %b    |  %h   |  %h   |  %h %h  | %s | %0s", $time - 5, address, write_data,
                     mem_we, before, read_data, eb, ea, ok ? "PASS" : "FAIL", note);
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_data_memory.vcd"); $dumpvars(0, tb_data_memory); end
        $display("============================================================================");
        $display(" tb_data_memory : self-checking testbench for module data_memory");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge; before = t-1 ns, after = t+5 ns)");
        $display("  time | address | wdata | mem_we | before | after | expected | chk  | note");
        dcycle(8'h00, 8'h00, 0, 8'h00, 8'h00, "word 00 starts at 0");
        dcycle(8'h80, 8'h5A, 1, 8'h00, 8'h5A, "ST: new value after the edge");
        dcycle(8'h80, 8'hFF, 0, 8'h5A, 8'h5A, "mem_we = 0: no write");
        dcycle(8'hFF, 8'h66, 1, 8'h00, 8'h66, "last word (255)");
        dcycle(8'h80, 8'h00, 0, 8'h5A, 8'h5A, "LD reads word 80");
        dcycle(8'h00, 8'hB4, 1, 8'h00, 8'hB4, "write word 00");
        dcycle(8'h80, 8'h01, 1, 8'h5A, 8'h01, "overwrite word 80");
        dcycle(8'hFF, 8'h00, 0, 8'h66, 8'h66, "word FF kept its value");
        $display("\nPART 2: all 256 words start at 0 (fresh instance), then 4000 random cycles");
        for (i = 0; i < 256; i = i + 1) begin n_p2 = n_p2 + 1; if (FRESH.mem[i] !== 8'h00) errors = errors + 1; end
        for (i = 0; i < 256; i = i + 1) model[i] = DUT.mem[i];
        for (c = 0; c < 4000; c = c + 1) begin
            address = $random(seed); write_data = $random(seed); mem_we = $random(seed); #1; n_p2 = n_p2 + 1;
            if (read_data !== model[address]) errors = errors + 1;
            @(posedge clk); if (mem_we) model[address] = write_data; @(negedge clk);
        end
        $display("  256 initial words + %0d random cycles compared", n_p2 - 256);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_data_memory (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_data_memory (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
