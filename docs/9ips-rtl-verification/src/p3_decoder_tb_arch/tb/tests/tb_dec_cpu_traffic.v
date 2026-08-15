`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_dec_cpu_traffic;

  tb_env #(.MAX_GAP(1)) env ();

  `TB_DUMP(tb_dec_cpu_traffic, "tb_dec_cpu_traffic.vcd")

  initial begin
    env.banner("tb_dec_cpu_traffic");
    env.reset_dut;
    env.u_cpu.set_seed(32'h1CE0_0004);

    env.u_cpu.cpu_traffic(5000);

    env.u_cpu.idle(4);
    env.require_coverage(50);
    env.finish_test("tb_dec_cpu_traffic");
  end

endmodule
