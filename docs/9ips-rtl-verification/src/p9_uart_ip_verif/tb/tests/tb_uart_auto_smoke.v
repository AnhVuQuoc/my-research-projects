`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_uart_auto_smoke;

  tb_env env();
  `TB_DUMP(tb_uart_auto_smoke, "tb_uart_auto_smoke.vcd")

  integer i;
  reg     ok;
  reg [7:0] d;
  reg [7:0] iv;

  initial begin
    env.banner("tb_uart_auto_smoke");
    env.reset_dut;

    env.chk.note("1: loopback, no parity, one stop");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);
    env.seq.send_byte_fc(8'h5A, ok);
    env.settle(`FRAME_CYCLES(`BAUD_DIV, 10) + 40);
    env.seq.read_rx_fc(ok);
    env.chk.expect_true("a byte was available to read", ok);
    env.check_status;

    env.chk.note("2: external receive, self-predicted");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    env.seq.recv_byte(8'hC3);
    env.settle(40);
    env.seq.read_rx_fc(ok);
    env.chk.expect_true("received byte present", ok);
    env.check_status;

    env.chk.note("3: small burst, transmit then receive");
    for (i = 0; i < 4; i = i + 1) begin
      iv = i; d = 8'h11 + iv;
      env.seq.send_byte_fc(d, ok);
    end
    env.settle(`FRAME_CYCLES(`BAUD_DIV, 10) * 5);

    for (i = 0; i < 4; i = i + 1) begin
      iv = i; d = 8'hA0 + iv;
      env.seq.recv_byte(d);
    end
    env.seq.drain_rx(6);
    env.check_status;

    env.chk.note("4: reconfigure to even parity from the bus");
    env.seq.configure(`BAUD_DIV, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
    env.seq.recv_byte(8'h3C);
    env.seq.drain_rx(2);
    env.check_status;

    env.require_checks(4, 4);
    env.finish_test("tb_uart_auto_smoke");
  end

endmodule
