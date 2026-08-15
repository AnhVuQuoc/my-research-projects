`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_apb_random;

  tb_env env();
  `TB_DUMP(tb_apb_random, "tb_apb_random.vcd")

  initial begin
    env.banner("tb_apb_random");
    env.reset_dut;
    env.seq.enable_all;
    env.chk.note("phase 1: register traffic only, aligned timing");
    env.seq.set_irq_style(`IRQ_ALIGNED);
    env.seq.set_seed(32'h1234_0001);
    env.seq.random_traffic(250, `PROF_REG);
    env.check_state;
    env.chk.note("phase 2: interrupt traffic only");
    env.seq.enable_all;
    env.seq.set_seed(32'h1234_0002);
    env.seq.random_traffic(250, `PROF_IRQ);
    env.seq.drain_all;
    env.check_state;
    env.chk.note("phase 3: illegal accesses mixed into legal ones");
    env.seq.set_seed(32'h1234_0003);
    env.seq.random_traffic(150, `PROF_ERROR);
    env.seq.idle(4);
    env.seq.enable_all;
    env.check_state;
    env.chk.note("phase 4: both interfaces at once - the crossing");
    env.seq.set_irq_style(`IRQ_ALIGNED);
    env.seq.set_seed(32'h1234_0004);
    env.seq.random_traffic(500, `PROF_MIXED);
    env.seq.drain_all;
    env.check_state;
    env.chk.note("phase 5: the same, with request lines at arbitrary offsets");
    env.seq.set_irq_style(`IRQ_SKEWED);
    env.seq.set_seed(32'h1234_0005);
    env.seq.random_traffic(500, `PROF_MIXED);
    env.seq.drain_all;
    env.check_state;
    env.chk.note("phase 6: a second seed on the mixed profile");
    env.seq.set_irq_style(`IRQ_ALIGNED);
    env.seq.set_seed(32'h9ABC_DEF0);
    env.seq.random_traffic(500, `PROF_MIXED);
    env.seq.drain_all;
    env.check_state;
    env.chk.require_evaluations(400, 100);
    env.require_coverage(80);
    env.finish_test("tb_apb_random");
  end

endmodule
