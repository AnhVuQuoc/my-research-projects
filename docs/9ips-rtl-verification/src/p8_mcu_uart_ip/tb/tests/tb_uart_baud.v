`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_uart_baud;

  tb_env env();
  `TB_DUMP(tb_uart_baud, "tb_uart_baud.vcd")

  integer i;
  reg [7:0] d;
  reg [7:0] iv;

  initial begin
    env.banner("tb_uart_baud");
    env.reset_dut;
	
    env.chk.note("F4.1 transmitted bit period matches the divisor");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    env.set_expected_bit_period(`BAUD_DIV, 3.0);
    env.cov.hit_parity_none;

    for (i = 0; i < 4; i = i + 1) begin
      iv = i;
      d  = 8'h55 + iv;
      env.expect_tx(d);
      env.seq.send_byte(d);
      env.settle(`FRAME_CYCLES(`BAUD_DIV, 10));
    end
    env.chk.note("F4.2 the same, at twice the divisor");
    env.seq.configure(`BAUD_DIV_ALT, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    env.set_expected_bit_period(`BAUD_DIV_ALT, 3.0);

    for (i = 0; i < 3; i = i + 1) begin
      iv = i;
      d  = 8'hA0 + iv;
      env.expect_tx(d);
      env.seq.send_byte(d);
      env.settle(`FRAME_CYCLES(`BAUD_DIV_ALT, 10));
    end

    env.chk.note("F4.3 parity and two stop bits do not disturb the bit period");
    env.seq.configure(`BAUD_DIV, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0);
    env.set_expected_bit_period(`BAUD_DIV, 3.0);
    env.cov.hit_parity_even;
    env.cov.hit_stop2;

    for (i = 0; i < 3; i = i + 1) begin
      iv = i;
      d  = 8'h0F + iv;
      env.expect_tx(d);
      env.seq.send_byte(d);
      env.settle(`FRAME_CYCLES(`BAUD_DIV, 12));
    end

    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

    env.chk.note("F5.1 receive at exactly the nominal rate");
    env.seq.set_line_style(`LINE_EXACT);
    for (i = 0; i < 4; i = i + 1) begin
      iv = i;
      d  = 8'h11 * (iv + 8'd1);
      env.seq.recv_byte(d);
      env.note_rx_byte(d);
      env.seq.rd(`UREG_RXDATA);
      env.chk.expect_eq("byte received at nominal rate", env.seq.m.last_rdata, {24'd0, d});
    end
    env.check_status;

    env.chk.note("F5.2 receive from a transmitter running 3% FAST");
    env.seq.set_line_style(`LINE_FAST);
    for (i = 0; i < 4; i = i + 1) begin
      iv = i;
      d  = 8'h27 + iv;
      env.seq.recv_byte(d);
      env.note_rx_byte(d);
      env.seq.rd(`UREG_RXDATA);
      env.chk.expect_eq("byte received from a fast transmitter", env.seq.m.last_rdata, {24'd0, d});
    end
    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("no framing error at +3%", env.seq.m.last_rdata[`ST_ERR_FRAME] === 1'b0);

    env.chk.note("F5.3 receive from a transmitter running 3% SLOW");
    env.seq.set_line_style(`LINE_SLOW);
    for (i = 0; i < 4; i = i + 1) begin
      iv = i;
      d  = 8'h71 + iv;
      env.seq.recv_byte(d);
      env.note_rx_byte(d);
      env.seq.rd(`UREG_RXDATA);
      env.chk.expect_eq("byte received from a slow transmitter", env.seq.m.last_rdata, {24'd0, d});
    end
    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("no framing error at -3%", env.seq.m.last_rdata[`ST_ERR_FRAME] === 1'b0);
    env.check_status;

    env.chk.note("F5.4 receive at a different configured rate");
    env.seq.set_line_style(`LINE_EXACT);
    env.seq.configure(`BAUD_DIV_ALT, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    for (i = 0; i < 3; i = i + 1) begin
      iv = i;
      d  = 8'hE1 + iv;
      env.seq.recv_byte(d);
      env.note_rx_byte(d);
      env.seq.rd(`UREG_RXDATA);
      env.chk.expect_eq("byte received at the second rate",
                        env.seq.m.last_rdata, {24'd0, d});
    end
    env.check_status;

    env.chk.note("F5.5 a glitch on the line is not mistaken for a start bit");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    env.seq.line_glitch(`CLK_PERIOD * 2);
    env.seq.line_idle(2);
    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("the glitch produced no byte", env.seq.m.last_rdata[`ST_RX_EMPTY] === 1'b1);
    env.chk.expect_true("and no framing error", env.seq.m.last_rdata[`ST_ERR_FRAME] === 1'b0);
    env.seq.recv_byte(8'h6D);
    env.note_rx_byte(8'h6D);
    env.seq.rd(`UREG_RXDATA);
    env.chk.expect_eq("the frame after a glitch is intact", env.seq.m.last_rdata, 32'h0000_006D);
    env.check_status;
    env.chk.require_evaluations(10, 30);
    env.finish_test("tb_uart_baud");
  end

endmodule
