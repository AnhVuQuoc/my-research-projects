`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_err_response;

  tb_env env();
  `TB_DUMP(tb_err_response, "tb_err_response.vcd")

  integer i;

  initial begin
    env.banner("tb_err_response");
    env.seq.set_irq_style(`IRQ_ALIGNED);
    env.seq.set_seed(32'h0000_7002);
    env.reset_dut;
    env.seq.wr(`REG_MASK, 32'h0000_003C);
    env.check_state;
    env.chk.note("F3.1 unmapped addresses, read and write");
    env.seq.rd(8'h80);
    env.chk.expect_eq("unmapped read errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.wr(8'h80, 32'hDEAD_BEEF);
    env.chk.expect_eq("unmapped write errors",{31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.rd(8'hFC);
    env.chk.expect_eq("top of range errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.chk.note("F3.2 misaligned addresses within an implemented word");
    env.seq.rd(8'h01);
    env.chk.expect_eq("0x01 errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.rd(8'h02);
    env.seq.rd(8'h03);
    env.seq.wr(8'h05, 32'hFFFF_FFFF);
    env.chk.note("F3.3 writes to read-only registers");
    env.seq.wr(`REG_PEND,   32'hFFFF_FFFF);
    env.chk.expect_eq("write PEND errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.wr(`REG_ISR,    32'hFFFF_FFFF);
    env.chk.expect_eq("write ISR errors",  {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.wr(`REG_STATUS, 32'hFFFF_FFFF);
    env.chk.expect_eq("write STATUS errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.wr(`REG_ID,     32'hFFFF_FFFF);
    env.chk.expect_eq("write ID errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.chk.note("F3.4 unrecognised command codes");
    env.seq.wr(`REG_CMD, 32'd0);
    env.chk.expect_eq("command 0 errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.wr(`REG_CMD, 32'd99);
    env.chk.expect_eq("command 99 errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.wr(`REG_CMD, 32'hFFFF_FFFF);
    env.chk.expect_eq("command all-ones errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.chk.note("F3.5 reads of write-only registers return zero, no error");
    env.seq.rd(`REG_EOI);
    env.chk.expect_eq("read EOI no error", {31'd0, env.seq.m.last_err}, 32'd0);
    env.chk.expect_eq("read EOI is zero",  env.seq.m.last_rdata, 32'd0);
    env.seq.rd(`REG_CMD);
    env.chk.note("F3.6 no side effects from any rejected access");
    env.seq.rd(`REG_MASK);
    env.chk.expect_eq("MASK survived every illegal access", env.seq.m.last_rdata, 32'h0000_003C);
    env.check_state;
    env.chk.note("F3.7 recovery after sustained illegal traffic");
    env.seq.random_traffic(120, `PROF_ERROR);
    env.seq.idle(4);
    env.seq.wr(`REG_MASK, 32'h0000_00FF);
    env.seq.rd(`REG_MASK);
    env.chk.expect_eq("slave still functional", env.seq.m.last_rdata, 32'h0000_00FF);
    env.check_state;
    env.finish_test("tb_err_response");
  end

endmodule
