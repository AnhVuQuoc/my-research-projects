`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_uart_loopback;

  tb_env env();
  `TB_DUMP(tb_uart_loopback, "tb_uart_loopback.vcd")

  integer i;
  reg [7:0] d;

  initial begin
    env.banner("tb_uart_loopback");
    env.reset_dut;
	
    env.chk.note("F3.1 one byte, no parity, one stop bit");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);
    env.set_expected_bit_period(`BAUD_DIV, 5.0);
    env.cov.hit_parity_none;

    env.expect_tx(8'h5A);
    env.seq.send_byte(8'h5A);

    env.settle(`FRAME_CYCLES(`BAUD_DIV, 10));

    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("receive FIFO is no longer empty", env.seq.m.last_rdata[`ST_RX_EMPTY] === 1'b0);

    env.note_rx_byte(8'h5A);
    env.seq.rd(`UREG_RXDATA);
    env.chk.expect_eq("the byte came back intact", env.seq.m.last_rdata, 32'h0000_005A);
    env.check_status;

    env.chk.note("F3.2 a set of bytes chosen to catch bit-order faults");
    for (i = 0; i < 6; i = i + 1) begin
      case (i)
        0: d = 8'h00;
        1: d = 8'hFF;
        2: d = 8'h01;
        3: d = 8'h80;
        4: d = 8'hAA;
        default: d = 8'h55;
      endcase
      env.expect_tx(d);
      env.seq.send_byte(d);
      env.settle(`FRAME_CYCLES(`BAUD_DIV, 10));
      env.note_rx_byte(d);
      env.seq.rd(`UREG_RXDATA);
      env.chk.expect_eq("loopback byte", env.seq.m.last_rdata, {24'd0, d});
    end
    env.check_status;

    env.chk.note("F3.3 even parity");
    env.seq.configure(`BAUD_DIV, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0);
    env.cov.hit_parity_even;
    env.expect_tx(8'h3C);
    env.seq.send_byte(8'h3C);
    env.settle(`FRAME_CYCLES(`BAUD_DIV, 11));
    env.note_rx_byte(8'h3C);
    env.seq.rd(`UREG_RXDATA);
    env.chk.expect_eq("even parity round trip", env.seq.m.last_rdata, 32'h0000_003C);
    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("no parity error", env.seq.m.last_rdata[`ST_ERR_PARITY] === 1'b0);

    env.chk.note("F3.4 odd parity");
    env.seq.configure(`BAUD_DIV, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0);
    env.cov.hit_parity_odd;
    env.expect_tx(8'h3C);
    env.seq.send_byte(8'h3C);
    env.settle(`FRAME_CYCLES(`BAUD_DIV, 11));
    env.note_rx_byte(8'h3C);
    env.seq.rd(`UREG_RXDATA);
    env.chk.expect_eq("odd parity round trip", env.seq.m.last_rdata, 32'h0000_003C);
    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("no parity error", env.seq.m.last_rdata[`ST_ERR_PARITY] === 1'b0);

    env.chk.note("F3.5 two stop bits");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0);
    env.cov.hit_stop2;
    env.expect_tx(8'hC3);
    env.seq.send_byte(8'hC3);
    env.settle(`FRAME_CYCLES(`BAUD_DIV, 12));
    env.note_rx_byte(8'hC3);
    env.seq.rd(`UREG_RXDATA);
    env.chk.expect_eq("two stop bits round trip", env.seq.m.last_rdata, 32'h0000_00C3);
    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("no framing error", env.seq.m.last_rdata[`ST_ERR_FRAME] === 1'b0);

    env.chk.note("F3.6 a second baud rate, to prove the divisor is used");
    env.seq.configure(`BAUD_DIV_ALT, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);
    env.set_expected_bit_period(`BAUD_DIV_ALT, 5.0);
    env.expect_tx(8'h96);
    env.seq.send_byte(8'h96);
    env.settle(`FRAME_CYCLES(`BAUD_DIV_ALT, 10));
    env.note_rx_byte(8'h96);
    env.seq.rd(`UREG_RXDATA);
    env.chk.expect_eq("round trip at the second rate", env.seq.m.last_rdata, 32'h0000_0096);
    env.check_status;

    env.chk.require_evaluations(10, 20);
    env.finish_test("tb_uart_loopback");
  end

endmodule
