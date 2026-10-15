`timescale 1ns / 1ps
// ============================================================================
// tb_shifter_4bit.v : self checking testbench for shifter_4bit
// Student : Vu Quoc Anh   Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// Part 1  : all 16 values of a applied 10 ns apart and printed as a table.
// Part 2  : self check of all 16 values using the arithmetic meaning of a
//           shift instead of copying the wiring:
//             SHL : 2a = 16 x shl_out_bit + shl
//             SHR :  a =  2 x shr + shr_out_bit
// Ends with one PASS or FAILED line.
// ============================================================================
module tb_shifter_4bit;
    reg  [3:0] a;
    wire [3:0] shl, shr;
    wire       shl_out_bit, shr_out_bit;
    integer i, errors;

    shifter_4bit dut (.a(a), .shl(shl), .shr(shr),
                      .shl_out_bit(shl_out_bit), .shr_out_bit(shr_out_bit));

    initial begin
        errors = 0;
        $display("============================================================");
        $display(" Student: Vu Quoc Anh    Roll number: SE203519");
        $display(" Project: ALU4    Testbench: tb_shifter_4bit");
        $display("============================================================");

        $display("Part 1: all 16 inputs (one every 10 ns)");
        $display("  time   | a    | shl  out | shr  out");
        for (i = 0; i < 16; i = i + 1) begin
            a = i[3:0];
            #10;
            $display("  %4d ns | %b | %b  %b   | %b  %b", $time - 10, a, shl, shl_out_bit, shr, shr_out_bit);
        end

        $display("Part 2: self check with the arithmetic identities, 16 cases");
        for (i = 0; i < 16; i = i + 1) begin
            a = i[3:0];
            #1;
            if ((2*a) !== (16*shl_out_bit + shl) || a !== (2*shr + shr_out_bit) ||
                shl[0] !== 1'b0 || shr[3] !== 1'b0) begin
                errors = errors + 1;
                $display("  FAIL a=%b", a);
            end
        end
        $display("  16 cases checked, %0d errors", errors);
        if (errors == 0) $display("PASS: tb_shifter_4bit (Vu Quoc Anh, SE203519), 16 cases, 0 errors");
        else             $display("FAILED: tb_shifter_4bit, %0d errors", errors);
        $finish;
    end
endmodule
