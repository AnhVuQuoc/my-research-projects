`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_intc_nesting;

  tb_env env();

  `TB_DUMP(tb_intc_nesting, "tb_intc_nesting.vcd")

  initial begin
    env.banner("tb_intc_nesting");
    env.u_cpu.set_irq_style(`IRQ_ALIGNED);
    env.u_cpu.set_seed(32'h0002_2222);
    env.reset_dut;
    env.u_cpu.enable_all;
    env.chk.note("1: a more urgent source preempts a running ISR");
    env.u_cpu.arrive(2);
    env.u_cpu.u_cpudrv.wait_irq(50);
    env.chk.expect_true("source 2 offered", env.u_cpu.u_cpudrv.wait_ok);
    env.chk.expect_eq("offered id = 2", {29'd0, env.irq_id}, 32'd2);
    env.u_cpu.ack;
    env.u_cpu.idle(2);
    env.u_cpu.arrive(6);
    env.u_cpu.u_cpudrv.wait_irq(50);
    env.chk.expect_true("source 6 preempts", env.u_cpu.u_cpudrv.wait_ok);
    env.chk.expect_eq("offered id = 6", {29'd0, env.irq_id}, 32'd6);
    env.u_cpu.ack;
    env.u_cpu.read_isr;
    env.chk.expect_eq("both 2 and 6 in service",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0044);
    env.chk.note("2: equal priority must NOT preempt (live-lock check)");
    env.u_cpu.arrive(6);
    env.u_cpu.idle(8);
    env.chk.expect_true("no self-preemption", env.irq_out === 1'b0);
    env.chk.note("3: a less urgent source waits, it is not lost");
    env.u_cpu.arrive(1);
    env.u_cpu.idle(8);
    env.chk.expect_true("no preemption by source 1", env.irq_out === 1'b0);
    env.u_cpu.read_pend;
    env.chk.expect_true("sources 1 and 6 pending",env.u_cpu.u_cpudrv.last_rdata[1] === 1'b1);
    env.chk.note("4: unwind LIFO, then re-offer the source that fired again");
    env.u_cpu.eoi;
    env.u_cpu.idle(3);
    env.u_cpu.read_isr;
    env.chk.expect_eq("only source 2 still in service",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0004);
    env.chk.expect_true("source 6 offered again", env.irq_out === 1'b1);
    env.chk.expect_eq("and it is 6", {29'd0, env.irq_id}, 32'd6);
    env.u_cpu.ack;
    env.u_cpu.idle(2);
    env.u_cpu.eoi;
    env.u_cpu.idle(3);
    env.u_cpu.eoi;
    env.u_cpu.idle(3);
    env.chk.expect_true("source 1 finally offered", env.irq_out === 1'b1);
    env.chk.expect_eq("and it is 1", {29'd0, env.irq_id}, 32'd1);
    env.u_cpu.ack;
    env.u_cpu.eoi;
    env.u_cpu.idle(3);
    env.u_cpu.read_isr;
    env.chk.expect_eq("nesting fully unwound",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0000);
    env.chk.note("5: masking a source that is currently being offered");
    env.u_cpu.arrive(4);
    env.u_cpu.u_cpudrv.wait_irq(50);
    env.chk.expect_true("source 4 offered", env.u_cpu.u_cpudrv.wait_ok);
    env.u_cpu.set_mask(8'b1110_1111);
    env.u_cpu.idle(3);
    env.chk.expect_true("offer withdrawn by masking", env.irq_out === 1'b0);
    env.u_cpu.enable_all;
    env.u_cpu.idle(3);
    env.chk.expect_true("offer returns when re-enabled", env.irq_out === 1'b1);
    env.u_cpu.ack;
    env.u_cpu.eoi;
    env.u_cpu.idle(3);
    env.chk.note("6: nesting to depth 4 and unwinding");
    env.u_cpu.nested_deep(4, 2);
    env.u_cpu.idle(5);
    env.u_cpu.read_isr;
    env.chk.expect_eq("in-service empty after unwinding",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0000);
    env.chk.note("7: repeated nested pairs");
    env.u_cpu.run_pattern(`PAT_NESTED, 8);
    env.u_cpu.drain(6);
    env.require_coverage(55);
    env.finish_test("tb_intc_nesting");
  end

endmodule
