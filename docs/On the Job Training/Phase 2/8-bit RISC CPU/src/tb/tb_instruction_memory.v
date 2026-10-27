// =============================================================================
// File        : tb_instruction_memory.v
// Module      : tb_instruction_memory   (self-checking testbench for instruction_memory)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 9 directed reads of program.mem (demo.asm)
// Part 2      : all 256 addresses against the testbench's own copy of the file, plus an X check
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_instruction_memory;
    reg [7:0] address; wire [15:0] instruction; reg [15:0] golden [0:255];
    integer errors = 0, n_dir = 0, n_p2 = 0, a;
    instruction_memory #(.PROGRAM_FILE("program.mem")) DUT (.address(address), .instruction(instruction));
    task dcase; input [7:0] ad; input [15:0] e; input [8*24:1] note;
        reg ok; begin
            address = ad; #5; n_dir = n_dir + 1; ok = (instruction === e); if (!ok) errors = errors + 1;
            $display("  %t |   %3d   |    %h     |   %h   | %s | %0s", $time - 5, address, instruction, e, ok ? "PASS" : "FAIL", note); #5;
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_instruction_memory.vcd"); $dumpvars(0, tb_instruction_memory); end
        $display("============================================================================");
        $display(" tb_instruction_memory : self-checking testbench for module instruction_memory");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        address = 0; #10;
        $display("\nPART 1: directed reads of program.mem (row t: applied at t, sampled at t + 5 ns)");
        $display("  time | address | instruction | expected | chk  | note");
        dcase(8'd0, 16'h8205, "LDI R1, 5");
        dcase(8'd1, 16'h8403, "LDI R2, 3");
        dcase(8'd2, 16'h1650, "ADD R3, R1, R2");
        dcase(8'd3, 16'h2850, "SUB R4, R1, R2");
        dcase(8'd4, 16'h5AE0, "XOR R5, R3, R4");
        dcase(8'd5, 16'h6D40, "SHL R6, R5");
        dcase(8'd6, 16'h9C64, "ADDI R6, 100");
        dcase(8'd7, 16'hF000, "HLT");
        dcase(8'd255, 16'h0000, "last word = NOP");
        $display("\nPART 2: all 256 words against the testbench's own copy of program.mem");
        $readmemh("program.mem", golden, 0, 255);
        for (a = 0; a < 256; a = a + 1) begin
            address = a; #1; n_p2 = n_p2 + 1;
            if (instruction !== golden[a] || (^instruction) === 1'bx) errors = errors + 1;
        end
        $display("  %0d addresses compared, no X found", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_instruction_memory (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_instruction_memory (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
