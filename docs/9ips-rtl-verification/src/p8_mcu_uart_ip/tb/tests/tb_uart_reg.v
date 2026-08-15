`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_uart_reg;

  tb_env env();
  `TB_DUMP(tb_uart_reg, "tb_uart_reg.vcd")

  integer a;
  reg [7:0] av;

  initial begin
    env.banner("tb_uart_reg");
    env.reset_dut;

    env.chk.note("F1.1 identification register");
    env.seq.rd(`UREG_ID);
    env.chk.expect_eq("ID value", env.seq.m.last_rdata, `UART_ID_VALUE);
    env.chk.expect_eq("ID no error", {31'd0, env.seq.m.last_err}, 32'd0);

    env.chk.note("F1.2 reset values");
    env.seq.rd(`UREG_CTRL);
    env.chk.expect_eq("CTRL resets to zero", env.seq.m.last_rdata, 32'd0);
    env.seq.rd(`UREG_BAUD);
    env.chk.expect_eq("BAUD resets to the minimum", env.seq.m.last_rdata, `UART_BAUD_MIN);
    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("both FIFOs start empty", env.seq.m.last_rdata[`ST_TX_EMPTY] && env.seq.m.last_rdata[`ST_RX_EMPTY]);

    env.chk.note("F2.1 CTRL is read/write, unimplemented bits read zero");
    env.seq.wr(`UREG_CTRL, 32'h0000_002A);
    env.seq.rd(`UREG_CTRL);
    env.seq.wr(`UREG_CTRL, 32'hFFFF_FFFF);
    env.seq.rd(`UREG_CTRL);
    env.chk.expect_eq("only the implemented CTRL bits are kept", env.seq.m.last_rdata, 32'h0000_003F);
    env.seq.wr(`UREG_CTRL, 32'h0000_0000);

    env.chk.note("F2.2 BAUD is CLAMPED, and the error is reported");
    env.seq.wr(`UREG_BAUD, 32'd100);
    env.chk.expect_eq("a legal divisor is accepted", {31'd0, env.seq.m.last_err}, 32'd0);
    env.seq.rd(`UREG_BAUD);
    env.chk.expect_eq("and stored", env.seq.m.last_rdata, 32'd100);

    env.seq.wr(`UREG_BAUD, 32'd4);
    env.chk.expect_eq("a divisor below the minimum errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.rd(`UREG_BAUD);
    env.chk.expect_eq("and the register is clamped, not corrupted", env.seq.m.last_rdata, `UART_BAUD_MIN);

    env.chk.note("F2.3 write-only registers read as zero without an error");
    env.seq.rd(`UREG_TXDATA);
    env.chk.expect_eq("TXDATA reads zero", env.seq.m.last_rdata, 32'd0);
    env.chk.expect_eq("TXDATA read is not an error", {31'd0, env.seq.m.last_err}, 32'd0);
    env.seq.rd(`UREG_ICLR);
    env.chk.expect_eq("ICLR reads zero", env.seq.m.last_rdata, 32'd0);

    env.chk.note("F2.4 writes to read-only registers are refused");
    env.seq.wr(`UREG_STATUS, 32'hFFFF_FFFF);
    env.chk.expect_eq("write STATUS errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.wr(`UREG_RXDATA, 32'hFFFF_FFFF);
    env.chk.expect_eq("write RXDATA errors", {31'd0, env.seq.m.last_err}, 32'd1);
    env.seq.wr(`UREG_ID, 32'hFFFF_FFFF);
    env.chk.expect_eq("write ID errors", {31'd0, env.seq.m.last_err}, 32'd1);

    env.chk.note("F1.3 exhaustive read sweep of all 256 byte offsets");
    for (a = 0; a < 256; a = a + 1) begin
      av = a;
      env.seq.rd(av);
    end

    env.chk.note("F1.4 the sweep changed nothing that should not change");
    env.check_status;

    env.finish_test("tb_uart_reg");
  end

endmodule
