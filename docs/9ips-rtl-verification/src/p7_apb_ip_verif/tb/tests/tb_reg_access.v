`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_reg_access;

  tb_env env();
  `TB_DUMP(tb_reg_access, "tb_reg_access.vcd")

  integer a;
  reg [7:0] av;

  initial begin
    env.banner("tb_reg_access");
    env.seq.set_irq_style(`IRQ_ALIGNED);
    env.seq.set_seed(32'h0000_7001);
    env.reset_dut;
    env.chk.note("F1.1 identification register");
    env.seq.rd(`REG_ID);
    env.chk.expect_eq("ID value", env.seq.m.last_rdata, `INTC_ID);
    env.chk.expect_eq("ID no error", {31'd0, env.seq.m.last_err}, 32'd0);
    env.chk.note("F1.2 reset values");
    env.seq.rd(`REG_MASK);
    env.seq.rd(`REG_PEND);
    env.seq.rd(`REG_ISR);
    env.seq.rd(`REG_STATUS);
    env.chk.note("F2.1 MASK is read/write");
    env.seq.wr(`REG_MASK, 32'h0000_00A5);
    env.seq.rd(`REG_MASK);
    env.seq.wr(`REG_MASK, 32'h0000_005A);
    env.seq.rd(`REG_MASK);
    env.chk.note("F2.2 unimplemented bits read as zero");
    env.seq.wr(`REG_MASK, 32'hFFFF_FFFF);
    env.seq.rd(`REG_MASK);
    env.chk.expect_eq("upper bits are zero", env.seq.m.last_rdata, 32'h0000_00FF);
    env.chk.note("F2.3 walking one through MASK");
    for (a = 0; a < 8; a = a + 1) begin
      env.seq.wr(`REG_MASK, (32'd1 << a));
      env.seq.rd(`REG_MASK);
    end
    env.chk.note("F2.4 walking zero through MASK");
    for (a = 0; a < 8; a = a + 1) begin
      env.seq.wr(`REG_MASK, 32'h0000_00FF & ~(32'd1 << a));
      env.seq.rd(`REG_MASK);
    end
    env.chk.note("F1.3 exhaustive read sweep of all 256 byte offsets");
    for (a = 0; a < 256; a = a + 1) begin
      av = a;
      env.seq.rd(av);
    end
    env.chk.note("F1.4 state unchanged by the read sweep");
    env.check_state;
    env.chk.note("F2.5 back-to-back transfers");
    env.seq.m.write_b2b(`REG_MASK, 32'h0000_0033, `REG_MASK, 32'h0000_00CC);
    env.seq.rd(`REG_MASK);
    env.chk.expect_eq("second write of the pair took effect", env.seq.m.last_rdata, 32'h0000_00CC);
    env.check_state;
    env.finish_test("tb_reg_access");
  end

endmodule
