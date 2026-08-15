`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_intc_random;

  tb_env env();

  `TB_DUMP(tb_intc_random, "tb_intc_random.vcd")

  integer phase;

  initial begin
    env.banner("tb_intc_random");
    env.reset_dut;
    env.u_cpu.enable_all;
    env.chk.note("phase 1: aligned stimulus, 400 operations");
    env.u_cpu.set_irq_style(`IRQ_ALIGNED);
    env.u_cpu.set_seed(32'h1111_2222);
    env.u_cpu.random_traffic(400);
    env.u_cpu.drain(10);
    env.chk.note("phase 2: a second seed, 400 operations");
    env.u_cpu.set_seed(32'h9999_ABCD);
    env.u_cpu.random_traffic(400);
    env.u_cpu.drain(10);
    env.chk.note("phase 3: skewed request timing, 400 operations");
    env.u_cpu.set_irq_style(`IRQ_SKEWED);
    env.u_cpu.set_seed(32'h5555_0F0F);
    env.u_cpu.random_traffic(400);
    env.u_cpu.drain(10);
    env.chk.note("phase 4: interrupt storms");
    env.u_cpu.set_irq_style(`IRQ_ALIGNED);
    env.u_cpu.run_pattern(`PAT_STORM, 6);
    env.u_cpu.drain(12);
    env.chk.note("phase 5: realistic ISR flow");
    env.u_cpu.run_pattern(`PAT_ISR_FLOW, 20);
    env.u_cpu.drain(10);
    env.chk.require_evaluations(20, 50);
    env.require_coverage(70);
    env.finish_test("tb_intc_random");
  end

endmodule
