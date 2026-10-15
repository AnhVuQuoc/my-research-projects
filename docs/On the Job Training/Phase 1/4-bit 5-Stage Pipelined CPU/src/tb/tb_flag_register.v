// =============================================================================
// File        : tb_flag_register.v
// Module      : tb_flag_register   (self-checking testbench for flag_register)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Clock       : rising edges at 10, 20, 30 ... ns. Row t: inputs applied at
//               t - 5 ns, flags sampled at t + 5 ns (after the edge at t).
// Part 1      : 7 directed cycles (named after the instruction that would
//               drive them); Part 2: 1000 random cycles vs a model
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_flag_register;

    reg  clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end

    reg  rst = 1'b1, zero_we = 1'b0, carry_we = 1'b0, zero_in = 1'b0, carry_in = 1'b0;
    wire zero_flag, carry_flag;
    reg  mz, mc;
    integer errors = 0, n_dir = 0, n_rnd = 0;
    integer c, seed = 32'h5E203519;

    flag_register DUT (.clk(clk), .rst(rst), .zero_we(zero_we), .carry_we(carry_we),
                       .zero_in(zero_in), .carry_in(carry_in),
                       .zero_flag(zero_flag), .carry_flag(carry_flag));

    task dcycle;
        input r, zwe, cwe, zi, ci, e_z, e_c; input [8*32:1] note;
        reg ok;
        begin
            rst = r; zero_we = zwe; carry_we = cwe; zero_in = zi; carry_in = ci;
            @(posedge clk); @(negedge clk);
            n_dir = n_dir + 1; ok = (zero_flag === e_z) && (carry_flag === e_c);
            if (!ok) errors = errors + 1;
            $display("  %t |  %b  |  %b   %b  |  %b   %b  |  %b  %b  |  %b  %b  | %s | %0s",
                     $time - 5, rst, zero_we, carry_we, zero_in, carry_in, zero_flag, carry_flag,
                     e_z, e_c, ok ? "PASS" : "FAIL", note);
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_flag_register.vcd"); $dumpvars(0, tb_flag_register); end
        $display("============================================================================");
        $display(" tb_flag_register : self-checking testbench for module flag_register");
        $display(" Student          : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado           : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge, sampled at t + 5 ns)");
        $display("  time | rst | zwe cwe | z_in c_in | Z  C  | exp   | chk  | note");
        $display("  -----+-----+---------+-----------+-------+-------+------+-----");
        dcycle(1'b1,1'b0,1'b0,1'b1,1'b1, 1'b0,1'b0, "reset clears both");
        dcycle(1'b0,1'b1,1'b0,1'b1,1'b1, 1'b1,1'b0, "XOR -> 0: Zero only");
        dcycle(1'b0,1'b1,1'b1,1'b0,1'b1, 1'b0,1'b1, "ADD 15+2: both");
        dcycle(1'b0,1'b0,1'b0,1'b1,1'b0, 1'b0,1'b1, "LDI: no enable, hold");
        dcycle(1'b0,1'b0,1'b1,1'b1,1'b0, 1'b0,1'b0, "carry_we only");
        dcycle(1'b0,1'b1,1'b1,1'b1,1'b1, 1'b1,1'b1, "SUB 7-7: Z = 1, C = 1");
        dcycle(1'b1,1'b1,1'b1,1'b0,1'b0, 1'b0,1'b0, "reset wins over enables");

        $display("\nPART 2: 1000 random cycles against the reference model");
        mz = 1'b0; mc = 1'b0;
        for (c = 0; c < 1000; c = c + 1) begin
            rst = (($unsigned($random(seed)) % 40) == 0);
            zero_we = $random(seed); carry_we = $random(seed);
            zero_in = $random(seed); carry_in = $random(seed);
            @(posedge clk);
            if (rst) begin mz = 1'b0; mc = 1'b0; end
            else begin if (zero_we) mz = zero_in; if (carry_we) mc = carry_in; end
            @(negedge clk);
            n_rnd = n_rnd + 1;
            if (zero_flag !== mz || carry_flag !== mc) begin
                errors = errors + 1;
                $display("  FAIL cycle %0d: Z=%b/%b C=%b/%b", c, zero_flag, mz, carry_flag, mc);
            end
        end
        $display("  %0d random cycles compared", n_rnd);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_flag_register (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_rnd);
        else
            $display("FAILED: tb_flag_register (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_rnd);
        $finish(0);
    end

endmodule

`default_nettype wire
