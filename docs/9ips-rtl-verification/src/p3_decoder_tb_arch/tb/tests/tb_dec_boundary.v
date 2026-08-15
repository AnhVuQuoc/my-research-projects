`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_dec_boundary;

  tb_env #(.MAX_GAP(0)) env ();

  `TB_DUMP(tb_dec_boundary, "tb_dec_boundary.vcd")

  initial begin
    env.banner("tb_dec_boundary");
    env.reset_dut;
    env.u_cpu.set_seed(32'h0000_0002);


    env.u_cpu.walk_boundaries(`BASE0, `SIZE0);
    env.u_cpu.walk_boundaries(`BASE1, `SIZE1);
    env.u_cpu.walk_boundaries(`BASE2, `SIZE2);
    env.u_cpu.walk_boundaries(`BASE3, `SIZE3);


    env.u_cpu.send(32'h1000_0000);
    env.u_cpu.send(32'h3FFF_FFFF);
    env.u_cpu.send(32'h4000_2000);
    env.u_cpu.send(32'hFFFF_FFFF);
    env.u_cpu.stop;

    env.u_cpu.idle(4);
    env.require_coverage(90);
    env.finish_test("tb_dec_boundary");
  end

endmodule
