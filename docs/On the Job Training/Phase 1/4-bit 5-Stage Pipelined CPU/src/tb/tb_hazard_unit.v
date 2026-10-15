// =============================================================================
// File        : tb_hazard_unit.v
// Module      : tb_hazard_unit   (self-checking testbench for hazard_unit)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Part 1      : 10 directed pipeline situations, one every 10 ns (sampled at
//               t + 5 ns), each named after the instruction pair it models.
// Part 2      : exhaustive: all 2^12 = 4096 input combinations against a
//               reference written from the hazard rules.
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_hazard_unit;

    reg  [1:0] id_rd, id_rs, ex_rd;
    reg        id_uses_rd, id_uses_rs, id_is_jz, ex_reg_we, ex_wb_sel, ex_zero_we;
    wire       load_use_stall, flag_stall, stall, pc_en, ir_load, id_ex_bubble;
    integer    errors = 0, n_dir = 0, n_exh = 0;
    integer    v;
    reg        r_lu, r_fl;

    hazard_unit DUT (
        .id_rd(id_rd), .id_rs(id_rs), .id_uses_rd(id_uses_rd), .id_uses_rs(id_uses_rs),
        .id_is_jz(id_is_jz), .ex_rd(ex_rd), .ex_reg_we(ex_reg_we), .ex_wb_sel(ex_wb_sel),
        .ex_zero_we(ex_zero_we), .load_use_stall(load_use_stall), .flag_stall(flag_stall),
        .stall(stall), .pc_en(pc_en), .ir_load(ir_load), .id_ex_bubble(id_ex_bubble)
    );

    // ---- reference: the two hazard rules, written as plain if statements ---
    task reference;
        begin
            r_lu = 1'b0;
            if (ex_reg_we == 1'b1 && ex_wb_sel == 1'b1) begin       // EX holds LOAD
                if (id_uses_rd == 1'b1 && id_rd == ex_rd) r_lu = 1'b1;
                if (id_uses_rs == 1'b1 && id_rs == ex_rd) r_lu = 1'b1;
            end
            r_fl = (id_is_jz == 1'b1 && ex_zero_we == 1'b1);
        end
    endtask

    task check_outputs;
        output ok;
        begin
            reference;
            ok = (load_use_stall === r_lu) && (flag_stall === r_fl) &&
                 (stall === (r_lu | r_fl)) && (pc_en === !(r_lu | r_fl)) &&
                 (ir_load === !(r_lu | r_fl)) && (id_ex_bubble === (r_lu | r_fl));
        end
    endtask

    // fields: ID {rd, rs, uses_rd, uses_rs, is_jz}  EX {rd, reg_we, wb_sel, zero_we}
    task dcase;
        input [1:0] i_rd, i_rs; input u_rd, u_rs, jz;
        input [1:0] e_rd; input e_we, e_wbs, e_zwe;
        input e_lu, e_fl; input [8*36:1] note;
        reg ok;
        begin
            id_rd = i_rd; id_rs = i_rs; id_uses_rd = u_rd; id_uses_rs = u_rs; id_is_jz = jz;
            ex_rd = e_rd; ex_reg_we = e_we; ex_wb_sel = e_wbs; ex_zero_we = e_zwe;
            #5;
            n_dir = n_dir + 1;
            ok = (load_use_stall === e_lu) && (flag_stall === e_fl) && (stall === (e_lu | e_fl)) &&
                 (pc_en === !(e_lu | e_fl)) && (ir_load === !(e_lu | e_fl)) &&
                 (id_ex_bubble === (e_lu | e_fl));
            if (!ok) errors = errors + 1;
            $display("  %t | R%0d R%0d  %b %b %b | R%0d  %b  %b  %b |  %b   %b  |   %b    %b    %b   | %s | %0s",
                     $time - 5, id_rd, id_rs, id_uses_rd, id_uses_rs, id_is_jz, ex_rd, ex_reg_we,
                     ex_wb_sel, ex_zero_we, load_use_stall, flag_stall, stall, pc_en,
                     id_ex_bubble, ok ? "PASS" : "FAIL", note);
            #5;
        end
    endtask

    initial begin
        $timeformat(-9, 0, "", 5);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_hazard_unit.vcd"); $dumpvars(0, tb_hazard_unit); end
        $display("============================================================================");
        $display(" tb_hazard_unit : self-checking testbench for module hazard_unit");
        $display(" Student        : Vu Quoc Anh | Roll number: SE203519");
        $display(" Vivado         : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        {id_rd, id_rs, id_uses_rd, id_uses_rs, id_is_jz, ex_rd, ex_reg_we, ex_wb_sel, ex_zero_we} = 12'd0;
        #10;
        $display("\nPART 1: directed pipeline situations (row t: applied at t, sampled at t + 5 ns)");
        $display("  time | ID: rd rs ud us jz | EX: rd we wbs zwe | LU  FL  | stall pc_en bubble | chk  | ID instr after EX instr");
        $display("  -----+--------------------+-------------------+---------+--------------------+------+------------------------");
        //    ID rd  rs   urd  urs  jz   EX rd we   wbs  zwe   LU   FL
        dcase(2'd1, 2'd2, 1'b1, 1'b1, 1'b0, 2'd3, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, "ADD R1,R2 after ADD R3,x: none");
        dcase(2'd2, 2'd1, 1'b1, 1'b1, 1'b0, 2'd2, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, "SUB R2,R1 after LOAD R2: Rd match");
        dcase(2'd3, 2'd2, 1'b1, 1'b1, 1'b0, 2'd2, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, "ADD R3,R2 after LOAD R2: Rs match");
        dcase(2'd0, 2'd0, 1'b1, 1'b0, 1'b0, 2'd0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, "STORE R0 after LOAD R0");
        dcase(2'd2, 2'd0, 1'b0, 1'b0, 1'b0, 2'd2, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, "LDI R2 after LOAD R2: no read");
        dcase(2'd1, 2'd1, 1'b1, 1'b1, 1'b0, 2'd1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, "ADD R1,R1 after ADD R1: forward");
        dcase(2'd0, 2'd2, 1'b0, 1'b1, 1'b0, 2'd2, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, "EX we=0, wb_sel=1: not a LOAD");
        dcase(2'd0, 2'd0, 1'b0, 1'b0, 1'b1, 2'd1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, "JZ after SUB: flag stall");
        dcase(2'd0, 2'd0, 1'b0, 1'b0, 1'b1, 2'd3, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, "JZ after LDI: old flag is fine");
        dcase(2'd0, 2'd0, 1'b0, 1'b0, 1'b1, 2'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, "JZ after LOAD: no stall");

        $display("\nPART 2: exhaustive check (4096 cases)");
        for (v = 0; v < 4096; v = v + 1) begin : exh
            reg ok;
            {id_rd, id_rs, id_uses_rd, id_uses_rs, id_is_jz, ex_rd, ex_reg_we, ex_wb_sel, ex_zero_we} = v;
            #1;
            check_outputs(ok);
            n_exh = n_exh + 1;
            if (!ok) begin
                errors = errors + 1;
                $display("  FAIL input vector %b: LU %b/%b FL %b/%b", v[11:0], load_use_stall, r_lu,
                         flag_stall, r_fl);
            end
        end
        $display("  %0d exhaustive cases compared", n_exh);

        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_hazard_unit (Vu Quoc Anh, SE203519) %0d directed + %0d exhaustive checks, 0 errors", n_dir, n_exh);
        else
            $display("FAILED: tb_hazard_unit (Vu Quoc Anh, SE203519) %0d errors in %0d checks", errors, n_dir + n_exh);
        $finish(0);
    end

endmodule

`default_nettype wire
