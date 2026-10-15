`timescale 1ns / 1ps
// ============================================================================
// tb_flag_unit.v : self checking testbench for flag_unit
// Student : Vu Quoc Anh   Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// Part 1  : seven directed cases applied 10 ns apart. Each one feeds the
//           flag unit the inputs a real operation would produce (for example
//           ADD 5 + 3 gives result 0000_1000, c3 = 1, c4 = 0).
// Part 2  : exhaustive self check over all 16 input bits (8 result bits +
//           8 control and carry bits) = 65,536 cases, compared with a
//           reference written from the flag specification.
// Ends with one PASS or FAILED line.
// ============================================================================
module tb_flag_unit;
    reg  [7:0] result;
    reg        arith, is_shl, is_shr, is_muldiv, c3, c4, shl_out_bit, shr_out_bit;
    wire       carry, zero, overflow, negative;
    reg        e_c, e_z, e_v, e_n;
    integer i, errors;

    flag_unit dut (.result(result), .arith(arith), .is_shl(is_shl), .is_shr(is_shr),
                   .is_muldiv(is_muldiv), .c3(c3), .c4(c4),
                   .shl_out_bit(shl_out_bit), .shr_out_bit(shr_out_bit),
                   .carry(carry), .zero(zero), .overflow(overflow), .negative(negative));

    // apply one case: {arith, is_shl, is_shr, is_muldiv, c3, c4, shl_out_bit, shr_out_bit}
    task show;
        input [8*10:1] name;
        input [7:0] r;
        input [7:0] ctl;
        begin
            result = r;
            {arith, is_shl, is_shr, is_muldiv, c3, c4, shl_out_bit, shr_out_bit} = ctl;
            #10;
            $display("  %4d ns | %s | %b_%b |  %b  %b  %b  %b |  %b  %b |  %b  %b | %b %b %b %b",
                     $time - 10, name, result[7:4], result[3:0], arith, is_shl, is_shr, is_muldiv,
                     c3, c4, shl_out_bit, shr_out_bit, carry, zero, overflow, negative);
        end
    endtask

    initial begin
        errors = 0;
        $display("============================================================");
        $display(" Student: Vu Quoc Anh    Roll number: SE203519");
        $display(" Project: ALU4    Testbench: tb_flag_unit");
        $display("============================================================");

        $display("Part 1: directed cases (one every 10 ns)");
        $display("  (ar = arith, sl = is_shl, sr = is_shr, md = is_muldiv, so = shl_out_bit, ro = shr_out_bit)");
        $display("  time    | case       | result    | ar sl sr md | c3 c4 | so ro | C Z V N");
        show("ADD 5+3   ", 8'b0000_1000, 8'b1000_1000);
        show("SUB 5-5   ", 8'b0000_0000, 8'b1000_1100);
        show("SUB 3-5   ", 8'b0000_1110, 8'b1000_0000);
        show("SHL 1011  ", 8'b0000_0110, 8'b0100_0010);
        show("SHR 0001  ", 8'b0000_0000, 8'b0010_0001);
        show("MUL 15x15 ", 8'b1110_0001, 8'b0001_0000);
        show("AND 0&0   ", 8'b0000_0000, 8'b0000_0000);

        $display("Part 2: exhaustive self check, 65536 cases");
        for (i = 0; i < 65536; i = i + 1) begin
            {result, arith, is_shl, is_shr, is_muldiv, c3, c4, shl_out_bit, shr_out_bit} = i[15:0];
            #1;
            e_c = 1'b0;                                  // reference, one flag at a time
            if (arith)  e_c = e_c | c4;
            if (is_shl) e_c = e_c | shl_out_bit;
            if (is_shr) e_c = e_c | shr_out_bit;
            e_v = arith ? (c3 != c4) : 1'b0;
            e_z = (result == 8'd0);
            e_n = is_muldiv ? 1'b0 : result[3];
            if (carry !== e_c || zero !== e_z || overflow !== e_v || negative !== e_n) begin
                errors = errors + 1;
                if (errors <= 10) $display("  FAIL input=%b got CZVN=%b%b%b%b expected %b%b%b%b",
                                           i[15:0], carry, zero, overflow, negative, e_c, e_z, e_v, e_n);
            end
        end
        $display("  65536 cases checked, %0d errors", errors);
        if (errors == 0) $display("PASS: tb_flag_unit (Vu Quoc Anh, SE203519), 65536 cases, 0 errors");
        else             $display("FAILED: tb_flag_unit, %0d errors", errors);
        $finish;
    end
endmodule
