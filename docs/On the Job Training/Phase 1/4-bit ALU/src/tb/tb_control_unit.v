`timescale 1ns / 1ps
// ============================================================================
// tb_control_unit.v : self checking testbench for control_unit
// Student : Vu Quoc Anh   Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// Part 1  : all 16 opcodes applied 10 ns apart and printed as the decode table.
// Part 2  : self check of all 16 opcodes against an independent case statement
//           written straight from the decode table on paper.
// Ends with one PASS or FAILED line.
// ============================================================================
module tb_control_unit;
    reg  [3:0] opcode;
    wire sub, arith, is_shl, is_shr, is_div, is_muldiv;
    reg  [5:0] exp;     // {sub, arith, is_shl, is_shr, is_div, is_muldiv}
    integer i, errors;

    control_unit dut (.opcode(opcode), .sub(sub), .arith(arith), .is_shl(is_shl),
                      .is_shr(is_shr), .is_div(is_div), .is_muldiv(is_muldiv));

    initial begin
        errors = 0;
        $display("============================================================");
        $display(" Student: Vu Quoc Anh    Roll number: SE203519");
        $display(" Project: ALU4    Testbench: tb_control_unit");
        $display("============================================================");

        $display("Part 1: decode table (one opcode every 10 ns)");
        $display("  time   | opcode | sub arith shl shr div muldiv");
        for (i = 0; i < 16; i = i + 1) begin
            opcode = i[3:0];
            #10;
            $display("  %4d ns |  %b  |  %b    %b    %b   %b   %b    %b",
                     $time - 10, opcode, sub, arith, is_shl, is_shr, is_div, is_muldiv);
        end

        $display("Part 2: self check of all 16 opcodes");
        for (i = 0; i < 16; i = i + 1) begin
            opcode = i[3:0];
            #1;
            case (opcode)
                4'b0000: exp = 6'b010000;   // ADD
                4'b0001: exp = 6'b110000;   // SUB
                4'b0110: exp = 6'b001000;   // SHL
                4'b0111: exp = 6'b000100;   // SHR
                4'b1000: exp = 6'b000001;   // MUL
                4'b1001: exp = 6'b000011;   // DIV
                default: exp = 6'b000000;   // AND OR XOR NOT and unused codes
            endcase
            if ({sub, arith, is_shl, is_shr, is_div, is_muldiv} !== exp) begin
                errors = errors + 1;
                $display("  FAIL opcode=%b", opcode);
            end
        end
        $display("  16 opcodes checked, %0d errors", errors);
        if (errors == 0) $display("PASS: tb_control_unit (Vu Quoc Anh, SE203519), 16 opcodes, 0 errors");
        else             $display("FAILED: tb_control_unit, %0d errors", errors);
        $finish;
    end
endmodule
