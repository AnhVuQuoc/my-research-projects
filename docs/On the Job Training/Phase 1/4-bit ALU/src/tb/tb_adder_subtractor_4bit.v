`timescale 1ns / 1ps
// ============================================================================
// tb_adder_subtractor_4bit.v : self checking testbench for adder_subtractor_4bit
// Student : Vu Quoc Anh   Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// Part 1  : six directed cases applied 10 ns apart, printed with the carries
//           and the C and V flags they produce.
// Part 2  : exhaustive self check, all 16 x 16 x 2 = 512 (a, b, sub) inputs.
//           sum and c4 against integer arithmetic, c3 against the carry into
//           bit 3, and c3 ^ c4 against the textbook signed overflow rule.
// Ends with one PASS or FAILED line.
// ============================================================================
module tb_adder_subtractor_4bit;
    reg  [3:0] a, b;
    reg        sub;
    wire [3:0] sum;
    wire       c3, c4;

    adder_subtractor_4bit dut (.a(a), .b(b), .sub(sub), .sum(sum), .c3(c3), .c4(c4));

    integer i, errors;
    reg [3:0] bx;          // b after the conditional inversion (b XOR sub)
    reg [4:0] full;        // 5 bit reference sum
    reg [3:0] low3;        // reference for the carry into bit 3
    reg       v_rule;      // textbook overflow rule

    task show;
        input [3:0] ta, tb_;
        input       ts;
        begin
            a = ta; b = tb_; sub = ts;
            #10;
            $display("  %4d ns | %2d %s %2d | %b %b %b | %b   %b  %b  | C=%b V=%b",
                     $time - 10, a, (sub ? "-" : "+"), b, a, (sub ? ~b : b), sub,
                     sum, c3, c4, c4, c3 ^ c4);
        end
    endtask

    initial begin
        errors = 0;
        $display("============================================================");
        $display(" Student: Vu Quoc Anh    Roll number: SE203519");
        $display(" Project: ALU4    Testbench: tb_adder_subtractor_4bit");
        $display("============================================================");

        $display("Part 1: directed cases (one every 10 ns)");
        $display("  time   | case    | a    b_x  sub | sum  c3 c4 | flags");
        show(4'd5,  4'd3, 1'b0);    // signed overflow: +8 does not fit
        show(4'd5,  4'd3, 1'b1);    // no borrow
        show(4'd3,  4'd5, 1'b1);    // borrow, result -2
        show(4'd15, 4'd1, 1'b0);    // unsigned carry out
        show(4'd8,  4'd1, 1'b1);    // -8 - 1 = -9 does not fit
        show(4'd7,  4'd7, 1'b0);    // 7 + 7 = 14 = -2 signed: overflow

        $display("Part 2: exhaustive self check, 512 cases");
        for (i = 0; i < 512; i = i + 1) begin
            {sub, a, b} = i[8:0];
            #1;
            bx   = sub ? ~b : b;
            full = {1'b0, a} + {1'b0, bx} + sub;
            low3 = {1'b0, a[2:0]} + {1'b0, bx[2:0]} + sub;     // bit 3 = c3
            v_rule = (a[3] == bx[3]) && (full[3] != a[3]);       // same sign in, other sign out
            if (sum !== full[3:0] || c4 !== full[4] || c3 !== low3[3] || (c3 ^ c4) !== v_rule) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("  FAIL sub=%b a=%0d b=%0d : sum=%b c3=%b c4=%b expected sum=%b c3=%b c4=%b",
                             sub, a, b, sum, c3, c4, full[3:0], low3[3], full[4]);
            end
        end
        $display("  512 cases checked, %0d errors", errors);
        if (errors == 0) $display("PASS: tb_adder_subtractor_4bit (Vu Quoc Anh, SE203519), 512 cases, 0 errors");
        else             $display("FAILED: tb_adder_subtractor_4bit, %0d errors", errors);
        $finish;
    end
endmodule
