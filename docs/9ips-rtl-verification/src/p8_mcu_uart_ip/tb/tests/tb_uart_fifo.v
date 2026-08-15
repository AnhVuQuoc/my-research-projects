`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_uart_fifo;

  tb_env env();
  `TB_DUMP(tb_uart_fifo, "tb_uart_fifo.vcd")

  integer i;
  reg [7:0] d;
  reg [7:0] iv;

  initial begin
    env.banner("tb_uart_fifo");
    env.reset_dut;
	
    env.chk.note("F6.1 transmit FIFO fills and reports full");
    env.seq.configure(32'd256, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    env.set_expected_bit_period(256, 5.0);

    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("transmit FIFO starts empty", env.seq.m.last_rdata[`ST_TX_EMPTY] === 1'b1);

    for (i = 0; i < `UART_FIFO_DEPTH + 1; i = i + 1) begin
      iv = i;
      d  = 8'hB0 + iv;
      env.expect_tx(d);
      env.seq.send_byte(d);
    end

    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("transmit FIFO reports full", env.seq.m.last_rdata[`ST_TX_FULL] === 1'b1);
    env.chk.expect_true("and is not empty", env.seq.m.last_rdata[`ST_TX_EMPTY] === 1'b0);
    env.cov.hit_tx_full;

    env.chk.note("F6.2 a write to a full transmit FIFO is dropped");
    env.seq.send_byte(8'hEE);
    env.chk.expect_eq("the dropped write is not a bus error", {31'd0, env.seq.m.last_err}, 32'd0);

    env.settle(`FRAME_CYCLES(256, 10) * (`UART_FIFO_DEPTH + 2));
    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("transmit FIFO drained", env.seq.m.last_rdata[`ST_TX_EMPTY] === 1'b1);

    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    env.set_expected_bit_period(`BAUD_DIV, 5.0);

    env.chk.note("F6.3 receive FIFO fills");
    for (i = 0; i < `UART_FIFO_DEPTH; i = i + 1) begin
      iv = i;
      d  = 8'h40 + iv;
      env.seq.recv_byte(d);
      env.note_rx_byte(d);
    end

    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("receive FIFO reports full", env.seq.m.last_rdata[`ST_RX_FULL] === 1'b1);
    env.cov.hit_rx_full;

    env.chk.note("F6.4 a byte arriving with the receive FIFO full is an overrun");
    env.seq.recv_byte(8'h99);
    env.note_rx_byte(8'h99);
    env.settle(8);

    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("overrun flag set", env.seq.m.last_rdata[`ST_ERR_OVERRUN] === 1'b1);
    env.cov.hit_err_overrun;

    env.chk.note("F6.5 the FIFO still holds the ORIGINAL bytes, in order");
    for (i = 0; i < `UART_FIFO_DEPTH; i = i + 1) begin
      iv = i;
      env.seq.rd(`UREG_RXDATA);
      env.chk.expect_eq("buffered byte survived the overrun", env.seq.m.last_rdata, {24'd0, (8'h40 + iv)});
    end

    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("receive FIFO now empty", env.seq.m.last_rdata[`ST_RX_EMPTY] === 1'b1);

    env.chk.note("F6.6 the overrun flag is sticky until cleared");
    env.chk.expect_true("still set after draining", env.seq.m.last_rdata[`ST_ERR_OVERRUN] === 1'b1);
    env.seq.clear_errors;
    env.settle(4);
    env.seq.rd(`UREG_STATUS);
    env.chk.expect_true("cleared by writing one to ICLR", env.seq.m.last_rdata[`ST_ERR_OVERRUN] === 1'b0);
    env.check_status;

    env.chk.note("F6.7 reading an empty receive FIFO is harmless");
    for (i = 0; i < 3; i = i + 1) env.seq.rd(`UREG_RXDATA);
    env.chk.expect_eq("empty read is not an error", {31'd0, env.seq.m.last_err}, 32'd0);

    env.seq.recv_byte(8'h7E);
    env.note_rx_byte(8'h7E);
    env.seq.rd(`UREG_RXDATA);
    env.chk.expect_eq("the next real byte is correct", env.seq.m.last_rdata, 32'h0000_007E);
    env.check_status;

    env.finish_test("tb_uart_fifo");
  end

endmodule
