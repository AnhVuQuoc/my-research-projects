// =============================================================================
// File        : tb_hazard_unit.v
// Module      : tb_hazard_unit   (self-checking testbench for hazard_unit)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 11 named pipeline situations, 1 every 10 ns
// Part 2      : exhaustive: all 2^16 = 65536 input combinations vs plain if statements
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_hazard_unit;
    reg [2:0] id_ra, id_rb, ex_rd; reg id_uses_a, id_uses_b, id_is_bz, id_is_bnz, ex_reg_we, ex_wb_sel, ex_zero_we;
    wire load_use_stall, flag_stall, stall, ir_load, id_ex_bubble;
    integer errors = 0, n_dir = 0, n_p2 = 0, v; reg r_lu, r_fl;
    hazard_unit DUT (.id_ra(id_ra), .id_rb(id_rb), .id_uses_a(id_uses_a), .id_uses_b(id_uses_b), .id_is_bz(id_is_bz),
        .id_is_bnz(id_is_bnz), .ex_rd(ex_rd), .ex_reg_we(ex_reg_we), .ex_wb_sel(ex_wb_sel), .ex_zero_we(ex_zero_we),
        .load_use_stall(load_use_stall), .flag_stall(flag_stall), .stall(stall), .ir_load(ir_load), .id_ex_bubble(id_ex_bubble));
    task reference; begin
        r_lu = 1'b0;
        if (ex_reg_we == 1'b1 && ex_wb_sel == 1'b1) begin
            if (id_uses_a == 1'b1 && id_ra == ex_rd) r_lu = 1'b1;
            if (id_uses_b == 1'b1 && id_rb == ex_rd) r_lu = 1'b1;
        end
        r_fl = ((id_is_bz == 1'b1 || id_is_bnz == 1'b1) && ex_zero_we == 1'b1);
    end endtask
    function outs_ok; input dummy;
        outs_ok = (load_use_stall === r_lu) && (flag_stall === r_fl) && (stall === (r_lu | r_fl)) &&
                  (ir_load === !(r_lu | r_fl)) && (id_ex_bubble === (r_lu | r_fl));
    endfunction
    task dcase; input [2:0] a, b; input ua, ub, bz, bnz; input [2:0] e_rd; input e_we, e_wbs, e_zwe;
        input e_lu, e_fl; input [8*38:1] note;
        reg ok; begin
            id_ra = a; id_rb = b; id_uses_a = ua; id_uses_b = ub; id_is_bz = bz; id_is_bnz = bnz;
            ex_rd = e_rd; ex_reg_we = e_we; ex_wb_sel = e_wbs; ex_zero_we = e_zwe; #5; n_dir = n_dir + 1;
            reference; ok = outs_ok(0) && (r_lu == e_lu) && (r_fl == e_fl); if (!ok) errors = errors + 1;
            $display("  %t | R%0d R%0d %b%b %b%b | R%0d %b %b %b |  %b   %b  |   %b   | %s | %0s", $time - 5, id_ra, id_rb,
                     id_uses_a, id_uses_b, id_is_bz, id_is_bnz, ex_rd, ex_reg_we, ex_wb_sel, ex_zero_we,
                     load_use_stall, flag_stall, stall, ok ? "PASS" : "FAIL", note); #5;
        end endtask
    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_hazard_unit.vcd"); $dumpvars(0, tb_hazard_unit); end
        $display("============================================================================");
        $display(" tb_hazard_unit : self-checking testbench for module hazard_unit");
        $display(" Student : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado  : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        {id_ra, id_rb, id_uses_a, id_uses_b, id_is_bz, id_is_bnz, ex_rd, ex_reg_we, ex_wb_sel, ex_zero_we} = 16'd0; #10;
        $display("\nPART 1: directed pipeline situations (row t: applied at t, sampled at t + 5 ns)");
        $display("  time | ID: ra rb ua.ub bz.bnz | EX: rd we wbs zwe | LU  FL | stall | chk  | ID instruction after EX instruction");
        dcase(3'd1,3'd2,1,1,0,0, 3'd3,1,0,1, 0,0, "ADD R4,R1,R2 after ADD R3: none");
        dcase(3'd3,3'd2,1,1,0,0, 3'd3,1,1,0, 1,0, "ADD R4,R3,R2 after LD R3: port A");
        dcase(3'd1,3'd3,1,1,0,0, 3'd3,1,1,0, 1,0, "ADD R4,R1,R3 after LD R3: port B");
        dcase(3'd3,3'd3,1,1,0,0, 3'd3,1,1,0, 1,0, "ADD R4,R3,R3 after LD R3: both");
        dcase(3'd0,3'd5,1,1,0,0, 3'd5,1,1,0, 1,0, "ST R5,[R0] after LD R5: store data");
        dcase(3'd5,3'd2,1,1,0,0, 3'd5,1,1,0, 1,0, "ST R2,[R5] after LD R5: address");
        dcase(3'd3,3'd7,0,0,0,0, 3'd3,1,1,0, 0,0, "LDI R3,0xC8 after LD R3: fields only");
        dcase(3'd1,3'd1,1,0,0,0, 3'd1,1,0,1, 0,0, "ADDI R1 after ADD R1: forwarded");
        dcase(3'd0,3'd0,0,0,1,0, 3'd1,1,0,1, 0,1, "BZ after SUB: flag stall");
        dcase(3'd0,3'd0,0,0,0,1, 3'd1,1,0,1, 0,1, "BNZ after ADDI: flag stall");
        dcase(3'd0,3'd0,0,0,1,0, 3'd1,1,0,0, 0,0, "BZ after LDI: old flag is fine");
        $display("\nPART 2: exhaustive check (65536 cases)");
        for (v = 0; v < 65536; v = v + 1) begin
            {id_ra, id_rb, id_uses_a, id_uses_b, id_is_bz, id_is_bnz, ex_rd, ex_reg_we, ex_wb_sel, ex_zero_we} = v;
            #1; reference; n_p2 = n_p2 + 1; if (!outs_ok(0)) errors = errors + 1;
        end
        $display("  %0d exhaustive cases compared", n_p2);
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_hazard_unit (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_p2);
        else
            $display("FAILED: tb_hazard_unit (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_p2);
        $finish(0);
    end
endmodule
`default_nettype wire
