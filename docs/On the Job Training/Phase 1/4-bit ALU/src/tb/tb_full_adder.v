`timescale 1ns / 1ps
// ============================================================================
// tb_full_adder.v : self checking testbench for full_adder
// Student : Vu Quoc Anh   Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// Part 1  : all 8 input rows applied 10 ns apart and printed as the truth
//           table (time stamps match the waveform).
// Part 2  : self check of all 8 rows against two independent references:
//           the integer sum a + b + cin and the Boolean equations.
// Ends with one PASS or FAILED line.
// ============================================================================
module tb_full_adder;
    reg  a, b, cin;
    wire sum, cout;
    integer i, errors;
    reg [1:0] exp;

    full_adder dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    initial begin
        errors = 0;
        $display("============================================================");
        $display(" Student: Vu Quoc Anh    Roll number: SE203519");
        $display(" Project: ALU4    Testbench: tb_full_adder");
        $display("============================================================");

        $display("Part 1: truth table (one row every 10 ns)");
        $display("  time   | a b cin | sum cout");
        for (i = 0; i < 8; i = i + 1) begin
            {a, b, cin} = i[2:0];
            #10;
            $display("  %4d ns | %b %b  %b  |  %b   %b", $time - 10, a, b, cin, sum, cout);
        end

        $display("Part 2: self check of all 8 rows");
        for (i = 0; i < 8; i = i + 1) begin
            {a, b, cin} = i[2:0];
            #1;
            exp = a + b + cin;                                  // arithmetic reference
            if ({cout, sum} !== exp ||
                sum  !== (a ^ b ^ cin) ||                       // Boolean reference
                cout !== ((a & b) | (cin & (a ^ b)))) begin
                errors = errors + 1;
                $display("  FAIL a=%b b=%b cin=%b : sum=%b cout=%b", a, b, cin, sum, cout);
            end
        end
        $display("  8 rows checked, %0d errors", errors);
        if (errors == 0) $display("PASS: tb_full_adder (Vu Quoc Anh, SE203519), 8 cases, 0 errors");
        else             $display("FAILED: tb_full_adder, %0d errors", errors);
        $finish;
    end
endmodule
