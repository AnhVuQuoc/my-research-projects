// =============================================================================
// File        : tb_register_file.v
// Module      : tb_register_file   (self-checking testbench for register_file)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Clock       : rising edges at 10, 20, 30 ... ns. Row t: inputs applied at
//               t - 5 ns (falling edge), read ports sampled at t - 1 ns
//               ("before" the edge) and at t + 5 ns ("after" the edge).
//               "before" shows the write-first bypass, "after" the stored value.
// Part 1      : 10 directed cycles, expected values by hand
// Part 2      : 2000 random cycles against a reference model (array + bypass)
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_register_file;

    reg        clk = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end

    reg        rst = 1'b1, we = 1'b0;
    reg  [1:0] ra = 0, rb = 0, wa = 0;
    reg  [3:0] wd = 0;
    wire [3:0] qa, qb;
    integer    errors = 0, n_dir = 0, n_rnd = 0;
    integer    c, seed = 32'h5E203519;
    reg  [3:0] model [0:3];
    reg  [3:0] bqa, bqb, exp_a, exp_b;

    register_file DUT (.clk(clk), .rst(rst), .ra(ra), .rb(rb), .wa(wa), .wd(wd),
                       .we(we), .qa(qa), .qb(qb));

    task dcycle;
        input r; input w; input [1:0] a_wa; input [3:0] a_wd; input [1:0] a_ra, a_rb;
        input [3:0] e_bqa, e_bqb, e_aqa, e_aqb; input [8*30:1] note;
        reg ok;
        begin
            rst = r; we = w; wa = a_wa; wd = a_wd; ra = a_ra; rb = a_rb;   // at falling edge
            #4; bqa = qa; bqb = qb;                                       // t - 1 ns
            @(posedge clk); @(negedge clk);                                // edge t, sample t + 5
            n_dir = n_dir + 1;
            ok = (bqa === e_bqa) && (bqb === e_bqb) && (qa === e_aqa) && (qb === e_aqb);
            if (!ok) errors = errors + 1;
            $display("  %t |  %b   %b | R%0d %b | R%0d R%0d | %b %b | %b %b | %b %b %b %b | %s | %0s",
                     $time - 5, rst, we, wa, wd, ra, rb, bqa, bqb, qa, qb,
                     e_bqa, e_bqb, e_aqa, e_aqb, ok ? "PASS" : "FAIL", note);
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_register_file.vcd"); $dumpvars(0, tb_register_file); end
        $display("============================================================================");
        $display(" tb_register_file : self-checking testbench for module register_file");
        $display(" Student          : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado           : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        @(negedge clk);
        $display("\nPART 1: directed cycles (row t = rising edge; before = t-1 ns, after = t+5 ns)");
        $display("  time | rst we | write   | read  | before    | after     | exp b4 / after      | chk  | note");
        $display("  -----+--------+---------+-------+-----------+-----------+---------------------+------+-----");
        //     rst  we   wa    wd       ra    rb    b4 qa    b4 qb    af qa    af qb
        dcycle(1'b1,1'b0,2'd0,4'b0000,2'd0,2'd3, 4'b0000,4'b0000,4'b0000,4'b0000, "reset (also active at 10 ns)");
        dcycle(1'b0,1'b1,2'd0,4'b0001,2'd0,2'd1, 4'b0001,4'b0000,4'b0001,4'b0000, "write R0, bypass on port A");
        dcycle(1'b0,1'b1,2'd1,4'b0101,2'd1,2'd0, 4'b0101,4'b0001,4'b0101,4'b0001, "write R1, bypass on port A");
        dcycle(1'b0,1'b1,2'd2,4'b1010,2'd3,2'd2, 4'b0000,4'b1010,4'b0000,4'b1010, "write R2, bypass on port B");
        dcycle(1'b0,1'b1,2'd3,4'b1111,2'd3,2'd3, 4'b1111,4'b1111,4'b1111,4'b1111, "write R3, bypass on both");
        dcycle(1'b0,1'b0,2'd2,4'b0000,2'd2,2'd1, 4'b1010,4'b0101,4'b1010,4'b0101, "we = 0: R2 keeps 1010");
        dcycle(1'b0,1'b1,2'd1,4'b0110,2'd2,2'd0, 4'b1010,4'b0001,4'b1010,4'b0001, "write R1, other regs read");
        dcycle(1'b0,1'b0,2'd0,4'b0000,2'd1,2'd1, 4'b0110,4'b0110,4'b0110,4'b0110, "R1 = 0110 on both ports");
        dcycle(1'b1,1'b1,2'd0,4'b1111,2'd1,2'd2, 4'b0110,4'b1010,4'b0000,4'b0000, "reset wins over a write");
        dcycle(1'b0,1'b0,2'd0,4'b0000,2'd0,2'd3, 4'b0000,4'b0000,4'b0000,4'b0000, "R0 stayed 0 after that");

        $display("\nPART 2: 2000 random cycles against the reference model");
        model[0] = 0; model[1] = 0; model[2] = 0; model[3] = 0;
        for (c = 0; c < 2000; c = c + 1) begin
            rst = (($unsigned($random(seed)) % 50) == 0);
            we  = $random(seed); wa = $random(seed); wd = $random(seed);
            ra  = $random(seed); rb = $random(seed);
            #1;
            exp_a = (we && wa == ra) ? wd : model[ra];
            exp_b = (we && wa == rb) ? wd : model[rb];
            n_rnd = n_rnd + 1;
            if (!rst && (qa !== exp_a || qb !== exp_b)) begin
                errors = errors + 1;
                $display("  FAIL cycle %0d: ra=%0d qa=%b exp %b | rb=%0d qb=%b exp %b", c, ra, qa, exp_a,
                         rb, qb, exp_b);
            end
            @(posedge clk);
            if (rst) begin model[0] = 0; model[1] = 0; model[2] = 0; model[3] = 0; end
            else if (we) model[wa] = wd;
            @(negedge clk);
        end
        $display("  %0d random cycles compared", n_rnd);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_register_file (Vu Quoc Anh, SE203519) %0d directed + %0d random checks, 0 errors", n_dir, n_rnd);
        else
            $display("FAILED: tb_register_file (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_rnd);
        $finish(0);
    end

endmodule

`default_nettype wire
