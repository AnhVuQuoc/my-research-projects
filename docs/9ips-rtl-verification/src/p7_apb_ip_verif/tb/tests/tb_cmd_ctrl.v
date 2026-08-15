`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_cmd_ctrl;

  tb_env env();
  `TB_DUMP(tb_cmd_ctrl, "tb_cmd_ctrl.vcd")

  integer i;

  initial begin
    env.banner("tb_cmd_ctrl");
    env.seq.set_irq_style(`IRQ_ALIGNED);
    env.seq.set_seed(32'h0000_7003);
    env.reset_dut;
    env.chk.note("F4.1 ENABLE_ALL / DISABLE_ALL");
    env.seq.wr(`REG_MASK, 32'h0000_0000);
    env.seq.wr(`REG_CMD, `CMD_ENABLE_ALL);
    env.chk.expect_eq("command accepted", {31'd0, env.seq.m.last_err}, 32'd0);
    env.seq.idle(8);
    env.seq.rd(`REG_MASK);
    env.chk.expect_eq("mask fully set", env.seq.m.last_rdata, 32'h0000_00FF);
    env.seq.wr(`REG_CMD, `CMD_DISABLE_ALL);
    env.seq.idle(8);
    env.seq.rd(`REG_MASK);
    env.chk.expect_eq("mask fully cleared", env.seq.m.last_rdata, 32'h0000_0000);
    env.check_state;
    env.chk.note("F4.2 accesses during a command are refused, with no effect");
    env.seq.wr(`REG_CMD, `CMD_ENABLE_ALL);
    env.seq.idle(8);
    env.seq.wr(`REG_MASK, 32'h0000_00F0);
    env.seq.idle(4);
    env.seq.wr(`REG_CMD, `CMD_DRAIN);
    env.seq.wr(`REG_MASK, 32'h0000_0000);
    env.chk.expect_eq("access during busy is refused", {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.idle(`APB_INTC_N + 6);
    env.seq.rd(`REG_MASK);
    env.chk.expect_eq("the refused write had no effect", env.seq.m.last_rdata, 32'h0000_00F0);
    env.check_state;
    env.chk.note("F4.3 DRAIN unwinds a three-level nest");
    env.seq.wr(`REG_CMD, `CMD_ENABLE_ALL);
    env.seq.idle(8);
    env.seq.nest_build(3);
    env.seq.idle(4);
    env.seq.rd(`REG_ISR);
    env.chk.expect_eq("three levels in service", env.seq.m.last_rdata, 32'h0000_0007);
    env.seq.wr(`REG_CMD, `CMD_DRAIN);
    env.seq.idle(`APB_INTC_N + 6);
    env.seq.rd(`REG_ISR);
    env.chk.expect_eq("nest fully unwound", env.seq.m.last_rdata, 32'h0000_0000);
    env.check_state;
    env.chk.note("F4.4 DRAIN with nothing in service");
    env.seq.wr(`REG_CMD, `CMD_DRAIN);
    env.seq.idle(`APB_INTC_N + 6);
    env.check_state;
    env.seq.rd(`REG_ISR);
    env.chk.expect_eq("still empty", env.seq.m.last_rdata, 32'h0000_0000);
    env.seq.isr_flow(5, 2);
    env.seq.idle(4);
    env.check_state;
    env.chk.note("F4.5 a command during a command is refused");
    env.seq.wr(`REG_CMD, `CMD_DRAIN);
    env.seq.wr(`REG_CMD, `CMD_ENABLE_ALL);
    env.chk.expect_eq("second command refused", {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.idle(`APB_INTC_N + 6);
    env.check_state;
    env.chk.note("F4.6 repeated commands");
    for (i = 0; i < 4; i = i + 1) begin
      env.seq.wr(`REG_CMD, `CMD_ENABLE_ALL);
      env.seq.idle(6);
      env.seq.wr(`REG_CMD, `CMD_DISABLE_ALL);
      env.seq.idle(6);
    end
    env.check_state;

    env.finish_test("tb_cmd_ctrl");
  end

endmodule
