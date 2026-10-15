// =============================================================================
// File        : tb_instruction_memory.v
// Module      : tb_instruction_memory   (self-checking testbench)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 8 directed reads of program.mem, one every 10 ns (sampled at
//               t + 5 ns); expected words typed from the program table.
// Part 2      : all 16 addresses compared with a SEPARATE copy of the file
//               read by the testbench itself, plus an X check on every word.
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_instruction_memory;

    reg  [3:0]  address;
    wire [11:0] instruction;
    reg  [11:0] golden [0:15];
    integer     errors = 0, n_dir = 0, n_exh = 0;
    integer     a;

    instruction_memory #(.PROGRAM_FILE("program.mem")) DUT (
        .address(address), .instruction(instruction)
    );

    task dcase;
        input [3:0] ad; input [11:0] e_w; input [8*30:1] note;
        reg ok;
        begin
            address = ad; #5;
            n_dir = n_dir + 1; ok = (instruction === e_w); if (!ok) errors = errors + 1;
            $display("  %t |   %2d    |    %h      |   %h    | %s | %0s",
                     $time - 5, address, instruction, e_w, ok ? "PASS" : "FAIL", note);
            #5;
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_instruction_memory.vcd"); $dumpvars(0, tb_instruction_memory); end
        $display("============================================================================");
        $display(" tb_instruction_memory : self-checking testbench for module instruction_memory");
        $display(" Student               : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado                : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        address = 0; #10;
        $display("\nPART 1: directed reads of program.mem (row t: applied at t, sampled at t + 5 ns)");
        $display("  time | address | instruction | expected | chk  | note");
        $display("  -----+---------+-------------+----------+------+-----");
        dcase(4'd0,  12'h645, "LDI R1, 5");
        dcase(4'd1,  12'h683, "LDI R2, 3");
        dcase(4'd2,  12'h060, "ADD R1, R2");
        dcase(4'd3,  12'h6CA, "LDI R3, 10");
        dcase(4'd4,  12'h470, "XOR R1, R3");
        dcase(4'd5,  12'hA05, "JMP 5");
        dcase(4'd6,  12'hC00, "unused word = NOP");
        dcase(4'd15, 12'hC00, "last word = NOP");

        $display("\nPART 2: all 16 words against the testbench's own copy of program.mem");
        $readmemh("program.mem", golden);
        for (a = 0; a < 16; a = a + 1) begin
            address = a; #1;
            n_exh = n_exh + 1;
            if (instruction !== golden[a] || (^instruction) === 1'bx) begin
                errors = errors + 1;
                $display("  FAIL address %0d: %h, file says %h", a, instruction, golden[a]);
            end
        end
        $display("  %0d addresses compared, no X found", n_exh);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_instruction_memory (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_exh);
        else
            $display("FAILED: tb_instruction_memory (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_exh);
        $finish(0);
    end

endmodule

`default_nettype wire
