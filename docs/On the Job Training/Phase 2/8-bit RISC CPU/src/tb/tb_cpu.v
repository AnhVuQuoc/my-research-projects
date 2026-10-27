// =============================================================================
// File        : tb_cpu.v
// Module      : tb_cpu   (self-checking testbench for cpu_top)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Clock       : rising edges at 10, 20, 30 ... ns. Row t is sampled at t + 5 ns.
// Part 1      : reset values; 6 programs (asm/*.asm). Every retiring instruction
//               is compared with a hand-written expected list, the cycle in
//               which HLT retires with the hand-calculated 4 + k + bubbles, the
//               drain after HLT, and the final registers, memory and flags.
// Part 2      : the 6 programs and 300 random programs in LOCKSTEP with 2
//               copies of isa_reference_model; invariants every cycle;
//               coverage goals that must all be reached.
// Vivado      : press "Run All" (the run ends by itself with $finish)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_cpu;

    reg clk = 1'b0;
    reg rst = 1'b1;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end

    wire [7:0]  pc_out, alu_out, wb_data_out;
    wire [15:0] instr_out;
    wire        zero_out, carry_out, halted;

    cpu_top #(.PROGRAM_FILE("program.mem")) CPU (
        .clk(clk), .rst(rst), .pc_out(pc_out), .instr_out(instr_out), .alu_out(alu_out),
        .wb_data_out(wb_data_out), .zero_out(zero_out), .carry_out(carry_out), .halted(halted)
    );

    isa_reference_model REF_WB  ();
    isa_reference_model REF_MEM ();

    integer errors = 0, checks = 0, ls_checks = 0, inv_checks = 0;
    integer cycle = 0, i, p, k, n_ret;
    integer seed = 32'h5E203519;

    always @(posedge clk) begin
        if (rst) cycle <= 1;
        else     cycle <= cycle + 1;
    end

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------
    function [8*14:1] left;
        input [8*14:1] s;
        integer n;
        begin
            left = s;
            for (n = 0; n < 14; n = n + 1)
                if (left[112:105] == 8'h00) left = {left[104:1], 8'h20};
        end
    endfunction

    function [8*14:1] disasm;
        input [15:0] w;
        reg [8*14:1] s;
        begin
            case (w[15:12])
                4'h0: $sformat(s, "NOP");
                4'h1: $sformat(s, "ADD R%0d,R%0d,R%0d", w[11:9], w[8:6], w[5:3]);
                4'h2: $sformat(s, "SUB R%0d,R%0d,R%0d", w[11:9], w[8:6], w[5:3]);
                4'h3: $sformat(s, "AND R%0d,R%0d,R%0d", w[11:9], w[8:6], w[5:3]);
                4'h4: $sformat(s, "OR R%0d,R%0d,R%0d",  w[11:9], w[8:6], w[5:3]);
                4'h5: $sformat(s, "XOR R%0d,R%0d,R%0d", w[11:9], w[8:6], w[5:3]);
                4'h6: $sformat(s, "SHL R%0d,R%0d", w[11:9], w[8:6]);
                4'h7: $sformat(s, "SHR R%0d,R%0d", w[11:9], w[8:6]);
                4'h8: $sformat(s, "LDI R%0d,%0d",  w[11:9], w[7:0]);
                4'h9: $sformat(s, "ADDI R%0d,%0d", w[11:9], w[7:0]);
                4'hA: $sformat(s, "LD R%0d,[R%0d]", w[11:9], w[8:6]);
                4'hB: $sformat(s, "ST R%0d,[R%0d]", w[11:9], w[8:6]);
                4'hC: $sformat(s, "JMP %0d", w[7:0]);
                4'hD: $sformat(s, "BZ %0d",  w[7:0]);
                4'hE: $sformat(s, "BNZ %0d", w[7:0]);
                default: $sformat(s, "HLT");
            endcase
            disasm = left(s);
        end
    endfunction

    // which register ports an instruction really reads (from the ISA table)
    function reads_a; input [3:0] op;
        reads_a = (op >= 4'h1 && op <= 4'h7) || op == 4'h9 || op == 4'hA || op == 4'hB;
    endfunction
    function reads_b; input [3:0] op;
        reads_b = (op >= 4'h1 && op <= 4'h5) || op == 4'hB;
    endfunction

    function [8*3:1] a3; input [7:0] a;
        reg [8*3:1] t;
        begin $sformat(t, "%3d", a); a3 = t; end
    endfunction

    task check8; input [8*44:1] name; input [7:0] actual, expected;
        begin
            checks = checks + 1;
            if (actual === expected) $display("  %t | PASS | %0s = %h", $time, name, actual);
            else begin $display("  %t | FAIL | %0s = %h (expected %h)", $time, name, actual, expected); errors = errors + 1; end
        end
    endtask
    task check1; input [8*44:1] name; input actual, expected;
        begin
            checks = checks + 1;
            if (actual === expected) $display("  %t | PASS | %0s = %b", $time, name, actual);
            else begin $display("  %t | FAIL | %0s = %b (expected %b)", $time, name, actual, expected); errors = errors + 1; end
        end
    endtask

    task clear_memories;
        begin
            for (i = 0; i < 256; i = i + 1) begin CPU.IMEM.mem[i] = 16'h0000; CPU.DMEM.mem[i] = 8'h00; end
        end
    endtask
    task load_program; input [8*24:1] f;
        begin clear_memories; $readmemh(f, CPU.IMEM.mem, 0, 255); end
    endtask
    task copy_to_models;
        begin
            for (i = 0; i < 256; i = i + 1) begin
                REF_WB.imem[i] = CPU.IMEM.mem[i];  REF_WB.dmem[i] = CPU.DMEM.mem[i];
                REF_MEM.imem[i] = CPU.IMEM.mem[i]; REF_MEM.dmem[i] = CPU.DMEM.mem[i];
            end
            REF_WB.reset_state; REF_MEM.reset_state;
        end
    endtask
    task reset_cpu;
        begin
            rst <= 1'b1;
            @(negedge clk); @(posedge clk); @(posedge clk); @(negedge clk);
            rst <= 1'b0;
        end
    endtask

    // ------------------------------------------------------------------------
    // Part 1 engine: expected retire list, written by hand
    // kind 1 = no write, 2 = register write, 3 = memory write
    // ------------------------------------------------------------------------
    reg [1:0] exp_kind [0:63];
    reg [7:0] exp_addr [0:63];
    reg [2:0] exp_rd   [0:63];
    reg [7:0] exp_val  [0:63];
    reg [7:0] exp_ma   [0:63];
    integer   n_exp, exp_halt_cycle;
    task e_ins; input [7:0] a; begin exp_kind[n_exp] = 1; exp_addr[n_exp] = a; n_exp = n_exp + 1; end endtask
    task e_reg; input [7:0] a; input [2:0] d; input [7:0] v;
        begin exp_kind[n_exp] = 2; exp_addr[n_exp] = a; exp_rd[n_exp] = d; exp_val[n_exp] = v; n_exp = n_exp + 1; end endtask
    task e_mem; input [7:0] a; input [7:0] ma; input [7:0] v;
        begin exp_kind[n_exp] = 3; exp_addr[n_exp] = a; exp_ma[n_exp] = ma; exp_val[n_exp] = v; n_exp = n_exp + 1; end endtask

    task run_directed;
        input [8*30:1] title;
        reg ok, done;
        reg [8*14:1] wtxt;
        reg [7:0] pc_at_halt;
        integer guard;
        begin
            $display("\n  --- %0s: %0d retirements expected, HLT expected in cycle %0d ---", title, n_exp, exp_halt_cycle);
            $display("  time  | cyc | IF  | ID  | EX  | MEM | WB  | retiring       | st fl fA fB | WB write       | check");
            $display("  ------+-----+-----+-----+-----+-----+-----+----------------+-------------+----------------+------");
            k = 0; done = 1'b0; guard = 0;
            while (!done && guard < 300) begin
                if (guard > 0) @(negedge clk);
                guard = guard + 1;
                if (CPU.wb_valid) begin
                    checks = checks + 1;
                    case (exp_kind[k])
                        2'd1: ok = CPU.wb_pc == exp_addr[k] && !CPU.wb_reg_we;
                        2'd2: ok = CPU.wb_pc == exp_addr[k] && CPU.wb_reg_we && CPU.wb_rd == exp_rd[k] &&
                                   CPU.wb_data == exp_val[k];
                        default: ok = CPU.wb_pc == exp_addr[k] && !CPU.wb_reg_we &&
                                      CPU.DMEM.mem[exp_ma[k]] == exp_val[k];
                    endcase
                    if (k >= n_exp) ok = 1'b0;
                    if (CPU.wb_reg_we)           $sformat(wtxt, "R%0d=%h", CPU.wb_rd, CPU.wb_data);
                    else if (exp_kind[k] == 3)   $sformat(wtxt, "M[%h]=%h", exp_ma[k], CPU.DMEM.mem[exp_ma[k]]);
                    else                         wtxt = left("none");
                    if (!ok) errors = errors + 1;
                end
                else wtxt = left("-");
                $display("  %t | %3d | %s | %s | %s | %s | %s | %s | %b  %b  %0d  %0d  | %s | %0s",
                    $time - 5, cycle, a3(CPU.if_pc),
                    CPU.id_valid  ? a3(CPU.id_pc)  : " --", CPU.ex_valid  ? a3(CPU.ex_pc)  : " --",
                    CPU.mem_valid ? a3(CPU.mem_pc) : " --", CPU.wb_valid  ? a3(CPU.wb_pc)  : " --",
                    CPU.wb_valid ? disasm(CPU.wb_instr) : left("bubble"),
                    CPU.stall, CPU.if_id_flush, CPU.fwd_a_sel, CPU.fwd_b_sel, left(wtxt),
                    CPU.wb_valid ? (ok ? "PASS" : "FAIL") : "-");
                if (CPU.wb_valid) begin
                    if (CPU.wb_instr[15:12] == 4'hF) begin
                        done = 1'b1;
                        checks = checks + 1;
                        if (cycle == exp_halt_cycle)
                            $display("  %t | PASS | HLT retired in cycle %0d = 4 + %0d + %0d bubbles", $time, cycle, n_exp, cycle - 4 - n_exp);
                        else begin
                            $display("  %t | FAIL | HLT retired in cycle %0d (expected %0d)", $time, cycle, exp_halt_cycle);
                            errors = errors + 1;
                        end
                    end
                    k = k + 1;
                end
            end
            if (!done) begin errors = errors + 1; $display("  FAIL | watchdog: HLT never retired"); end
            // drain check: nothing more retires, PC frozen, halted = 1
            pc_at_halt = CPU.if_pc;
            ok = 1'b1;
            repeat (5) begin @(negedge clk); if (CPU.wb_valid || CPU.if_pc !== pc_at_halt || !halted) ok = 1'b0; end
            checks = checks + 1;
            if (ok) $display("  %t | PASS | drained: 5 cycles after HLT, no retirement, PC frozen at %0d, halted = 1", $time, pc_at_halt);
            else begin $display("  %t | FAIL | pipeline did not stop after HLT", $time); errors = errors + 1; end
            @(posedge clk); #1;
        end
    endtask

    // ------------------------------------------------------------------------
    // Part 2 engine: lockstep, invariants, coverage
    // ------------------------------------------------------------------------
    reg     lockstep_on = 1'b0, invariant_on = 1'b0, lockstep_done = 1'b0;
    integer target_retire;
    integer cov_fa_mem = 0, cov_fa_wb = 0, cov_fb_mem = 0, cov_fb_wb = 0, cov_bypass = 0;
    integer cov_lu_a = 0, cov_lu_b = 0, cov_flag = 0, cov_jmp = 0, cov_bz_t = 0, cov_bz_n = 0;
    integer cov_bnz_t = 0, cov_bnz_n = 0, cov_hlt = 0, cov_wrap = 0, cov_ld = 0, cov_st = 0;
    integer cov_shift = 0, cov_addi = 0, cov_c1 = 0;
    reg        pv = 1'b0, p_stall, p_flush, p_halted;
    reg [7:0]  p_pc;
    reg [15:0] p_id;
    reg        p_idv;

    task inv_fail; input [8*48:1] what;
        begin errors = errors + 1; $display("  %t | FAIL | invariant: %0s", $time, what); end
    endtask

    always @(negedge clk) begin
        if (invariant_on && !rst) begin
            inv_checks = inv_checks + 1;
            if ((^{CPU.if_pc, CPU.id_instr, CPU.ex_instr, CPU.mem_instr, CPU.wb_instr, CPU.RF.r0, CPU.RF.r1,
                   CPU.RF.r2, CPU.RF.r3, CPU.RF.r4, CPU.RF.r5, CPU.RF.r6, CPU.RF.r7, CPU.zero_flag,
                   CPU.carry_flag, CPU.stall, CPU.if_id_flush, halted, wb_data_out}) === 1'bx)
                inv_fail("X value on a key signal");
            if (CPU.pc_sel && CPU.stall) inv_fail("branch taken while stalled");
            if (pv && p_stall && (CPU.if_pc !== p_pc || CPU.id_instr !== p_id || CPU.id_valid !== p_idv || CPU.ex_valid !== 1'b0))
                inv_fail("stall did not freeze PC and IF/ID, or no bubble");
            if (pv && p_flush && CPU.id_valid !== 1'b0) inv_fail("flush did not empty IF/ID");
            if (pv && p_halted && (CPU.if_pc !== p_pc || CPU.id_valid !== 1'b0)) inv_fail("halted CPU still fetching");
            if (CPU.ex_valid && CPU.mem_wb_sel && CPU.mem_reg_we &&
                ((reads_a(CPU.ex_instr[15:12]) && CPU.fwd_a_sel == 2'b10) ||
                 (reads_b(CPU.ex_instr[15:12]) && CPU.fwd_b_sel == 2'b10)))
                inv_fail("LD result forwarded from MEM (too early)");
            pv = 1'b1; p_stall = CPU.stall; p_flush = CPU.if_id_flush; p_halted = halted;
            p_pc = CPU.if_pc; p_id = CPU.id_instr; p_idv = CPU.id_valid;
        end
        else pv = 1'b0;

        if (lockstep_on && !rst && !lockstep_done) begin
            if (CPU.mem_valid) begin
                REF_MEM.step; ls_checks = ls_checks + 1;
                if (CPU.mem_pc !== REF_MEM.last_pc || CPU.zero_flag !== REF_MEM.zf || CPU.carry_flag !== REF_MEM.cf) begin
                    errors = errors + 1;
                    $display("  %t | FAIL | lockstep MEM: pc %0d/%0d Z %b/%b C %b/%b", $time, CPU.mem_pc,
                             REF_MEM.last_pc, CPU.zero_flag, REF_MEM.zf, CPU.carry_flag, REF_MEM.cf);
                end
            end
            if (CPU.wb_valid) begin
                ls_checks = ls_checks + 1;
                if (CPU.RF.r0 !== REF_WB.r[0] || CPU.RF.r1 !== REF_WB.r[1] || CPU.RF.r2 !== REF_WB.r[2] ||
                    CPU.RF.r3 !== REF_WB.r[3] || CPU.RF.r4 !== REF_WB.r[4] || CPU.RF.r5 !== REF_WB.r[5] ||
                    CPU.RF.r6 !== REF_WB.r[6] || CPU.RF.r7 !== REF_WB.r[7]) begin
                    errors = errors + 1; $display("  %t | FAIL | lockstep WB: registers differ before pc %0d", $time, CPU.wb_pc);
                end
                REF_WB.step; ls_checks = ls_checks + 1;
                if (CPU.wb_pc !== REF_WB.last_pc || CPU.wb_reg_we !== REF_WB.last_reg_we ||
                    (REF_WB.last_reg_we && (CPU.wb_rd !== REF_WB.last_rd || CPU.wb_data !== REF_WB.last_value))) begin
                    errors = errors + 1;
                    $display("  %t | FAIL | lockstep WB: pc %0d/%0d we %b/%b rd %0d/%0d data %h/%h", $time, CPU.wb_pc,
                             REF_WB.last_pc, CPU.wb_reg_we, REF_WB.last_reg_we, CPU.wb_rd, REF_WB.last_rd,
                             CPU.wb_data, REF_WB.last_value);
                end
                // memory changes only through ST: compare all 256 words when a ST retires
                // and at the end of every program (a stray write is caught at the next compare)
                if (REF_WB.last_mem_we || REF_WB.halted || REF_WB.steps >= target_retire) begin
                    ls_checks = ls_checks + 1;
                    for (p = 0; p < 256; p = p + 1)
                        if (CPU.DMEM.mem[p] !== REF_WB.dmem[p]) begin
                            errors = errors + 1; $display("  %t | FAIL | lockstep WB: dmem[%0d] %h/%h", $time, p, CPU.DMEM.mem[p], REF_WB.dmem[p]);
                        end
                end
                case (CPU.wb_instr[15:12])
                    4'hA: cov_ld = cov_ld + 1;   4'hB: cov_st = cov_st + 1;   4'hF: cov_hlt = cov_hlt + 1;
                    4'h6, 4'h7: cov_shift = cov_shift + 1;   4'h9: cov_addi = cov_addi + 1;
                    default: ;
                endcase
                if (REF_WB.steps >= target_retire || REF_WB.halted) lockstep_done = 1'b1;
            end
            if (CPU.ex_valid && reads_a(CPU.ex_instr[15:12])) begin
                if (CPU.fwd_a_sel == 2'b10) cov_fa_mem = cov_fa_mem + 1;
                if (CPU.fwd_a_sel == 2'b01) cov_fa_wb  = cov_fa_wb + 1;
            end
            if (CPU.ex_valid && reads_b(CPU.ex_instr[15:12])) begin
                if (CPU.fwd_b_sel == 2'b10) cov_fb_mem = cov_fb_mem + 1;
                if (CPU.fwd_b_sel == 2'b01) cov_fb_wb  = cov_fb_wb + 1;
            end
            if (CPU.id_valid && CPU.wb_reg_we &&
                ((CPU.id_uses_a && CPU.id_ra == CPU.wb_rd) || (CPU.id_uses_b && CPU.id_rb == CPU.wb_rd)))
                cov_bypass = cov_bypass + 1;
            if (CPU.load_use_stall && CPU.id_uses_a && CPU.id_ra == CPU.ex_rd) cov_lu_a = cov_lu_a + 1;
            if (CPU.load_use_stall && CPU.id_uses_b && CPU.id_rb == CPU.ex_rd) cov_lu_b = cov_lu_b + 1;
            if (CPU.flag_stall) cov_flag = cov_flag + 1;
            if (CPU.pc_sel && CPU.id_is_jmp) cov_jmp = cov_jmp + 1;
            if (CPU.id_is_bz  && !CPU.stall) begin if (CPU.pc_sel) cov_bz_t = cov_bz_t + 1; else cov_bz_n = cov_bz_n + 1; end
            if (CPU.id_is_bnz && !CPU.stall) begin if (CPU.pc_sel) cov_bnz_t = cov_bnz_t + 1; else cov_bnz_n = cov_bnz_n + 1; end
            if (CPU.if_pc == 8'd255 && CPU.pc_en && !CPU.pc_sel) cov_wrap = cov_wrap + 1;
            if (CPU.carry_flag) cov_c1 = cov_c1 + 1;
        end
    end

    task run_lockstep; input integer n;
        integer guard;
        begin
            copy_to_models; target_retire = n; lockstep_done = 1'b0;
            rst <= 1'b1;
            @(negedge clk); @(posedge clk); @(posedge clk); @(negedge clk);
            rst <= 1'b0; lockstep_on = 1'b1; guard = 0;
            while (!lockstep_done && guard < 20 * n + 40) begin @(negedge clk); guard = guard + 1; end
            lockstep_on = 1'b0;
            if (!lockstep_done) begin
                errors = errors + 1; $display("  %t | FAIL | watchdog: %0d of %0d retired", $time, REF_WB.steps, n);
            end
            if (REF_WB.halted) begin                         // the CPU must stop as well
                repeat (5) @(negedge clk);
                ls_checks = ls_checks + 1;
                if (!halted || CPU.wb_valid) begin errors = errors + 1; $display("  %t | FAIL | lockstep: CPU did not halt", $time); end
            end
        end
    endtask

    function [15:0] random_instr; input integer dummy;
        reg [3:0] op; integer r;
        begin
            r = $unsigned($random(seed)) % 100;
            if      (r < 40) op = 4'h1 + ($unsigned($random(seed)) % 5);   // ADD..XOR
            else if (r < 46) op = 4'h6 + ($unsigned($random(seed)) % 2);   // SHL, SHR
            else if (r < 56) op = 4'h8;                                    // LDI
            else if (r < 64) op = 4'h9;                                    // ADDI
            else if (r < 74) op = 4'hA;                                    // LD
            else if (r < 82) op = 4'hB;                                    // ST
            else if (r < 85) op = 4'hC;                                    // JMP
            else if (r < 91) op = 4'hD;                                    // BZ
            else if (r < 97) op = 4'hE;                                    // BNZ
            else if (r < 99) op = 4'h0;                                    // NOP
            else             op = 4'hF;                                    // HLT
            random_instr = $random(seed);
            random_instr[15:12] = op;
            if (op >= 4'hC && op <= 4'hE) random_instr[7:0] = random_instr[7:0] % 32;  // stay in the program
        end
    endfunction

    // ------------------------------------------------------------------------
    // Expected lists (hand calculated from asm/*.asm)
    // ------------------------------------------------------------------------
    task setup_demo; begin n_exp = 0;
        e_reg(0,1,8'd5); e_reg(1,2,8'd3); e_reg(2,3,8'd8); e_reg(3,4,8'd2); e_reg(4,5,8'd10);
        e_reg(5,6,8'd20); e_reg(6,6,8'd120); e_ins(7); exp_halt_cycle = 12; end endtask
    task setup_arith; begin n_exp = 0;
        e_reg(0,1,8'd200); e_reg(1,2,8'd100); e_reg(2,3,8'd44); e_reg(3,4,8'd156); e_reg(4,5,8'd100);
        e_reg(5,6,8'd0); e_reg(6,7,8'd255); e_reg(7,7,8'd0); e_ins(8); exp_halt_cycle = 13; end endtask
    task setup_logic; begin n_exp = 0;
        e_reg(0,1,8'hF0); e_reg(1,2,8'h3C); e_reg(2,3,8'h30); e_reg(3,4,8'hFC); e_reg(4,5,8'hCC);
        e_reg(5,6,8'hE0); e_reg(6,7,8'h1E); e_reg(7,0,8'h00); e_ins(8); exp_halt_cycle = 13; end endtask
    task setup_mem; begin n_exp = 0;
        e_reg(0,1,8'h80); e_reg(1,2,8'h5A); e_mem(2,8'h80,8'h5A); e_reg(3,3,8'h5A); e_reg(4,4,8'hB4);
        e_reg(5,1,8'h81); e_mem(6,8'h81,8'hB4); e_reg(7,5,8'hB4); e_mem(8,8'h00,8'hB4); e_reg(9,6,8'hB4);
        e_ins(10); exp_halt_cycle = 17; end endtask
    task setup_branch; begin n_exp = 0;
        e_reg(0,1,8'd5); e_reg(1,2,8'd0);
        e_reg(2,2,8'd5);  e_reg(3,1,8'd4); e_ins(4);
        e_reg(2,2,8'd9);  e_reg(3,1,8'd3); e_ins(4);
        e_reg(2,2,8'd12); e_reg(3,1,8'd2); e_ins(4);
        e_reg(2,2,8'd14); e_reg(3,1,8'd1); e_ins(4);
        e_reg(2,2,8'd15); e_reg(3,1,8'd0); e_ins(4);
        e_ins(5); e_ins(7); e_reg(9,4,8'd1); e_reg(10,5,8'd0); e_ins(11); e_ins(12);
        exp_halt_cycle = 39; end endtask
    task setup_wrap; begin n_exp = 0;
        e_ins(0); e_reg(254,1,8'd7); e_reg(255,3,8'd0); e_ins(0); e_ins(1); exp_halt_cycle = 11; end endtask

    // ------------------------------------------------------------------------
    // Main sequence
    // ------------------------------------------------------------------------
    integer ok_cov;
    initial begin
        $timeformat(-9, 0, "", 6);
        if ($test$plusargs("vcd")) begin $dumpfile("tb_cpu.vcd"); $dumpvars(0, tb_cpu); end
        $display("============================================================================");
        $display(" tb_cpu : self-checking testbench for cpu_top (8-bit, 5-stage pipeline)");
        $display(" Student: Vu Quoc Anh | Roll number: SE203519");
        $display(" Course : Phase 1 Capstone | Lecturer: Shivashish Pal");
        $display(" Vivado : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");
        $display("\nPART 1: directed tests (rows 10 ns apart; row t is sampled at t + 5 ns)");
        invariant_on = 1'b1;

        $display("\n  --- reset values ---");
        rst <= 1'b1;
        @(negedge clk); @(posedge clk); @(posedge clk); @(negedge clk);
        check8("PC after reset", pc_out, 8'd0);
        check8("R0 after reset", CPU.RF.r0, 8'd0);
        check8("R7 after reset", CPU.RF.r7, 8'd0);
        check1("Zero after reset", zero_out, 1'b0);
        check1("Carry after reset", carry_out, 1'b0);
        check1("halted after reset", halted, 1'b0);
        check1("IF/ID empty after reset", CPU.id_valid, 1'b0);
        check1("ID/EX empty after reset", CPU.ex_valid, 1'b0);
        check1("EX/MEM empty after reset", CPU.mem_valid, 1'b0);
        check1("MEM/WB empty after reset", CPU.wb_valid, 1'b0);

        load_program("program.mem"); setup_demo; reset_cpu; run_directed("program.mem (demo)");
        check8("final R3 (5 + 3)", CPU.RF.r3, 8'd8);
        check8("final R5 (8 XOR 2)", CPU.RF.r5, 8'd10);
        check8("final R6 (10 << 1, + 100)", CPU.RF.r6, 8'd120);

        load_program("prog_arith.mem"); setup_arith; reset_cpu; run_directed("prog_arith.mem");
        check8("final R3 (200 + 100 mod 256)", CPU.RF.r3, 8'd44);
        check8("final R4 (100 - 200 mod 256)", CPU.RF.r4, 8'd156);
        check8("final R7 (255 + 1 mod 256)", CPU.RF.r7, 8'd0);
        check1("final Zero", zero_out, 1'b1);
        check1("final Carry (255 + 1)", carry_out, 1'b1);

        load_program("prog_logic.mem"); setup_logic; reset_cpu; run_directed("prog_logic.mem");
        check8("final R6 (F0 << 1)", CPU.RF.r6, 8'hE0);
        check8("final R7 (3C >> 1)", CPU.RF.r7, 8'h1E);
        check8("final R0 (ordinary register)", CPU.RF.r0, 8'h00);
        check1("final Zero", zero_out, 1'b1);
        check1("final Carry (from SHR: old bit 0)", carry_out, 1'b0);

        load_program("prog_mem.mem"); setup_mem; reset_cpu; run_directed("prog_mem.mem");
        check8("final M[80]", CPU.DMEM.mem[8'h80], 8'h5A);
        check8("final M[81]", CPU.DMEM.mem[8'h81], 8'hB4);
        check8("final M[00]", CPU.DMEM.mem[8'h00], 8'hB4);
        check8("final R6 (LD after ST)", CPU.RF.r6, 8'hB4);

        load_program("prog_branch.mem"); setup_branch; reset_cpu; run_directed("prog_branch.mem");
        check8("final R2 (5 + 4 + 3 + 2 + 1)", CPU.RF.r2, 8'd15);
        check8("final R1 (counter)", CPU.RF.r1, 8'd0);
        check8("final R3 (99 and 77 never ran)", CPU.RF.r3, 8'd0);
        check8("final R6 (after HLT never ran)", CPU.RF.r6, 8'd0);
        check8("PC frozen at HLT + 1", pc_out, 8'd13);
        check1("final Zero", zero_out, 1'b1);

        load_program("prog_wrap.mem"); setup_wrap; reset_cpu; run_directed("prog_wrap.mem");
        check8("final R1 (address 254)", CPU.RF.r1, 8'd7);
        check1("final Zero (SUB R3,R3,R3)", zero_out, 1'b1);

        $display("\n  --- reset while a ST is in MEM ---");
        load_program("prog_mem.mem"); reset_cpu;
        k = 0;
        while (!(CPU.mem_valid && CPU.mem_pc == 8'd2) && k < 100) begin @(negedge clk); k = k + 1; end
        if (k >= 100) begin errors = errors + 1; $display("  FAIL | watchdog: ST never reached MEM"); end
        $display("  %t | info | ST R2,[R1] is in MEM in cycle %0d; reset is asserted now", $time, cycle);
        rst <= 1'b1;
        @(posedge clk); #1;
        check8("M[80] not written by the abandoned ST", CPU.DMEM.mem[8'h80], 8'h00);
        reset_cpu;
        $display("\n  --- reset after HLT ---");
        load_program("program.mem"); reset_cpu;
        k = 0;
        while (!halted && k < 100) begin @(negedge clk); k = k + 1; end
        if (k >= 100) begin errors = errors + 1; $display("  FAIL | watchdog: CPU never halted"); end
        @(negedge clk); rst <= 1'b1; @(posedge clk); @(negedge clk); rst <= 1'b0;
        check1("halted cleared by reset", halted, 1'b0);
        check8("PC after reset", pc_out, 8'd0);
        $display("  Part 1: %0d directed checks, %0d errors so far", checks, errors);

        $display("\nPART 2: lockstep against isa_reference_model (independent ISA model)");
        load_program("program.mem");     run_lockstep(64);
        load_program("prog_arith.mem");  run_lockstep(64);
        load_program("prog_logic.mem");  run_lockstep(64);
        load_program("prog_mem.mem");    run_lockstep(64);
        load_program("prog_branch.mem"); run_lockstep(64);
        load_program("prog_wrap.mem");   run_lockstep(64);
        $display("  6 directed programs in lockstep: %0d comparisons, %0d errors so far", ls_checks, errors);
        $display("  300 random programs (seed %h), up to 64 retirements each ...", seed);
        for (k = 0; k < 300; k = k + 1) begin
            for (i = 0; i < 256; i = i + 1) begin
                CPU.IMEM.mem[i] = (i < 32) ? random_instr(0) : 16'h0000;
                CPU.DMEM.mem[i] = $random(seed);
            end
            run_lockstep(64);
        end
        $display("  random programs done: %0d lockstep comparisons, %0d invariant checks", ls_checks, inv_checks);
        $display("\n  coverage goals (each must be > 0)");
        $display("    forward A from MEM : %6d    forward A from WB : %6d", cov_fa_mem, cov_fa_wb);
        $display("    forward B from MEM : %6d    forward B from WB : %6d", cov_fb_mem, cov_fb_wb);
        $display("    RF bypass (dist 3) : %6d    flag stall        : %6d", cov_bypass, cov_flag);
        $display("    load-use, port A   : %6d    load-use, port B  : %6d", cov_lu_a, cov_lu_b);
        $display("    JMP taken          : %6d    HLT retired       : %6d", cov_jmp, cov_hlt);
        $display("    BZ taken / not     : %0d / %0d", cov_bz_t, cov_bz_n);
        $display("    BNZ taken / not    : %0d / %0d", cov_bnz_t, cov_bnz_n);
        $display("    LD / ST retired    : %0d / %0d", cov_ld, cov_st);
        $display("    SHL/SHR, ADDI      : %0d, %0d", cov_shift, cov_addi);
        $display("    PC wrap 255 -> 0   : %6d    cycles with C = 1 : %6d", cov_wrap, cov_c1);
        ok_cov = cov_fa_mem > 0 && cov_fa_wb > 0 && cov_fb_mem > 0 && cov_fb_wb > 0 && cov_bypass > 0 &&
                 cov_flag > 0 && cov_lu_a > 0 && cov_lu_b > 0 && cov_jmp > 0 && cov_hlt > 0 && cov_bz_t > 0 &&
                 cov_bz_n > 0 && cov_bnz_t > 0 && cov_bnz_n > 0 && cov_ld > 0 && cov_st > 0 && cov_shift > 0 &&
                 cov_addi > 0 && cov_wrap > 0 && cov_c1 > 0;
        if (!ok_cov) begin errors = errors + 1; $display("  FAIL | a coverage goal was not reached"); end
        else $display("  PASS | every coverage goal reached");
        #1;                     // let every process of the last falling edge finish first
        $display("\n============================================================================");
        if (errors == 0)
            $display("PASS: tb_cpu (Vu Quoc Anh, SE203519) %0d directed + %0d lockstep + %0d invariant checks, 0 errors",
                     checks, ls_checks, inv_checks);
        else
            $display("FAILED: tb_cpu (Vu Quoc Anh, SE203519) %0d errors in %0d directed + %0d lockstep + %0d invariant checks",
                     errors, checks, ls_checks, inv_checks);
        $finish(0);
    end

endmodule

`default_nettype wire
