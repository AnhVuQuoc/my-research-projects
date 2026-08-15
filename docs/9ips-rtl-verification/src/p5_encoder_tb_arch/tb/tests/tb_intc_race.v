`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_intc_race;

  tb_env env();

  `TB_DUMP(tb_intc_race, "tb_intc_race.vcd")

  initial begin
    env.banner("tb_intc_race");
    env.u_cpu.set_irq_style(`IRQ_ALIGNED);
    env.u_cpu.set_seed(32'h0003_3333);
    env.reset_dut;
    env.u_cpu.enable_all;
    env.chk.note("1: EOI with an empty in-service register (D7)");
    env.u_cpu.eoi;
    env.u_cpu.eoi;
    env.u_cpu.eoi;
    env.u_cpu.idle(3);
    env.u_cpu.read_isr;
    env.chk.expect_eq("in-service still empty",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0000);
    env.u_cpu.isr_flow(3, 2);
    env.u_cpu.idle(3);
    env.u_cpu.read_isr;
    env.chk.expect_eq("controller still functional after spurious EOIs",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0000);
    env.chk.note("2: acknowledge while no interrupt is offered");
    env.chk.expect_true("nothing offered to begin with", env.irq_out === 1'b0);
    env.u_cpu.ack;
    env.u_cpu.ack;
    env.u_cpu.idle(3);
    env.u_cpu.read_isr;
    env.chk.expect_eq("spurious acknowledge ignored",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0000);
    env.chk.note("3: request SET colliding with acknowledge CLEAR (D4)");
    env.u_cpu.arrive_hold(5);
    env.u_cpu.u_cpudrv.wait_irq(50);
    env.chk.expect_true("source 5 offered", env.u_cpu.u_cpudrv.wait_ok);
    env.u_cpu.arrive_colliding_with_ack(5);
    env.u_cpu.idle(4);
    env.u_cpu.read_isr;
    env.chk.expect_true("source 5 entered service",env.u_cpu.u_cpudrv.last_rdata[5] === 1'b1);
    env.u_cpu.read_pend;
    env.chk.expect_true("the colliding request was NOT lost",env.u_cpu.u_cpudrv.last_rdata[5] === 1'b1);
    env.u_cpu.depart(5);
    env.u_cpu.eoi;
    env.u_cpu.idle(3);
    env.chk.expect_true("retained request is offered after EOI",env.irq_out === 1'b1);
    env.u_cpu.ack;
    env.u_cpu.eoi;
    env.u_cpu.idle(4);
    env.chk.note("4: acknowledge and EOI colliding");
    env.u_cpu.arrive(2);
    env.u_cpu.u_cpudrv.wait_irq(50);
    env.u_cpu.ack;
    env.u_cpu.idle(2);
    env.u_cpu.arrive(6);
    env.u_cpu.u_cpudrv.wait_irq(50);
    env.u_cpu.u_cpudrv.ack_and_eoi;
    env.u_cpu.idle(4);
    env.u_cpu.read_isr;
    env.chk.expect_eq("only source 6 in service",{24'd0, env.u_cpu.u_cpudrv.last_rdata}, 32'h0000_0040);
    env.u_cpu.eoi;
    env.u_cpu.idle(3);
    env.chk.note("5: mask write colliding with acknowledge");
    env.u_cpu.arrive(4);
    env.u_cpu.u_cpudrv.wait_irq(50);
    env.u_cpu.u_cpudrv.ack_and_write(`ADDR_MASK, 8'b1110_1111);
    env.u_cpu.idle(4);
    env.u_cpu.read_isr;
    env.chk.expect_true("source 4 is in service despite the mask write",env.u_cpu.u_cpudrv.last_rdata[4] === 1'b1);
    env.u_cpu.eoi;
    env.u_cpu.enable_all;
    env.u_cpu.idle(3);
    env.chk.note("6: minimum-width request pulse");
    env.u_cpu.narrow_pulse(7);
    env.u_cpu.u_cpudrv.wait_irq(50);
    env.chk.expect_true("one-cycle pulse was captured",env.u_cpu.u_cpudrv.wait_ok);
    env.u_cpu.ack;
    env.u_cpu.eoi;
    env.u_cpu.idle(4);
    env.chk.note("7a: traffic with request lines changing at random offsets");
    env.u_cpu.set_irq_style(`IRQ_SKEWED);
    env.u_cpu.random_traffic(150);
    env.u_cpu.drain(8);
    env.chk.note("7b: traffic with request lines changing inside the setup window");
    env.u_cpu.set_irq_style(`IRQ_HOSTILE);
    env.u_cpu.random_traffic(150);
    env.u_cpu.drain(8);
    env.finish_test("tb_intc_race");
  end

endmodule
