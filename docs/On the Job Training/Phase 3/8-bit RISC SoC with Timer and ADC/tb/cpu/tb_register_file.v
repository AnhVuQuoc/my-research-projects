// =============================================================================
// File        : tb_register_file.v
// Module      : tb_register_file   (self-checking testbench for register_file)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 10 directed cycles; read ports sampled 1 ns BEFORE the edge (bypass) and 5 ns after
// Part 2      : 4000 random cycles against an array model with the same write-first bypass
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_register_file;
    reg clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end
    reg rst = 1'b1, we = 1'b0; reg [2:0] ra = 0, rb = 0, wa = 0; reg [7:0] wd = 0;
    wire [7:0] qa, qb; reg [7:0] model [0:7]; reg [7:0] bqa, bqb, ea, eb;
    integer errors = 0, n_dir = 0, n_p2 = 0, c, m, seed = 32'h5E203519;
    register_file DUT (.clk(clk), .rst(rst), .ra(ra), .rb(rb), .wa(wa), .wd(wd), .we(we), .qa(qa), .qb(qb));
    task dcycle; input r, w; input [2:0] a_wa; input [7:0] a_wd; input [2:0] a_ra, a_rb;
        input [7:0] e_bqa, e_bqb, e_aqa, e_aqb; input [8*28:1] note;
        reg ok; begin
            rst = r; we = w; wa = a_wa; wd = a_wd; ra = a_ra; rb = a_rb; #4; bqa = qa; bqb = qb;
            @(posedge clk); @(negedge clk); n_dir = n_dir + 1;
            ok = (bqa === e_bqa) && (bqb === e_bqb) && (qa === e_aqa) && (qb === e_aqb); if (!ok) errors = errors + 1;
            $display("  %t |  %b   %b | R%0d %h | R%0d R%0d | %h %h | %h %h | %h %h %h %h | %s | %0s", $time - 5, rst, we,
                     wa, wd, ra, rb, bqa, bqb, qa, qb, e_bqa, e_bqb, e_aqa, e_aqb, ok ? "PASS" : "FAIL", note);
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_register_file.vcd"); $dumpvars(0, tb_register_file); end
        $display("============================================================================");
        $display(" tb_register_file : self-checking testbench for module register_file");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge; before = t-1 ns, after = t+5 ns)");
        $display("  time | rst we | write | read  | before | after  | exp b4 / after | chk  | note");
        dcycle(1,0,3'd0,8'h00,3'd0,3'd7, 8'h00,8'h00,8'h00,8'h00, "reset (also active at 10 ns)");
        dcycle(0,1,3'd1,8'h11,3'd1,3'd0, 8'h11,8'h00,8'h11,8'h00, "write R1, bypass on port A");
        dcycle(0,1,3'd7,8'h77,3'd0,3'd7, 8'h00,8'h77,8'h00,8'h77, "write R7, bypass on port B");
        dcycle(0,1,3'd0,8'hA0,3'd0,3'd0, 8'hA0,8'hA0,8'hA0,8'hA0, "write R0 (ordinary), both");
        dcycle(0,0,3'd1,8'hFF,3'd1,3'd7, 8'h11,8'h77,8'h11,8'h77, "we = 0: R1 keeps 11");
        dcycle(0,1,3'd5,8'h55,3'd1,3'd0, 8'h11,8'hA0,8'h11,8'hA0, "write R5, other regs read");
        dcycle(0,0,3'd0,8'h00,3'd5,3'd5, 8'h55,8'h55,8'h55,8'h55, "R5 on both ports");
        dcycle(0,1,3'd5,8'h5B,3'd5,3'd1, 8'h5B,8'h11,8'h5B,8'h11, "overwrite R5, bypass");
        dcycle(1,1,3'd2,8'hEE,3'd1,3'd5, 8'h11,8'h5B,8'h00,8'h00, "reset wins over a write");
        dcycle(0,0,3'd0,8'h00,3'd2,3'd7, 8'h00,8'h00,8'h00,8'h00, "R2 stayed 0 after that");
        $display("\nPART 2: 4000 random cycles against the reference model");
        for (m = 0; m < 8; m = m + 1) model[m] = 8'h00;
        for (c = 0; c < 4000; c = c + 1) begin
            rst = (($unsigned($random(seed)) % 60) == 0); we = $random(seed); wa = $random(seed);
            wd = $random(seed); ra = $random(seed); rb = $random(seed); #1;
            ea = (we && wa == ra) ? wd : model[ra]; eb = (we && wa == rb) ? wd : model[rb]; n_p2 = n_p2 + 1;
            if (!rst && (qa !== ea || qb !== eb)) errors = errors + 1;
            @(posedge clk);
            if (rst) for (m = 0; m < 8; m = m + 1) model[m] = 8'h00; else if (we) model[wa] = wd;
            @(negedge clk);
        end
        $display("  %0d random cycles compared", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_register_file (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_register_file (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
