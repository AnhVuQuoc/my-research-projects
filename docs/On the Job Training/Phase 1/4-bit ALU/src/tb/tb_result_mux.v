`timescale 1ns / 1ps
// ============================================================================
// tb_result_mux.v : self checking testbench for result_mux
// Student : Vu Quoc Anh   Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// Part 1  : every data input gets a different fixed value, then all 16
//           opcodes are applied 10 ns apart. The printed table shows which
//           source each opcode selects.
// Part 2  : 16 opcodes x 200 random input sets = 3,200 cases. Every data
//           input gets its own random value, so picking the wrong source is
//           detected.
// Ends with one PASS or FAILED line.
// ============================================================================
module tb_result_mux;
    reg  [3:0] opcode;
    reg  [3:0] sum, and_out, or_out, xor_out, not_out, shl, shr, md_hi, md_lo;
    wire [7:0] result;
    reg  [7:0] exp;
    integer op, n, errors, seed;
    reg  [8*24:1] src;     // name of the source the opcode should select

    result_mux dut (.opcode(opcode), .sum(sum), .and_out(and_out), .or_out(or_out),
                    .xor_out(xor_out), .not_out(not_out), .shl(shl), .shr(shr),
                    .md_hi(md_hi), .md_lo(md_lo), .result(result));

    initial begin
        errors = 0; seed = 7;
        $display("============================================================");
        $display(" Student: Vu Quoc Anh    Roll number: SE203519");
        $display(" Project: ALU4    Testbench: tb_result_mux");
        $display("============================================================");

        // distinct marker values: sum=1 and=2 or=3 xor=4 not=5 shl=6 shr=7 hi=8 lo=9
        sum = 4'd1; and_out = 4'd2; or_out = 4'd3; xor_out = 4'd4; not_out = 4'd5;
        shl = 4'd6; shr = 4'd7; md_hi = 4'd8; md_lo = 4'd9;
        $display("Part 1: selection table (inputs: sum=1 and=2 or=3 xor=4 not=5 shl=6 shr=7 hi=8 lo=9)");
        $display("  time    | opcode | result    | selected source");
        for (op = 0; op < 16; op = op + 1) begin
            opcode = op[3:0];
            case (op)
                0:       src = "sum";
                1:       src = "sum (same branch)";
                2:       src = "and_out";
                3:       src = "or_out";
                4:       src = "xor_out";
                5:       src = "not_out";
                6:       src = "shl";
                7:       src = "shr";
                8:       src = "{md_hi, md_lo}";
                9:       src = "{md_hi, md_lo} (same)";
                default: src = "default";
            endcase
            #10;
            $display("  %4d ns |  %b  | %b_%b | %0s", $time - 10, opcode, result[7:4], result[3:0], src);
        end

        $display("Part 2: random self check, 16 opcodes x 200 = 3200 cases");
        for (op = 0; op < 16; op = op + 1) begin
            for (n = 0; n < 200; n = n + 1) begin
                opcode  = op[3:0];
                sum     = $random(seed); and_out = $random(seed); or_out = $random(seed);
                xor_out = $random(seed); not_out = $random(seed); shl    = $random(seed);
                shr     = $random(seed); md_hi   = $random(seed); md_lo  = $random(seed);
                #1;
                if      (op <= 1)  exp = {4'b0, sum};
                else if (op == 2)  exp = {4'b0, and_out};
                else if (op == 3)  exp = {4'b0, or_out};
                else if (op == 4)  exp = {4'b0, xor_out};
                else if (op == 5)  exp = {4'b0, not_out};
                else if (op == 6)  exp = {4'b0, shl};
                else if (op == 7)  exp = {4'b0, shr};
                else if (op <= 9)  exp = {md_hi, md_lo};
                else               exp = 8'd0;
                if (result !== exp) begin
                    errors = errors + 1;
                    if (errors <= 10) $display("  FAIL opcode=%b got %b expected %b", opcode, result, exp);
                end
            end
        end
        $display("  3200 cases checked, %0d errors", errors);
        if (errors == 0) $display("PASS: tb_result_mux (Vu Quoc Anh, SE203519), 3200 cases, 0 errors");
        else             $display("FAILED: tb_result_mux, %0d errors", errors);
        $finish;
    end
endmodule
