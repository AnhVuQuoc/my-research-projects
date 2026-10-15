// =============================================================================
// File        : tb_cpu.v
// Module      : tb_cpu   (self-checking testbench for cpu_top)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Clock       : rising edges at 10, 20, 30 ... ns (period 10 ns). One table
//               row = one clock cycle. A row labeled t is sampled at t + 5 ns
//               (falling edge), so it shows the state AFTER the rising edge
//               at t and BEFORE the next one: put the waveform cursor at t+5.
// Part 1      : directed. Reset values, then 5 programs. Every cycle the
//               instruction leaving WB (retiring) is compared with a hand
//               calculated expected stream: bubbles, address, register or
//               memory write. Final registers and flags are checked too.
// Part 2      : (a) the 5 programs again in LOCKSTEP with an independent ISA
//               reference model, (b) 300 random programs in lockstep,
//               (c) pipeline protocol invariants every cycle, (d) coverage
//               goals that must all be reached.
// Vivado      : press "Run All" (the run ends by itself with $finish).
// Waveform    : Icarus: vvp tb_cpu.vvp +vcd  ->  tb_cpu.vcd (Part 1 only)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_cpu;

    // ------------------------------------------------------------------------
    // Clock, reset, DUT
    // ------------------------------------------------------------------------
    reg clk = 1'b0;
    reg rst = 1'b1;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end  // rise at 10, 20 ...

    wire [3:0]  pc_out, alu_out, wb_data_out;
    wire [11:0] instr_out;
    wire        zero_out, carry_out;

    cpu_top #(.PROGRAM_FILE("program.mem")) CPU (
        .clk(clk), .rst(rst),
        .pc_out(pc_out), .instr_out(instr_out), .alu_out(alu_out),
        .wb_data_out(wb_data_out), .zero_out(zero_out), .carry_out(carry_out)
    );

    // Two copies of the golden model: REF_WB is compared when an instruction
    // retires (registers, memory, write data); REF_MEM is compared when an
    // instruction is in MEM, because that is when its flags are visible.
    isa_reference_model REF_WB  ();
    isa_reference_model REF_MEM ();

    // ------------------------------------------------------------------------
    // Book-keeping
    // ------------------------------------------------------------------------
    integer errors      = 0;
    integer checks      = 0;   // directed checks (Part 1)
    integer ls_checks   = 0;   // lockstep comparisons (Part 2)
    integer inv_checks  = 0;   // invariant evaluations (Part 1 + Part 2)
    integer cycle       = 0;   // cycle in progress (1 = first cycle after reset)
    integer i, p, k;
    integer seed        = 32'h5E203519;

    always @(posedge clk) begin
        if (rst) cycle <= 1;
        else     cycle <= cycle + 1;
    end

    // ------------------------------------------------------------------------
    // Small helpers: disassembler and string padding (for readable tables)
    // ------------------------------------------------------------------------
    function [8*12:1] left;                  // left-align a string in 12 chars
        input [8*12:1] s;
        integer n;
        begin
            left = s;
            for (n = 0; n < 12; n = n + 1)
                if (left[96:89] == 8'h00) left = {left[88:1], 8'h20};
        end
    endfunction

    function [8*12:1] disasm;
        input [11:0] w;
        reg   [8*12:1] s;
        begin
            case (w[11:8])
                4'h0: $sformat(s, "ADD R%0d,R%0d", w[7:6], w[5:4]);
                4'h1: $sformat(s, "SUB R%0d,R%0d", w[7:6], w[5:4]);
                4'h2: $sformat(s, "AND R%0d,R%0d", w[7:6], w[5:4]);
                4'h3: $sformat(s, "OR R%0d,R%0d",  w[7:6], w[5:4]);
                4'h4: $sformat(s, "XOR R%0d,R%0d", w[7:6], w[5:4]);
                4'h5: $sformat(s, "NOT R%0d",      w[7:6]);
                4'h6: $sformat(s, "LDI R%0d,%0d",  w[7:6], w[3:0]);
                4'h7: $sformat(s, "MOV R%0d,R%0d", w[7:6], w[5:4]);
                4'h8: $sformat(s, "LOAD R%0d,%0d", w[7:6], w[3:0]);
                4'h9: $sformat(s, "STORE R%0d,%0d",w[7:6], w[3:0]);
                4'hA: $sformat(s, "JMP %0d",       w[3:0]);
                4'hB: $sformat(s, "JZ %0d",        w[3:0]);
                default: $sformat(s, "NOP");
            endcase
            disasm = left(s);
        end
    endfunction

    // which register fields an instruction really reads (for invariants and
    // coverage only; written from the ISA table, independent of the RTL)
    function reads_rd; input [3:0] op;
        reads_rd = (op <= 4'h5) || (op == 4'h9);
    endfunction
    function reads_rs; input [3:0] op;
        reads_rs = (op <= 4'h4) || (op == 4'h7);
    endfunction

    // ------------------------------------------------------------------------
    // Expected retire stream for Part 1 (filled by the setup_* tasks)
    // kind 0 = bubble, 1 = instruction without write, 2 = register write,
    //      3 = memory write (checked in dmem one edge after the store)
    // ------------------------------------------------------------------------
    reg [1:0] exp_kind  [0:63];
    reg [3:0] exp_addr  [0:63];
    reg [1:0] exp_rd    [0:63];
    reg [3:0] exp_val   [0:63];
    reg [3:0] exp_maddr [0:63];
    integer   n_exp;

    task e_bub; begin
        exp_kind[n_exp] = 2'd0; n_exp = n_exp + 1; end endtask
    task e_ins; input [3:0] a; begin
        exp_kind[n_exp] = 2'd1; exp_addr[n_exp] = a; n_exp = n_exp + 1; end endtask
    task e_reg; input [3:0] a; input [1:0] rd; input [3:0] v; begin
        exp_kind[n_exp] = 2'd2; exp_addr[n_exp] = a; exp_rd[n_exp] = rd;
        exp_val[n_exp] = v; n_exp = n_exp + 1; end endtask
    task e_mem; input [3:0] a; input [3:0] ma; input [3:0] v; begin
        exp_kind[n_exp] = 2'd3; exp_addr[n_exp] = a; exp_maddr[n_exp] = ma;
        exp_val[n_exp] = v; n_exp = n_exp + 1; end endtask
    task e_fill; begin e_bub; e_bub; e_bub; e_bub; end endtask   // cycles 1-4

    // ------------------------------------------------------------------------
    // Directed check helpers
    // ------------------------------------------------------------------------
    task check4;
        input [8*40:1] name; input [3:0] actual; input [3:0] expected;
        begin
            checks = checks + 1;
            if (actual === expected)
                $display("  %t | PASS | %0s = %b", $time, name, actual);
            else begin
                $display("  %t | FAIL | %0s = %b (expected %b)", $time, name, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    task check1;
        input [8*40:1] name; input actual; input expected;
        begin
            checks = checks + 1;
            if (actual === expected)
                $display("  %t | PASS | %0s = %b", $time, name, actual);
            else begin
                $display("  %t | FAIL | %0s = %b (expected %b)", $time, name, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    // ------------------------------------------------------------------------
    // Program loading and reset
    // ------------------------------------------------------------------------
    task clear_memories;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                CPU.IMEM.mem[i] = 12'hC00;
                CPU.DMEM.mem[i] = 4'h0;
            end
        end
    endtask

    task load_program;
        input [8*20:1] file_name;
        begin
            clear_memories;
            $readmemh(file_name, CPU.IMEM.mem);
        end
    endtask

    task copy_to_models;        // the models get the same program and data
        begin
            for (i = 0; i < 16; i = i + 1) begin
                REF_WB.imem[i]  = CPU.IMEM.mem[i];  REF_WB.dmem[i]  = CPU.DMEM.mem[i];
                REF_MEM.imem[i] = CPU.IMEM.mem[i];  REF_MEM.dmem[i] = CPU.DMEM.mem[i];
            end
            REF_WB.reset_state;
            REF_MEM.reset_state;
        end
    endtask

    // reset for 2 rising edges, release at the falling edge of cycle 1
        task reset_cpu;
        begin
            rst <= 1'b1;
            @(negedge clk); @(posedge clk); @(posedge clk);
            @(negedge clk);
            rst <= 1'b0;
        end
    endtask

    // ------------------------------------------------------------------------
    // Part 1 engine: run one program cycle by cycle and check the WB stream
    // ------------------------------------------------------------------------
    task print_header;
        begin
            $display("  time  | cyc | IF | ID | EX | MEM| WB | retiring     | st fl fA fB | WB write    | check");
            $display("  ------+-----+----+----+----+----+----+--------------+-------------+-------------+------");
        end
    endtask

    task run_directed;
        input [8*32:1] title;
        reg ok;
        reg [8*12:1] wtxt;
        begin
            $display("\n  --- %0s: %0d cycles, expected stream written by hand ---", title, n_exp);
            print_header;
            for (k = 0; k < n_exp; k = k + 1) begin
                if (k > 0) @(negedge clk);       // k = 0 is the release edge itself
                checks = checks + 1;
                case (exp_kind[k])
                    2'd0: ok = !CPU.wb_valid;
                    2'd1: ok =  CPU.wb_valid && CPU.wb_pc == exp_addr[k] && !CPU.wb_reg_we;
                    2'd2: ok =  CPU.wb_valid && CPU.wb_pc == exp_addr[k] && CPU.wb_reg_we &&
                                CPU.wb_rd == exp_rd[k] && CPU.wb_data == exp_val[k];
                    default: ok = CPU.wb_valid && CPU.wb_pc == exp_addr[k] && !CPU.wb_reg_we &&
                                CPU.DMEM.mem[exp_maddr[k]] == exp_val[k];
                endcase
                if (!CPU.wb_valid)              wtxt = left("-");
                else if (CPU.wb_reg_we)         $sformat(wtxt, "R%0d=%b", CPU.wb_rd, CPU.wb_data);
                else if (exp_kind[k] == 2'd3)   $sformat(wtxt, "M[%0d]=%b", exp_maddr[k],
                                                         CPU.DMEM.mem[exp_maddr[k]]);
                else                            wtxt = left("none");
                $display("  %t | %3d | %2d | %2s | %2s | %2s | %2s | %s | %b  %b  %0d  %0d  | %s| %0s",
                    $time - 5, cycle, CPU.if_pc,
                    CPU.id_valid  ? addr_txt(CPU.id_pc)  : "--",
                    CPU.ex_valid  ? addr_txt(CPU.ex_pc)  : "--",
                    CPU.mem_valid ? addr_txt(CPU.mem_pc) : "--",
                    CPU.wb_valid  ? addr_txt(CPU.wb_pc)  : "--",
                    CPU.wb_valid  ? disasm(CPU.wb_instr) : left("bubble"),
                    CPU.stall, CPU.flush, CPU.fwd_a_sel, CPU.fwd_b_sel,
                    left(wtxt), ok ? "PASS" : "FAIL");
                if (!ok) errors = errors + 1;
            end
            @(posedge clk); #1;                  // let the last write happen
        end
    endtask

    function [8*2:1] addr_txt; input [3:0] a;
        reg [7:0] tens, ones;
        begin
            tens = 8'h30 + (a / 4'd10);
            ones = 8'h30 + (a % 4'd10);
            if (a < 4'd10) tens = 8'h20;        // leading space instead of 0
            addr_txt = {tens, ones};
        end
    endfunction

    // ------------------------------------------------------------------------
    // Expected streams, calculated by hand from the pipeline rules:
    //   instruction k (1st, 2nd ...) retires in cycle 4 + k + bubbles before it
    //   stall  -> 1 bubble just BEFORE the stalled instruction
    //   taken  -> 1 bubble just AFTER the branch (the flushed fetch)
    // ------------------------------------------------------------------------
    task setup_demo;        // program.mem (plan Appendix A)
        begin n_exp = 0; e_fill;
            e_reg(0, 1, 4'b0101);  e_reg(1, 2, 4'b0011);  e_reg(2, 1, 4'b1000);
            e_reg(3, 3, 4'b1010);  e_reg(4, 1, 4'b0010);
            e_ins(5); e_bub; e_ins(5); e_bub; e_ins(5);           // JMP 5 loop
        end
    endtask

    task setup_arith;       // prog_arith.mem: no hazard needs a stall
        begin n_exp = 0; e_fill;
            e_reg(0, 1, 4'b0101);  e_reg(1, 2, 4'b0011);  e_reg(2, 1, 4'b1000);
            e_mem(3, 0, 4'b1000);  e_reg(4, 1, 4'b0101);  e_reg(5, 1, 4'b0010);
            e_mem(6, 1, 4'b0010);  e_reg(7, 0, 4'b1000);  e_reg(8, 2, 4'b0000);
            e_ins(9);
        end
    endtask

    task setup_logic;       // prog_logic.mem: no stalls, distance-1 forwarding
        begin n_exp = 0; e_fill;
            e_reg(0, 1, 4'b1100);  e_reg(1, 2, 4'b1010);  e_reg(2, 3, 4'b1100);
            e_reg(3, 3, 4'b1000);  e_reg(4, 3, 4'b1100);  e_reg(5, 3, 4'b1110);
            e_reg(6, 1, 4'b0110);  e_reg(7, 2, 4'b0110);  e_reg(8, 0, 4'b0101);
            e_reg(9, 0, 4'b1010);  e_reg(10, 3, 4'b1010); e_reg(11, 3, 4'b0000);
            e_ins(12);
        end
    endtask

    task setup_jump;        // prog_jump.mem: JMP, taken JZ, not-taken JZ
        begin n_exp = 0; e_fill;
            e_reg(0, 0, 4'd1);  e_ins(1);  e_bub;                 // JMP 4 flush
            e_reg(4, 1, 4'd7);  e_reg(5, 1, 4'd0);  e_bub;        // flag stall
            e_ins(6);  e_bub;                                     // JZ 9 taken
            e_reg(9, 3, 4'd2);  e_reg(10, 3, 4'd4); e_bub;        // flag stall
            e_ins(11);                                            // JZ 14 not taken
            e_reg(12, 2, 4'd6); e_ins(13);
        end
    endtask

    task setup_hazard;      // prog_hazard.mem: every hazard type
        begin n_exp = 0; e_fill;
            e_reg(0, 1, 4'd3);  e_reg(1, 2, 4'd1);  e_reg(2, 3, 4'd2);
            e_reg(3, 1, 4'd4);  e_reg(4, 1, 4'd6);  e_mem(5, 5, 4'd6);
            e_reg(6, 2, 4'd6);  e_bub;                            // load-use
            e_reg(7, 2, 4'd0);  e_bub;                            // flag stall
            e_ins(8);  e_bub;                                     // JZ 10 taken
            e_reg(10, 3, 4'd9); e_ins(11); e_bub;                 // JZ 13 taken
            e_reg(13, 0, 4'd6); e_bub;                            // LOAD -> STORE
            e_mem(14, 0, 4'd6); e_ins(15);
        end
    endtask

    // ------------------------------------------------------------------------
    // Part 2 engine: lockstep comparison, invariants and coverage
    // ------------------------------------------------------------------------
    reg     lockstep_on  = 1'b0;
    reg     invariant_on = 1'b0;
    integer target_retire;
    reg     lockstep_done = 1'b0;

    // coverage counters
    integer cov_fwd_a_mem = 0, cov_fwd_a_wb = 0, cov_fwd_b_mem = 0, cov_fwd_b_wb = 0;
    integer cov_bypass = 0, cov_load_use = 0, cov_flag_stall = 0;
    integer cov_jmp = 0, cov_jz_taken = 0, cov_jz_not = 0, cov_wrap = 0;
    integer cov_load = 0, cov_store = 0, cov_nop = 0, cov_carry1 = 0;

    // previous-cycle values for the hold / flush invariants
    reg        prev_valid_sample = 1'b0;
    reg        prev_stall, prev_flush;
    reg [3:0]  prev_pc, prev_id_pc;
    reg [11:0] prev_id_instr;
    reg        prev_id_valid;

    task inv_fail; input [8*48:1] what;
        begin
            errors = errors + 1;
            $display("  %t | FAIL | invariant: %0s", $time, what);
        end
    endtask

    always @(negedge clk) begin
        // ---------------- pipeline protocol invariants ----------------
        if (invariant_on && !rst) begin
            inv_checks = inv_checks + 1;
            if ((^{CPU.if_pc, CPU.id_instr, CPU.ex_instr, CPU.mem_instr, CPU.wb_instr,
                   CPU.RF.r0, CPU.RF.r1, CPU.RF.r2, CPU.RF.r3, CPU.zero_flag,
                   CPU.carry_flag, CPU.stall, CPU.flush, wb_data_out}) === 1'bx)
                inv_fail("X value on a key signal");
            if (CPU.pc_sel && CPU.stall)
                inv_fail("branch taken while stalled");
            if (prev_valid_sample && prev_stall &&
                (CPU.if_pc !== prev_pc || CPU.id_instr !== prev_id_instr ||
                 CPU.id_valid !== prev_id_valid || CPU.ex_valid !== 1'b0))
                inv_fail("stall did not freeze PC/IF-ID or insert a bubble");
            if (prev_valid_sample && prev_flush && CPU.id_valid !== 1'b0)
                inv_fail("flush did not empty IF/ID");
            if (CPU.ex_valid && CPU.mem_wb_sel && CPU.mem_reg_we &&
                ((reads_rd(CPU.ex_instr[11:8]) && CPU.fwd_a_sel == 2'b10) ||
                 (reads_rs(CPU.ex_instr[11:8]) && CPU.ex_alu_src_sel == 1'b0 &&
                  CPU.fwd_b_sel == 2'b10)))
                inv_fail("LOAD result forwarded from MEM (too early)");
            prev_valid_sample = 1'b1;
            prev_stall = CPU.stall;  prev_flush = CPU.flush;
            prev_pc = CPU.if_pc;     prev_id_instr = CPU.id_instr;
            prev_id_valid = CPU.id_valid;
        end
        else prev_valid_sample = 1'b0;

        // ---------------- lockstep comparison ----------------
        if (lockstep_on && !rst && !lockstep_done) begin
            // (1) flags: compare when an instruction is in MEM
            if (CPU.mem_valid) begin
                REF_MEM.step;
                ls_checks = ls_checks + 1;
                if (CPU.mem_pc !== REF_MEM.last_pc || CPU.zero_flag !== REF_MEM.zf ||
                    CPU.carry_flag !== REF_MEM.cf) begin
                    errors = errors + 1;
                    $display("  %t | FAIL | lockstep MEM: pc %0d/%0d Z %b/%b C %b/%b (cpu/ref)",
                             $time, CPU.mem_pc, REF_MEM.last_pc, CPU.zero_flag, REF_MEM.zf,
                             CPU.carry_flag, REF_MEM.cf);
                end
            end
            // (2) registers before the write, then the write, then memory
            if (CPU.wb_valid) begin
                ls_checks = ls_checks + 1;
                if (CPU.RF.r0 !== REF_WB.r[0] || CPU.RF.r1 !== REF_WB.r[1] ||
                    CPU.RF.r2 !== REF_WB.r[2] || CPU.RF.r3 !== REF_WB.r[3]) begin
                    errors = errors + 1;
                    $display("  %t | FAIL | lockstep WB: registers differ before pc %0d", $time, CPU.wb_pc);
                end
                REF_WB.step;
                ls_checks = ls_checks + 1;
                if (CPU.wb_pc !== REF_WB.last_pc || CPU.wb_reg_we !== REF_WB.last_reg_we ||
                    (REF_WB.last_reg_we && (CPU.wb_rd !== REF_WB.last_rd ||
                                            CPU.wb_data !== REF_WB.last_value))) begin
                    errors = errors + 1;
                    $display("  %t | FAIL | lockstep WB: pc %0d/%0d we %b/%b rd %0d/%0d data %b/%b",
                             $time, CPU.wb_pc, REF_WB.last_pc, CPU.wb_reg_we, REF_WB.last_reg_we,
                             CPU.wb_rd, REF_WB.last_rd, CPU.wb_data, REF_WB.last_value);
                end
                for (p = 0; p < 16; p = p + 1) begin
                    ls_checks = ls_checks + 1;
                    if (CPU.DMEM.mem[p] !== REF_WB.dmem[p]) begin
                        errors = errors + 1;
                        $display("  %t | FAIL | lockstep WB: dmem[%0d] %b/%b", $time, p,
                                 CPU.DMEM.mem[p], REF_WB.dmem[p]);
                    end
                end
                // retire-based coverage
                if (CPU.wb_instr[11:8] == 4'h8) cov_load  = cov_load + 1;
                if (CPU.wb_instr[11:8] == 4'h9) cov_store = cov_store + 1;
                if (CPU.wb_instr[11:8] >= 4'hC) cov_nop   = cov_nop + 1;
                if (REF_WB.steps >= target_retire) lockstep_done = 1'b1;
            end
            // event coverage (only on real instructions)
            if (CPU.ex_valid && reads_rd(CPU.ex_instr[11:8])) begin
                if (CPU.fwd_a_sel == 2'b10) cov_fwd_a_mem = cov_fwd_a_mem + 1;
                if (CPU.fwd_a_sel == 2'b01) cov_fwd_a_wb  = cov_fwd_a_wb + 1;
            end
            if (CPU.ex_valid && reads_rs(CPU.ex_instr[11:8])) begin
                if (CPU.fwd_b_sel == 2'b10) cov_fwd_b_mem = cov_fwd_b_mem + 1;
                if (CPU.fwd_b_sel == 2'b01) cov_fwd_b_wb  = cov_fwd_b_wb + 1;
            end
            if (CPU.id_valid && CPU.wb_reg_we &&
                ((reads_rd(CPU.id_instr[11:8]) && CPU.id_rd == CPU.wb_rd) ||
                 (reads_rs(CPU.id_instr[11:8]) && CPU.id_rs == CPU.wb_rd)))
                cov_bypass = cov_bypass + 1;
            if (CPU.load_use_stall) cov_load_use   = cov_load_use + 1;
            if (CPU.flag_stall)     cov_flag_stall = cov_flag_stall + 1;
            if (CPU.pc_sel && CPU.id_is_jmp) cov_jmp      = cov_jmp + 1;
            if (CPU.pc_sel && CPU.id_is_jz)  cov_jz_taken = cov_jz_taken + 1;
            if (CPU.id_valid && CPU.id_is_jz && !CPU.stall && !CPU.zero_flag)
                cov_jz_not = cov_jz_not + 1;
            if (CPU.if_pc == 4'd15 && CPU.pc_en && !CPU.pc_sel) cov_wrap = cov_wrap + 1;
            if (CPU.carry_flag) cov_carry1 = cov_carry1 + 1;
        end
    end

    // run the program now in CPU.IMEM / CPU.DMEM in lockstep for n retirements
    task run_lockstep;
        input integer n;
        integer guard;
        begin
            copy_to_models;
            target_retire = n;
            lockstep_done = 1'b0;
            rst <= 1'b1;
            @(negedge clk); @(posedge clk); @(posedge clk); @(negedge clk);
            rst <= 1'b0;
            lockstep_on = 1'b1;
            guard = 0;
            while (!lockstep_done && guard < 20 * n + 20) begin
                @(negedge clk); guard = guard + 1;
            end
            lockstep_on = 1'b0;
            if (!lockstep_done) begin
                errors = errors + 1;
                $display("  %t | FAIL | watchdog: only %0d of %0d instructions retired",
                         $time, REF_WB.steps, n);
            end
        end
    endtask

    // one random instruction: mostly ALU / memory, some jumps and NOPs
    function [11:0] random_instr;
        input integer dummy;
        reg [3:0] op;
        integer   r;
        begin
            r  = $unsigned($random(seed)) % 100;
            if      (r < 55) op = $unsigned($random(seed)) % 6;       // ADD..NOT
            else if (r < 65) op = 4'h6;                               // LDI
            else if (r < 70) op = 4'h7;                               // MOV
            else if (r < 80) op = 4'h8;                               // LOAD
            else if (r < 88) op = 4'h9;                               // STORE
            else if (r < 92) op = 4'hA;                               // JMP
            else if (r < 98) op = 4'hB;                               // JZ
            else             op = 4'hC + ($unsigned($random(seed)) % 4); // reserved
            random_instr = {op, $random(seed)} & 12'hFFF;
            random_instr[11:8] = op;
        end
    endfunction

    // ------------------------------------------------------------------------
    // Main sequence
    // ------------------------------------------------------------------------
    integer ok_cov;
    initial begin
        $timeformat(-9, 0, "", 6);
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_cpu.vcd");
            $dumpvars(0, tb_cpu);
        end
        $display("============================================================================");
        $display(" tb_cpu : self-checking testbench for cpu_top (5-stage pipeline)");
        $display(" Student: Vu Quoc Anh | Roll number: SE203519");
        $display(" Course : Phase 1 Capstone | Lecturer: Shivashish Pal");
        $display(" Vivado : press \"Run All\" (the run ends by itself with $finish)");
        $display("============================================================================");

        // ================= PART 1: directed =================
        $display("\nPART 1: directed tests (rows 10 ns apart; row t is sampled at t + 5 ns)");
        invariant_on = 1'b1;

        $display("\n  --- reset values ---");
        rst <= 1'b1;
        @(negedge clk); @(posedge clk); @(posedge clk); @(negedge clk);
        check4("PC after reset", pc_out, 4'd0);
        check4("R0 after reset", CPU.RF.r0, 4'd0);
        check4("R3 after reset", CPU.RF.r3, 4'd0);
        check1("Zero after reset", zero_out, 1'b0);
        check1("Carry after reset", carry_out, 1'b0);
        check1("IF/ID empty after reset", CPU.id_valid, 1'b0);
        check1("ID/EX empty after reset", CPU.ex_valid, 1'b0);
        check1("EX/MEM empty after reset", CPU.mem_valid, 1'b0);
        check1("MEM/WB empty after reset", CPU.wb_valid, 1'b0);

        load_program("program.mem");  setup_demo;
        reset_cpu;                     run_directed("program.mem (demonstration)");
        check4("final R1", CPU.RF.r1, 4'b0010);
        check4("final R2", CPU.RF.r2, 4'b0011);
        check4("final R3", CPU.RF.r3, 4'b1010);

        load_program("prog_arith.mem"); setup_arith;
        reset_cpu;                      run_directed("prog_arith.mem");
        check4("final R0 (LOAD of M[0])", CPU.RF.r0, 4'b1000);
        check4("final R1", CPU.RF.r1, 4'b0010);
        check4("final R2 (SUB R2,R2)", CPU.RF.r2, 4'b0000);
        check1("final Zero", zero_out, 1'b1);
        check1("final Carry (3-3: no borrow)", carry_out, 1'b1);

        load_program("prog_logic.mem"); setup_logic;
        reset_cpu;                      run_directed("prog_logic.mem");
        check4("final R0 (NOT 0101)", CPU.RF.r0, 4'b1010);
        check4("final R1 (XOR)", CPU.RF.r1, 4'b0110);
        check4("final R2 (MOV)", CPU.RF.r2, 4'b0110);
        check4("final R3 (XOR R3,R3)", CPU.RF.r3, 4'b0000);
        check1("final Zero", zero_out, 1'b1);
        check1("final Carry (never written)", carry_out, 1'b0);

        load_program("prog_jump.mem");  setup_jump;
        reset_cpu;                      run_directed("prog_jump.mem");
        check4("final R0 (JMP skipped 2, 3)", CPU.RF.r0, 4'd1);
        check4("final R1", CPU.RF.r1, 4'd0);
        check4("final R2 (7, 8, 14 never ran)", CPU.RF.r2, 4'd6);
        check4("final R3", CPU.RF.r3, 4'd4);
        check1("final Zero (ADD R3,R3 = 4)", zero_out, 1'b0);

        load_program("prog_hazard.mem"); setup_hazard;
        reset_cpu;                       run_directed("prog_hazard.mem");
        check4("final R0 (LOAD after JZ)", CPU.RF.r0, 4'd6);
        check4("final R1 (3 + 1 + 2)", CPU.RF.r1, 4'd6);
        check4("final R2 (6 - 6)", CPU.RF.r2, 4'd0);
        check4("final R3 (9 never 15)", CPU.RF.r3, 4'd9);
        check4("final M[5]", CPU.DMEM.mem[5], 4'd6);
        check4("final M[0] (LOAD -> STORE)", CPU.DMEM.mem[0], 4'd6);
        check1("final Zero", zero_out, 1'b1);
        check1("final Carry", carry_out, 1'b1);

        $display("\n  --- reset while a STORE is in MEM (bug found by Part 2, now fixed) ---");
        load_program("prog_arith.mem");
        reset_cpu;
        while (!(CPU.mem_valid && CPU.mem_pc == 4'd3)) @(negedge clk);  // STORE R1,0 in MEM
        $display("  %t | info | STORE R1,0 is in MEM in cycle %0d; reset is asserted now", $time, cycle);
        rst <= 1'b1;
        @(posedge clk); #1;
        check4("M[0] not written by the abandoned STORE", CPU.DMEM.mem[0], 4'b0000);
        reset_cpu;

        $display("\n  --- reset in the middle of a running program ---");
        load_program("prog_hazard.mem");
        repeat (12) @(negedge clk);
        @(negedge clk); rst <= 1'b1; @(posedge clk); @(negedge clk);
        check4("PC after reset", pc_out, 4'd0);
        check4("R0 after reset", CPU.RF.r0, 4'd0);
        check1("Zero after reset", zero_out, 1'b0);
        check1("Carry after reset", carry_out, 1'b0);
        check1("pipeline empty (ID/EX)", CPU.ex_valid, 1'b0);
        check1("pipeline empty (MEM/WB)", CPU.wb_valid, 1'b0);
        $display("  Part 1: %0d directed checks, %0d errors so far", checks, errors);

        // ================= PART 2: lockstep, random, invariants =================
        if ($test$plusargs("vcd")) $dumpoff;      // keep the waveform file small (Part 1 only)
        $display("\nPART 2: lockstep against isa_reference_model (independent ISA model)");
        load_program("program.mem");     run_lockstep(40);
        load_program("prog_arith.mem");  run_lockstep(40);
        load_program("prog_logic.mem");  run_lockstep(40);
        load_program("prog_jump.mem");   run_lockstep(40);
        load_program("prog_hazard.mem"); run_lockstep(40);
        $display("  5 directed programs in lockstep: %0d comparisons, %0d errors so far",
                 ls_checks, errors);

        $display("  300 random programs (seed %h), 64 retirements each ...", seed);
        for (k = 0; k < 300; k = k + 1) begin
            for (i = 0; i < 16; i = i + 1) begin
                CPU.IMEM.mem[i] = random_instr(0);
                CPU.DMEM.mem[i] = $random(seed);
            end
            run_lockstep(64);
        end
        $display("  random programs done: %0d lockstep comparisons, %0d invariant checks",
                 ls_checks, inv_checks);

        $display("\n  coverage goals (each must be > 0)");
        $display("    forward A from MEM : %6d    forward A from WB : %6d", cov_fwd_a_mem, cov_fwd_a_wb);
        $display("    forward B from MEM : %6d    forward B from WB : %6d", cov_fwd_b_mem, cov_fwd_b_wb);
        $display("    RF bypass (dist 3) : %6d    load-use stall    : %6d", cov_bypass, cov_load_use);
        $display("    flag stall (JZ)    : %6d    JMP taken         : %6d", cov_flag_stall, cov_jmp);
        $display("    JZ taken           : %6d    JZ not taken      : %6d", cov_jz_taken, cov_jz_not);
        $display("    PC wrap 15 -> 0    : %6d    LOAD / STORE      : %0d / %0d", cov_wrap, cov_load, cov_store);
        $display("    reserved opcode    : %6d    cycles with C = 1 : %6d", cov_nop, cov_carry1);
        ok_cov = (cov_fwd_a_mem > 0) && (cov_fwd_a_wb > 0) && (cov_fwd_b_mem > 0) &&
                 (cov_fwd_b_wb > 0) && (cov_bypass > 0) && (cov_load_use > 0) &&
                 (cov_flag_stall > 0) && (cov_jmp > 0) && (cov_jz_taken > 0) &&
                 (cov_jz_not > 0) && (cov_wrap > 0) && (cov_load > 0) &&
                 (cov_store > 0) && (cov_nop > 0) && (cov_carry1 > 0);
        if (!ok_cov) begin
            errors = errors + 1;
            $display("  FAIL | a coverage goal was not reached");
        end
        else
            $display("  PASS | every coverage goal reached");

        // ================= summary =================
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
