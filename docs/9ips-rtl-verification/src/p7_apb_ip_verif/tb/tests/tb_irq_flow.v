`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_irq_flow;

  tb_env env();
  `TB_DUMP(tb_irq_flow, "tb_irq_flow.vcd")

  integer i;

  initial begin
    env.banner("tb_irq_flow");
    env.seq.set_irq_style(`IRQ_ALIGNED);
    env.seq.set_seed(32'h0000_7004);
    env.reset_dut;
    env.chk.note("F5.1 masked source: silent, but pending");
    env.seq.wr(`REG_MASK, 32'h0000_0000);
    env.seq.arrive(3);
    env.seq.idle(6);
    env.chk.expect_true("no interrupt while masked", env.irq_out === 1'b0);
    env.seq.rd(`REG_PEND);
    env.chk.expect_eq("but it is pending", env.seq.m.last_rdata, 32'h0000_0008);
    env.chk.note("F5.2 unmasking a pending source");
    env.seq.enable_all;
    env.seq.idle(3);
    env.chk.expect_true("interrupt appears", env.irq_out === 1'b1);
    env.chk.expect_eq("and it is source 3", {29'd0, env.irq_id}, 32'd3);
    env.chk.note("F5.3 STATUS agrees with the pins");
    env.seq.rd(`REG_STATUS);
    env.chk.expect_eq("status.irq", {31'd0, env.seq.m.last_rdata[0]}, 32'd1);
    env.chk.expect_eq("status.id", {29'd0, env.seq.m.last_rdata[3:1]}, 32'd3);
    env.chk.expect_eq("status.busy", {31'd0, env.seq.m.last_rdata[4]}, 32'd0);
    env.chk.note("F5.4 acknowledge and end-of-interrupt through the bus");
    env.seq.ack;
    env.seq.idle(2);
    env.seq.rd(`REG_ISR);
    env.chk.expect_eq("in service", env.seq.m.last_rdata, 32'h0000_0008);
    env.seq.rd(`REG_PEND);
    env.chk.expect_eq("pending cleared", env.seq.m.last_rdata, 32'h0000_0000);
    env.seq.wr(`REG_EOI, 32'h0);
    env.seq.idle(3);
    env.seq.rd(`REG_ISR);
    env.chk.expect_eq("retired", env.seq.m.last_rdata, 32'h0000_0000);
    env.check_state;
    env.chk.note("F5.5 one interrupt from each source");
    for (i = 0; i < `APB_INTC_N; i = i + 1) begin
      env.seq.isr_flow(i, 2);
      env.seq.idle(2);
    end
    env.check_state;
    env.chk.note("F6.1 preemption and LIFO unwinding");
    env.seq.nest_build(3);
    env.seq.idle(3);
    env.seq.rd(`REG_ISR);
    env.chk.expect_eq("three levels", env.seq.m.last_rdata, 32'h0000_0007);
    env.seq.nest_unwind(3);
    env.seq.idle(3);
    env.seq.rd(`REG_ISR);
    env.chk.expect_eq("unwound", env.seq.m.last_rdata, 32'h0000_0000);
    env.check_state;
    env.chk.note("F6.2 equal priority does not preempt (live-lock check)");
    env.seq.arrive(6);
    env.seq.wait_irq(60);
    env.seq.ack;
    env.seq.idle(2);
    env.seq.arrive(6);
    env.seq.idle(8);
    env.chk.expect_true("no self-preemption", env.irq_out === 1'b0);
    env.seq.wr(`REG_EOI, 32'h0);
    env.seq.idle(3);
    env.chk.expect_true("re-offered once the level is free", env.irq_out === 1'b1);
    env.seq.ack;
    env.seq.wr(`REG_EOI, 32'h0);
    env.seq.idle(3);
    env.check_state;
    env.chk.note("F6.3 masking an offered source withdraws the offer");
    env.seq.arrive(4);
    env.seq.wait_irq(60);
    env.chk.expect_true("source 4 offered", env.seq.wait_ok);
    env.seq.wr(`REG_MASK, 32'h0000_00EF);
    env.seq.idle(3);
    env.chk.expect_true("offer withdrawn", env.irq_out === 1'b0);
    env.seq.enable_all;
    env.seq.idle(3);
    env.chk.expect_true("offer returns", env.irq_out === 1'b1);
    env.seq.ack;
    env.seq.wr(`REG_EOI, 32'h0);
    env.seq.idle(3);
    env.check_state;
    env.chk.note("F6.4 interrupts arriving during bus transfers");
    env.seq.set_irq_style(`IRQ_SKEWED);
    env.seq.random_traffic(200, `PROF_MIXED);
    env.seq.drain_all;
    env.check_state;
    env.finish_test("tb_irq_flow");
  end

endmodule
