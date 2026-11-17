// =============================================================================
// File        : tb_forwarding_unit.v
// Module      : tb_forwarding_unit   (self-checking testbench for forwarding_unit)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 9 directed situations, 1 every 10 ns
// Part 2      : exhaustive: all 2^14 = 16384 input combinations vs a newest-writer-first reference
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_forwarding_unit;
    reg [2:0] ex_ra, ex_rb, mem_rd, wb_rd; reg mem_reg_we, wb_reg_we; wire [1:0] fwd_a_sel, fwd_b_sel;
    integer errors = 0, n_dir = 0, n_p2 = 0, v;
    forwarding_unit DUT (.ex_ra(ex_ra), .ex_rb(ex_rb), .mem_rd(mem_rd), .mem_reg_we(mem_reg_we), .wb_rd(wb_rd),
                         .wb_reg_we(wb_reg_we), .fwd_a_sel(fwd_a_sel), .fwd_b_sel(fwd_b_sel));
    function [1:0] ref_sel; input [2:0] src;
        begin ref_sel = 2'b00; if (wb_reg_we && wb_rd == src) ref_sel = 2'b01; if (mem_reg_we && mem_rd == src) ref_sel = 2'b10; end
    endfunction
    task dcase; input [2:0] a, b, mr; input mw; input [2:0] wr; input ww; input [1:0] ea, eb; input [8*36:1] note;
        reg ok; begin
            ex_ra = a; ex_rb = b; mem_rd = mr; mem_reg_we = mw; wb_rd = wr; wb_reg_we = ww; #5; n_dir = n_dir + 1;
            ok = (fwd_a_sel === ea) && (fwd_b_sel === eb); if (!ok) errors = errors + 1;
            $display("  %t | R%0d R%0d | R%0d %b | R%0d %b |  %b    %b  |  %b    %b  | %s | %0s", $time - 5, ex_ra, ex_rb,
                     mem_rd, mem_reg_we, wb_rd, wb_reg_we, fwd_a_sel, fwd_b_sel, ea, eb, ok ? "PASS" : "FAIL", note); #5;
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_forwarding_unit.vcd"); $dumpvars(0, tb_forwarding_unit); end
        $display("============================================================================");
        $display(" tb_forwarding_unit : self-checking testbench for module forwarding_unit");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        {ex_ra, ex_rb, mem_rd, mem_reg_we, wb_rd, wb_reg_we} = 14'd0; #10;
        $display("\nPART 1: directed situations (row t: applied at t, sampled at t + 5 ns)");
        $display("  time | EX ra rb | MEM rd we | WB rd we | sel A sel B | exp A exp B | chk  | note");
        dcase(3'd1,3'd2, 3'd3,1, 3'd4,1, 2'b00,2'b00, "no match: both from register file");
        dcase(3'd1,3'd2, 3'd1,1, 3'd4,1, 2'b10,2'b00, "A matches MEM (distance 1)");
        dcase(3'd1,3'd2, 3'd3,1, 3'd1,1, 2'b01,2'b00, "A matches WB (distance 2)");
        dcase(3'd1,3'd2, 3'd1,1, 3'd1,1, 2'b10,2'b00, "A matches both: MEM (newest) wins");
        dcase(3'd1,3'd2, 3'd1,0, 3'd4,0, 2'b00,2'b00, "match but no write (ST, branch)");
        dcase(3'd1,3'd2, 3'd2,1, 3'd4,1, 2'b00,2'b10, "B matches MEM");
        dcase(3'd1,3'd2, 3'd5,1, 3'd2,1, 2'b00,2'b01, "B matches WB");
        dcase(3'd6,3'd6, 3'd6,1, 3'd6,1, 2'b10,2'b10, "ADD R7,R6,R6 after 2 writes to R6");
        dcase(3'd0,3'd7, 3'd7,1, 3'd0,1, 2'b01,2'b10, "A from WB, B from MEM together");
        $display("\nPART 2: exhaustive check (16384 cases)");
        for (v = 0; v < 16384; v = v + 1) begin
            {ex_ra, ex_rb, mem_rd, mem_reg_we, wb_rd, wb_reg_we} = v; #1; n_p2 = n_p2 + 1;
            if (fwd_a_sel !== ref_sel(ex_ra) || fwd_b_sel !== ref_sel(ex_rb)) errors = errors + 1;
        end
        $display("  %0d exhaustive cases compared", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_forwarding_unit (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_forwarding_unit (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
