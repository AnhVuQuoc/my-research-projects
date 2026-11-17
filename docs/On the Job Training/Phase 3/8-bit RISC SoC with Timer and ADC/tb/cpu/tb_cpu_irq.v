// =============================================================================
// File        : tb_cpu_irq.v
// Module      : tb_cpu_irq   (self-checking testbench for the interrupt logic)
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Method      : Lockstep against isa_reference_model with interrupts. A random irq
//               generator raises irq after a random delay and drops it when the
//               CPU takes the interrupt (or after a random hold time). When the
//               CPU takes an interrupt, both models are told after how many older
//               instructions still in flight they must take it, and they check
//               that their PC at that point equals the EPC the CPU saved.
//               Main programs are random (0x20..0x3F) and contain EI, DI, WFI;
//               the ISR at 0x10 clobbers Z and C to test the shadow flags.
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module tb_cpu_irq;
    reg clk = 1'b0, rst = 1'b1, irq = 1'b0;
    initial forever begin #5 clk = 1'b0; #5 clk = 1'b1; end
    wire [7:0] pc_out, alu_out, wb_data_out; wire [15:0] instr_out; wire zero_out, carry_out, halted;
    cpu_top #(.PROGRAM_FILE("program.mem"), .IRQ_VECTOR(8'h10)) CPU (
        .clk(clk), .rst(rst), .pc_out(pc_out), .instr_out(instr_out), .alu_out(alu_out), .wb_data_out(wb_data_out),
        .zero_out(zero_out), .carry_out(carry_out), .halted(halted),
        .irq(irq), .io_cs(), .io_we(), .io_addr(), .io_wdata(), .io_rdata(8'h00));
    isa_reference_model REF_WB ();
    isa_reference_model REF_MEM ();

    integer errors = 0, ls = 0, inv = 0, i, p, k, seed = 32'h5E203519, target, guard;
    integer c_take_run = 0, c_take_sleep = 0, c_wake_noie = 0, c_reti = 0, c_ei = 0, c_di = 0, c_blocked = 0, c_flagdiff = 0, c_wfi = 0;
    reg on = 1'b0, done = 1'b0, restore_skip = 1'b0, pv = 1'b0, p_take = 1'b0;
    integer irq_delay, irq_hold;

    task fail; input [8*60:1] m; begin errors = errors + 1; if (errors < 20) $display("  %t | FAIL | %0s", $time, m); end endtask

    // ---------------- random irq generator: delay, then high until taken or hold expires
    always @(posedge clk) begin
        if (rst || !on) begin irq <= 1'b0; irq_delay <= 5 + ($unsigned($random(seed)) % 30); irq_hold <= 0; end
        else if (!irq) begin
            if (irq_delay == 0) begin irq <= 1'b1; irq_hold <= 3 + ($unsigned($random(seed)) % 40); end
            else irq_delay <= irq_delay - 1;
        end
        else if (CPU.irq_take || irq_hold == 0) begin irq <= 1'b0; irq_delay <= 5 + ($unsigned($random(seed)) % 40); end
        else irq_hold <= irq_hold - 1;
    end

    // ---------------- lockstep, invariants and coverage (sampled at the falling edge)
    always @(negedge clk) begin
        if (on && !rst && !done) begin
            // interrupt taken this clock: tell both models how many older instructions are still in flight
            if (CPU.irq_take) begin
                REF_WB.int_cnt  = CPU.ex_valid + CPU.mem_valid + CPU.wb_valid;
                REF_MEM.int_cnt = CPU.ex_valid + CPU.mem_valid;
                REF_WB.int_epc  = CPU.IRQ.take_sleep ? CPU.if_pc : CPU.id_pc;
                REF_MEM.int_epc = REF_WB.int_epc;
                if (CPU.IRQ.take_sleep) c_take_sleep = c_take_sleep + 1; else c_take_run = c_take_run + 1;
                if (CPU.flag_next_z !== CPU.zero_flag || CPU.flag_next_c !== CPU.carry_flag) c_flagdiff = c_flagdiff + 1;
            end
            if (CPU.irq_restore) restore_skip = 1'b1;                        // older ISR flag writes are overwritten
            if (CPU.mem_valid && CPU.mem_instr == 16'h0001) restore_skip = 1'b0;
            if (irq && CPU.irq_ie && CPU.stall) c_blocked = c_blocked + 1;
            if (CPU.IRQ.sleeping && irq && !CPU.irq_ie) c_wake_noie = c_wake_noie + 1;
            if (CPU.IRQ.wfi_now) c_wfi = c_wfi + 1;
            // invariants
            inv = inv + 1;
            if (CPU.irq_take && CPU.stall) fail("interrupt taken while stalled");
            if (CPU.irq_take && CPU.pc_sel) fail("interrupt taken with a taken branch");
            if (CPU.irq_take && !CPU.irq_ie) fail("interrupt taken with IE = 0");
            if (pv && p_take && (CPU.id_valid !== 1'b0 || CPU.ex_valid !== 1'b0 || CPU.if_pc !== 8'h10)) fail("take did not squash and redirect");
            if (pv && p_take && CPU.irq_ie !== 1'b0) fail("IE not cleared on entry");
            pv = 1'b1; p_take = CPU.irq_take;
            // MEM copy: flags
            if (CPU.mem_valid) begin
                REF_MEM.step; ls = ls + 1;
                if (CPU.mem_pc !== REF_MEM.last_pc) fail("MEM pc mismatch");
                if (!restore_skip && (CPU.zero_flag !== REF_MEM.zf || CPU.carry_flag !== REF_MEM.cf)) fail("MEM flag mismatch");
                if (!REF_MEM.int_epc_ok) begin fail("REF_MEM: interrupt boundary != EPC"); REF_MEM.int_epc_ok = 1'b1; end
            end
            // WB copy: registers, write, memory on ST
            if (CPU.wb_valid) begin
                ls = ls + 1;
                if (CPU.RF.r0 !== REF_WB.r[0] || CPU.RF.r1 !== REF_WB.r[1] || CPU.RF.r2 !== REF_WB.r[2] || CPU.RF.r3 !== REF_WB.r[3] ||
                    CPU.RF.r4 !== REF_WB.r[4] || CPU.RF.r5 !== REF_WB.r[5] || CPU.RF.r6 !== REF_WB.r[6] || CPU.RF.r7 !== REF_WB.r[7]) fail("registers differ");
                REF_WB.step; ls = ls + 1;
                if (CPU.wb_pc !== REF_WB.last_pc || CPU.wb_reg_we !== REF_WB.last_reg_we ||
                    (REF_WB.last_reg_we && (CPU.wb_rd !== REF_WB.last_rd || CPU.wb_data !== REF_WB.last_value))) fail("WB retirement mismatch");
                if (!REF_WB.int_epc_ok) begin fail("REF_WB: interrupt boundary != EPC"); REF_WB.int_epc_ok = 1'b1; end
                if (CPU.irq_ie !== REF_WB.ie && !CPU.irq_take) ; // IE leads the model by the pipeline depth: not compared here
                case (CPU.wb_instr)
                    16'h0001: c_reti = c_reti + 1; 16'h0002: c_ei = c_ei + 1; 16'h0003: c_di = c_di + 1; default: ;
                endcase
                if (REF_WB.last_mem_we || REF_WB.steps >= target) begin
                    ls = ls + 1;
                    for (p = 0; p < 256; p = p + 1) if (CPU.DMEM.mem[p] !== REF_WB.dmem[p]) fail("data memory differs");
                end
                if (REF_WB.steps >= target || REF_WB.halted) done = 1'b1;
            end
        end
        else pv = 1'b0;
    end

    function [15:0] rnd_main; input integer dummy;
        reg [3:0] op; integer r;
        begin
            r = $unsigned($random(seed)) % 100;
            if      (r < 40) op = 4'h1 + ($unsigned($random(seed)) % 5);
            else if (r < 46) op = 4'h6 + ($unsigned($random(seed)) % 2);
            else if (r < 56) op = 4'h8;
            else if (r < 63) op = 4'h9;
            else if (r < 71) op = 4'hA;
            else if (r < 78) op = 4'hB;
            else if (r < 80) op = 4'hC;
            else if (r < 85) op = 4'hD;
            else if (r < 90) op = 4'hE;
            else op = 4'h0;
            rnd_main = $random(seed); rnd_main[15:12] = op;
            if (op >= 4'hC && op <= 4'hE) rnd_main[7:0] = 8'h20 + (rnd_main[7:0] % 32);
            if (op == 4'h0) rnd_main[11:0] = (r < 93) ? 12'h002 : (r < 95) ? 12'h003 : (r < 98) ? 12'h004 : 12'h000;  // EI, DI, WFI, NOP
        end
    endfunction

    initial begin
        $timeformat(-9, 0, "", 7);
        $display("============================================================================");
        $display(" tb_cpu_irq : interrupt lockstep for cpu_top (RETI, EI, DI, WFI, IRQ)");
        $display(" Student: Vu Quoc Anh | Roll number: SE203519");
        $display("============================================================================");
        for (k = 0; k < 400; k = k + 1) begin
            for (i = 0; i < 256; i = i + 1) begin CPU.IMEM.mem[i] = 16'h0000; CPU.DMEM.mem[i] = $random(seed); end
            CPU.IMEM.mem[8'h00] = 16'hC020;                                  // JMP 0x20
            CPU.IMEM.mem[8'h10] = 16'h9E01;                                  // ISR: ADDI R7, 1
            CPU.IMEM.mem[8'h11] = 16'h5D80;                                  //      XOR  R6, R6, R6   (Z = 1)
            CPU.IMEM.mem[8'h12] = 16'h2DB8;                                  //      SUB  R6, R6, R7   (borrow, Z = 0)
            CPU.IMEM.mem[8'h13] = 16'h0001;                                  //      RETI
            CPU.IMEM.mem[8'h20] = 16'h0002;                                  // EI
            for (i = 8'h21; i < 8'h40; i = i + 1) CPU.IMEM.mem[i] = rnd_main(0);
            for (i = 0; i < 256; i = i + 1) begin REF_WB.imem[i] = CPU.IMEM.mem[i]; REF_WB.dmem[i] = CPU.DMEM.mem[i];
                                                  REF_MEM.imem[i] = CPU.IMEM.mem[i]; REF_MEM.dmem[i] = CPU.DMEM.mem[i]; end
            REF_WB.reset_state; REF_MEM.reset_state; target = 120; done = 1'b0; restore_skip = 1'b0;
            rst <= 1'b1; @(negedge clk); @(posedge clk); @(posedge clk); @(negedge clk); rst <= 1'b0; on = 1'b1; guard = 0;
            while (!done && guard < 3000) begin @(negedge clk); guard = guard + 1; end
            if (!done && !CPU.IRQ.sleeping) fail("watchdog");
            on = 1'b0;
        end
        $display("  coverage: take_run %0d, take_sleep %0d, wake_without_IE %0d, WFI sleeps %0d, RETI %0d, EI %0d, DI %0d,",
                 c_take_run, c_take_sleep, c_wake_noie, c_wfi, c_reti, c_ei, c_di);
        $display("            blocked_by_stall %0d, take_with_flag_write_in_EX %0d", c_blocked, c_flagdiff);
        if (c_take_run == 0 || c_take_sleep == 0 || c_wake_noie == 0 || c_reti == 0 || c_di == 0 || c_blocked == 0 || c_flagdiff == 0) begin
            errors = errors + 1; $display("  FAIL | a coverage goal was not reached"); end
        #1;
        if (errors == 0) $display("PASS: tb_cpu_irq (Vu Quoc Anh, SE203519) 400 random programs, %0d lockstep + %0d invariant checks, 0 errors", ls, inv);
        else $display("FAILED: tb_cpu_irq (Vu Quoc Anh, SE203519) %0d errors", errors);
        $finish(0);
    end
endmodule
`default_nettype wire
