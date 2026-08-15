`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_uart_error;

  tb_env env();
  `TB_DUMP(tb_uart_error, "tb_uart_error.vcd")

  integer i;

  initial begin
    env.banner("tb_uart_error");
    env.reset_dut;

    env.chk.note("F7.1 framing error: the stop bit is low");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    env.seq.recv_bad_stop(8'hA5);
    env.note_rx_frame_error;
    env.seq.line_idle(2);
    env.settle(8);

    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("framing error reported", env.seq.m.last_rdata[`ST_ERR_FRAME] === 1'b1);
    env.chk.expect_true("no parity error reported", env.seq.m.last_rdata[`ST_ERR_PARITY] === 1'b0);
    env.chk.expect_true("the malformed byte was NOT delivered", env.seq.m.last_rdata[`ST_RX_EMPTY] === 1'b1);
    env.cov.hit_err_frame;

    env.chk.note("F7.2 the receiver recovers and takes the next good frame");
    env.seq.recv_byte(8'h5A);
    env.note_rx_byte(8'h5A);
    env.seq.rd(`UREG_RXDATA);
    env.chk.expect_eq("the frame after a framing error is intact", env.seq.m.last_rdata, 32'h0000_005A);

    env.seq.clear_errors;
    env.settle(4);
    env.check_status;

    env.chk.note("F7.3 parity error: the frame is perfect, one bit is wrong");
    env.seq.configure(`BAUD_DIV, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
    env.cov.hit_parity_even;
    env.seq.recv_bad_parity(8'h3C);
    env.note_rx_parity_error;
    env.seq.line_idle(2);
    env.settle(8);

    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("parity error reported", env.seq.m.last_rdata[`ST_ERR_PARITY] === 1'b1);
    env.chk.expect_true("no framing error - the stop bit was fine", env.seq.m.last_rdata[`ST_ERR_FRAME] === 1'b0);
    env.cov.hit_err_parity;

    env.note_rx_byte(8'h3C);
    env.seq.rd(`UREG_RXDATA);
    env.chk.expect_eq("the byte is delivered despite bad parity", env.seq.m.last_rdata, 32'h0000_003C);

    env.seq.clear_errors;
    env.settle(4);

    env.chk.note("F7.4 odd parity, error case");
    env.seq.configure(`BAUD_DIV, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0);
    env.cov.hit_parity_odd;
    env.seq.recv_bad_parity(8'h77);
    env.note_rx_parity_error;
    env.seq.line_idle(2);
    env.settle(8);
    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("odd parity error reported", env.seq.m.last_rdata[`ST_ERR_PARITY] === 1'b1);
    env.note_rx_byte(8'h77);
    env.seq.drain_rx(1);
    env.seq.clear_errors;
    env.settle(4);

    env.chk.note("F7.5 sticky flags survive until explicitly cleared");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    env.seq.recv_bad_stop(8'h11);
    env.note_rx_frame_error;
    env.seq.line_idle(2);
    env.settle(8);

    for (i = 0; i < 5; i = i + 1) begin
      env.seq.rd(`UREG_STATUS);
      env.chk.expect_true("flag still set on repeated polls", env.seq.m.last_rdata[`ST_ERR_FRAME] === 1'b1);
    end

    env.seq.recv_bad_parity(8'h22);
    env.note_rx_parity_error;
    env.seq.line_idle(2);
    env.settle(8);
    env.seq.wr(`UREG_ICLR, 32'd1 << `ICLR_FRAME);
    env.settle(4);
    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("framing flag cleared", env.seq.m.last_rdata[`ST_ERR_FRAME] === 1'b0);
    env.chk.expect_true("parity flag untouched", env.seq.m.last_rdata[`ST_ERR_PARITY] === 1'b1);

    env.seq.clear_errors;
    env.settle(4);
    env.seq.drain_rx(`UART_FIFO_DEPTH);

    env.chk.note("F7.6 the interrupt follows the error and data conditions");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    env.settle(4);
    env.check_irq_now;

    env.seq.recv_byte(8'h81);
    env.note_rx_byte(8'h81);
    env.settle(4);
    env.chk.expect_true("interrupt asserted with data waiting", env.irq === 1'b1);
    env.check_irq_now;

    env.seq.rd(`UREG_RXDATA);
    env.settle(4);
    env.chk.expect_true("interrupt released once the FIFO is drained", env.irq === 1'b0);
    env.check_irq_now;

    env.check_status;
    env.finish_test("tb_uart_error");
  end

endmodule
