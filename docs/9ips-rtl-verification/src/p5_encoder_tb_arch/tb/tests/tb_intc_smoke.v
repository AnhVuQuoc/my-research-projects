`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_intc_smoke;

  tb_env env();

  `TB_DUMP(tb_intc_smoke, "tb_intc_smoke.vcd")

  initial begin
    env.banner("tb_intc_smoke");
    env.u_cpu.set_irq_style(`IRQ_ALIGNED);
    env.u_cpu.set_seed(32'h0000_1111);
    env.reset_dut;
    env.chk.note("1: reset state via the register port");
    env.u_cpu.read_mask;
    env.chk.expect_eq("mask after reset",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0000);
    env.u_cpu.read_pend;
    env.chk.expect_eq("pend after reset",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0000);
    env.u_cpu.read_isr;
    env.chk.expect_eq("isr after reset",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0000);
    env.chk.note("2: mask register write/read");
    env.u_cpu.set_mask(8'b1010_0101);
    env.u_cpu.read_mask;
    env.chk.expect_eq("mask readback",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_00A5);
    env.chk.note("3: a disabled source stays silent");
    env.u_cpu.set_mask(8'b0000_0000);
    env.u_cpu.arrive(3);
    env.u_cpu.idle(6);
    env.chk.expect_true("no offer while masked", env.irq_out === 1'b0);
    env.u_cpu.read_pend;
    env.chk.expect_eq("pending set even while masked",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0008);
    env.chk.note("4: unmasking a pending source raises the interrupt");
    env.u_cpu.enable_all;
    env.u_cpu.idle(3);
    env.chk.expect_true("offer appears after unmask", env.irq_out === 1'b1);
    env.chk.expect_eq("offered id is 3", {29'd0, env.irq_id}, 32'd3);
    env.chk.note("5: acknowledge / EOI round trip");
    env.u_cpu.ack;
    env.u_cpu.idle(1);
    env.u_cpu.read_isr;
    env.chk.expect_eq("source 3 is in service",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0008);
    env.u_cpu.read_pend;
    env.chk.expect_eq("pending cleared by ack",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0000);
    env.chk.expect_true("offer withdrawn after ack", env.irq_out === 1'b0);
    env.u_cpu.eoi;
    env.u_cpu.idle(2);
    env.u_cpu.read_isr;
    env.chk.expect_eq("in-service cleared by EOI",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0000);
    env.chk.note("6: one interrupt from every source in turn");
    env.u_cpu.run_pattern(`PAT_SINGLE, 8);
    env.u_cpu.drain(4);
    env.finish_test("tb_intc_smoke");
  end

endmodule
