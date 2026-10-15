`timescale 1ns / 1ps
// ============================================================================
// tb_logic_unit_4bit.v : self checking testbench for logic_unit_4bit
// Student : Vu Quoc Anh   Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// Part 1  : four directed (a, b) pairs applied 10 ns apart and printed.
// Part 2  : exhaustive self check, all 256 (a, b) pairs, every output bit
//           compared with a bit by bit reference.
// Ends with one PASS or FAILED line.
// ============================================================================
module tb_logic_unit_4bit;
    reg  [3:0] a, b;
    wire [3:0] and_out, or_out, xor_out, not_out;
    integer i, j, errors;

    logic_unit_4bit dut (.a(a), .b(b), .and_out(and_out), .or_out(or_out),
                         .xor_out(xor_out), .not_out(not_out));

    task show;
        input [3:0] ta, tb_;
        begin
            a = ta; b = tb_;
            #10;
            $display("  %4d ns | %b %b | %b    %b   %b    %b",
                     $time - 10, a, b, and_out, or_out, xor_out, not_out);
        end
    endtask

    initial begin
        errors = 0;
        $display("============================================================");
        $display(" Student: Vu Quoc Anh    Roll number: SE203519");
        $display(" Project: ALU4    Testbench: tb_logic_unit_4bit");
        $display("============================================================");

        $display("Part 1: directed cases (one every 10 ns)");
        $display("  time   | a    b    | AND  OR   XOR  NOT a");
        show(4'b1100, 4'b1010);
        show(4'b0000, 4'b1111);
        show(4'b1010, 4'b0101);
        show(4'b0110, 4'b0011);

        $display("Part 2: exhaustive self check, 256 cases");
        for (i = 0; i < 256; i = i + 1) begin
            {a, b} = i[7:0];
            #1;
            for (j = 0; j < 4; j = j + 1) begin
                if (and_out[j] !== (a[j] && b[j]) || or_out[j] !== (a[j] || b[j]) ||
                    xor_out[j] !== (a[j] != b[j]) || not_out[j] !== !a[j]) begin
                    errors = errors + 1;
                    if (errors <= 10) $display("  FAIL a=%b b=%b bit %0d", a, b, j);
                end
            end
        end
        $display("  256 cases checked, %0d errors", errors);
        if (errors == 0) $display("PASS: tb_logic_unit_4bit (Vu Quoc Anh, SE203519), 256 cases, 0 errors");
        else             $display("FAILED: tb_logic_unit_4bit, %0d errors", errors);
        $finish;
    end
endmodule
