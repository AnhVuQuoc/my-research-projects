`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_dec_random;

  tb_env #(.MAX_GAP(3)) env ();

  `TB_DUMP(tb_dec_random, "tb_dec_random.vcd")

  initial begin
    env.banner("tb_dec_random");
    env.reset_dut;
    env.u_cpu.set_seed(32'hBEEF_0003);

    $display("[%0t] INFO  phase 1 : 1000 UNCONSTRAINED random addresses", $time);
    env.u_cpu.random_uniform(1000);
    $display("[%0t] INFO  coverage after unconstrained phase : %0d %%",
             $time, env.u_cov.coverage_pct());

    $display("[%0t] INFO  phase 2 : 3000 CONSTRAINED random addresses", $time);
    env.u_cpu.random_biased(3000);
    $display("[%0t] INFO  coverage after constrained phase   : %0d %%",
             $time, env.u_cov.coverage_pct());

    env.u_cpu.idle(4);
    env.require_coverage(85);
    env.finish_test("tb_dec_random");
  end

endmodule
