// =============================================================================
// File        : tb_forwarding_unit.v
// Module      : tb_forwarding_unit   (self-checking testbench for forwarding_unit)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 9 directed situations, one every 10 ns (sampled at t + 5 ns)
// Part 2      : exhaustive: all 2^10 = 1024 input combinations against a
//               reference that searches "newest writer first".
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_forwarding_unit;

    reg  [1:0] ex_rd, ex_rs, mem_rd, wb_rd;
    reg        mem_reg_we, wb_reg_we;
    wire [1:0] fwd_a_sel, fwd_b_sel;
    integer    errors = 0, n_dir = 0, n_exh = 0;
    integer    v;

    forwarding_unit DUT (
        .ex_rd(ex_rd), .ex_rs(ex_rs), .mem_rd(mem_rd), .mem_reg_we(mem_reg_we),
        .wb_rd(wb_rd), .wb_reg_we(wb_reg_we), .fwd_a_sel(fwd_a_sel), .fwd_b_sel(fwd_b_sel)
    );

    // reference: look at the stages from newest (MEM) to oldest (WB)
    function [1:0] ref_sel; input [1:0] src;
        begin
            ref_sel = 2'b00;                                  // register file
            if (wb_reg_we  && wb_rd  == src) ref_sel = 2'b01; // older writer
            if (mem_reg_we && mem_rd == src) ref_sel = 2'b10; // newer writer overrides
        end
    endfunction

    function [8*3:1] sname; input [1:0] s;
        case (s) 2'b00: sname = "ID "; 2'b01: sname = "WB "; 2'b10: sname = "MEM"; default: sname = "?? "; endcase
    endfunction

    task dcase;
        input [1:0] erd, ers, mrd; input mwe; input [1:0] wrd; input wwe;
        input [1:0] e_a, e_b; input [8*36:1] note;
        reg ok;
        begin
            ex_rd = erd; ex_rs = ers; mem_rd = mrd; mem_reg_we = mwe; wb_rd = wrd; wb_reg_we = wwe;
            #5;
            n_dir = n_dir + 1;
            ok = (fwd_a_sel === e_a) && (fwd_b_sel === e_b);
            if (!ok) errors = errors + 1;
            $display("  %t | R%0d  R%0d | R%0d   %b | R%0d  %b | %s   %s  | %s   %s | %s | %0s",
                     $time - 5, ex_rd, ex_rs, mem_rd, mem_reg_we, wb_rd, wb_reg_we,
                     sname(fwd_a_sel), sname(fwd_b_sel), sname(e_a), sname(e_b),
                     ok ? "PASS" : "FAIL", note);
            #5;
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_forwarding_unit.vcd"); $dumpvars(0, tb_forwarding_unit); end
        $display("============================================================================");
        $display(" tb_forwarding_unit : self-checking testbench for module forwarding_unit");
        $display(" Student            : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado             : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        {ex_rd, ex_rs, mem_rd, mem_reg_we, wb_rd, wb_reg_we} = 10'd0;
        #10;
        $display("\nPART 1: directed situations (row t: applied at t, sampled at t + 5 ns)");
        $display("  time | EX rd rs | MEM rd we | WB rd we | sel A sel B | exp A exp B | chk  | note");
        $display("  -----+----------+-----------+----------+-------------+-------------+------+-----");
        //    EX rd rs     MEM rd we     WB rd we      A      B
        dcase(2'd1, 2'd2, 2'd3, 1'b1, 2'd0, 1'b1, 2'b00, 2'b00, "no match: both from register file");
        dcase(2'd1, 2'd2, 2'd1, 1'b1, 2'd0, 1'b1, 2'b10, 2'b00, "A matches MEM (distance 1)");
        dcase(2'd1, 2'd2, 2'd3, 1'b1, 2'd1, 1'b1, 2'b01, 2'b00, "A matches WB (distance 2)");
        dcase(2'd1, 2'd2, 2'd1, 1'b1, 2'd1, 1'b1, 2'b10, 2'b00, "A matches both: newest (MEM) wins");
        dcase(2'd1, 2'd2, 2'd1, 1'b0, 2'd0, 1'b0, 2'b00, 2'b00, "match but MEM does not write");
        dcase(2'd1, 2'd2, 2'd2, 1'b1, 2'd0, 1'b0, 2'b00, 2'b10, "B matches MEM");
        dcase(2'd1, 2'd2, 2'd0, 1'b1, 2'd2, 1'b1, 2'b00, 2'b01, "B matches WB");
        dcase(2'd3, 2'd3, 2'd3, 1'b1, 2'd3, 1'b1, 2'b10, 2'b10, "ADD R3,R3 after two writes to R3");
        dcase(2'd0, 2'd1, 2'd1, 1'b1, 2'd0, 1'b1, 2'b01, 2'b10, "A from WB and B from MEM together");

        $display("\nPART 2: exhaustive check (1024 cases)");
        for (v = 0; v < 1024; v = v + 1) begin
            {ex_rd, ex_rs, mem_rd, mem_reg_we, wb_rd, wb_reg_we} = v;
            #1;
            n_exh = n_exh + 1;
            if (fwd_a_sel !== ref_sel(ex_rd) || fwd_b_sel !== ref_sel(ex_rs)) begin
                errors = errors + 1;
                $display("  FAIL input %b: A %b/%b B %b/%b", v[9:0], fwd_a_sel, ref_sel(ex_rd),
                         fwd_b_sel, ref_sel(ex_rs));
            end
        end
        $display("  %0d exhaustive cases compared", n_exh);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_forwarding_unit (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_exh);
        else
            $display("FAILED: tb_forwarding_unit (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_exh);
        $finish(0);
    end

endmodule

`default_nettype wire
