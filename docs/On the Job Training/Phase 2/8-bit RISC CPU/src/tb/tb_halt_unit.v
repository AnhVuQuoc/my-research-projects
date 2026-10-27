// =============================================================================
// File        : tb_halt_unit.v
// Module      : tb_halt_unit   (self-checking testbench for halt_unit)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 9 directed cycles; outputs sampled 1 ns before the edge, halted 5 ns after it
// Part 2      : 4000 random cycles against a model of the halt rules
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_halt_unit;
    reg clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end
    reg rst = 1'b1, id_is_hlt = 1'b0, stall = 1'b0, branch_flush = 1'b0;
    wire halted, halt, pc_en, if_id_flush; reg b_halt, b_pcen, b_fl, m_halted, e_halt, e_pcen, e_fl;
    integer errors = 0, n_dir = 0, n_p2 = 0, c, seed = 32'h5E203519;
    halt_unit DUT (.clk(clk), .rst(rst), .id_is_hlt(id_is_hlt), .stall(stall), .branch_flush(branch_flush),
                   .halted(halted), .halt(halt), .pc_en(pc_en), .if_id_flush(if_id_flush));
    task dcycle; input r, h, s, bf; input eh, ep, ef, ehd; input [8*34:1] note;
        reg ok; begin
            rst = r; id_is_hlt = h; stall = s; branch_flush = bf; #4; b_halt = halt; b_pcen = pc_en; b_fl = if_id_flush;
            @(posedge clk); @(negedge clk); n_dir = n_dir + 1;
            ok = (b_halt === eh) && (b_pcen === ep) && (b_fl === ef) && (halted === ehd); if (!ok) errors = errors + 1;
            $display("  %t |  %b   %b   %b   %b  |  %b    %b     %b   |   %b    | %b %b %b %b | %s | %0s", $time - 5, rst,
                     id_is_hlt, stall, branch_flush, b_halt, b_pcen, b_fl, halted, eh, ep, ef, ehd, ok ? "PASS" : "FAIL", note);
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_halt_unit.vcd"); $dumpvars(0, tb_halt_unit); end
        $display("============================================================================");
        $display(" tb_halt_unit : self-checking testbench for module halt_unit");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge; outputs at t-1 ns, halted at t+5 ns)");
        $display("  time | rst hlt st bfl | halt pc_en flush | halted | expected | chk  | note");
        dcycle(1,0,0,0, 0,1,0,0, "reset: running");
        dcycle(0,0,0,0, 0,1,0,0, "normal fetch");
        dcycle(0,0,1,0, 0,0,0,0, "stall: PC holds, no flush");
        dcycle(0,0,0,1, 0,1,1,0, "taken branch: flush IF/ID");
        dcycle(0,1,1,0, 0,0,0,0, "HLT in ID but stalled: not yet");
        dcycle(0,1,0,0, 1,0,1,1, "HLT in ID: freeze PC, flush, set halted");
        dcycle(0,0,0,0, 1,0,1,1, "halted stays 1 (pipeline drains)");
        dcycle(0,0,0,1, 1,0,1,1, "still halted");
        dcycle(1,0,0,0, 1,0,1,0, "reset clears halted");
        $display("\nPART 2: 4000 random cycles against the reference model");
        m_halted = 1'b0;
        for (c = 0; c < 4000; c = c + 1) begin
            rst = (($unsigned($random(seed)) % 50) == 0); id_is_hlt = (($unsigned($random(seed)) % 8) == 0);
            stall = $random(seed); branch_flush = $random(seed); #1;
            e_halt = m_halted | (id_is_hlt & !stall); e_pcen = !stall & !e_halt; e_fl = branch_flush | e_halt;
            n_p2 = n_p2 + 1;
            if (halt !== e_halt || pc_en !== e_pcen || if_id_flush !== e_fl || halted !== m_halted) errors = errors + 1;
            @(posedge clk);
            if (rst) m_halted = 1'b0; else if (id_is_hlt && !stall) m_halted = 1'b1;
            @(negedge clk);
        end
        $display("  %0d random cycles compared", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_halt_unit (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_halt_unit (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
