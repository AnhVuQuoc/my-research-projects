`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_dec_smoke;

  tb_env #(.MAX_GAP(0)) env ();

  `TB_DUMP(tb_dec_smoke, "tb_dec_smoke.vcd")

  initial begin
    env.banner("tb_dec_smoke");
    env.reset_dut;
    env.u_cpu.set_seed(32'h0000_0001);


    env.u_cpu.send(`BASE0 + 32'h0000_0010);  
    env.u_cpu.send(`BASE1 + 32'h0000_0020);  
    env.u_cpu.send(`BASE2 + 32'h0000_0004); 
    env.u_cpu.send(`BASE3 + 32'h0000_0008);  
    env.u_cpu.send(32'h1000_0000);           
    env.u_cpu.stop;

    env.u_cpu.idle(8);

    env.u_cpu.burst(`BASE0, 16, 4);

    env.finish_test("tb_dec_smoke");
  end

endmodule
