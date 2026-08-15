`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_uart_auto_rx;

  tb_env env();
  `TB_DUMP(tb_uart_auto_rx, "tb_uart_auto_rx.vcd")

  integer i;
  reg [7:0] d;
  reg [7:0] iv;

  initial begin
    env.banner("tb_uart_auto_rx");
    env.reset_dut;

    env.chk.note("1: receive at the nominal rate");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    env.seq.set_line_style(`LINE_EXACT);
    for (i = 0; i < 4; i = i + 1) begin
      iv = i; d = 8'h10 + iv;
      env.seq.recv_byte(d);
    end
    env.seq.drain_rx(`UART_FIFO_DEPTH);
    env.check_status;

    env.chk.note("2: transmitter 3% fast");
    env.seq.set_line_style(`LINE_FAST);
    for (i = 0; i < 4; i = i + 1) begin
      iv = i; d = 8'h20 + iv;
      env.seq.recv_byte(d);
    end
    env.seq.drain_rx(`UART_FIFO_DEPTH);

    env.chk.note("3: transmitter 3% slow");
    env.seq.set_line_style(`LINE_SLOW);
    for (i = 0; i < 4; i = i + 1) begin
      iv = i; d = 8'h30 + iv;
      env.seq.recv_byte(d);
    end
    env.seq.drain_rx(`UART_FIFO_DEPTH);
    env.check_status;

    env.chk.note("4: sweep parity and stop formats");
    env.seq.set_line_style(`LINE_EXACT);
    env.seq.configure(`BAUD_DIV, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
    env.seq.recv_byte(8'h5A); env.seq.drain_rx(1);
    env.seq.configure(`BAUD_DIV, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0);
    env.seq.recv_byte(8'hA5); env.seq.drain_rx(1);
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
    env.seq.recv_byte(8'h3C); env.seq.drain_rx(1);
    env.check_status;

    env.chk.note("5: fill the receive FIFO and drain it in order");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    for (i = 0; i < `UART_FIFO_DEPTH; i = i + 1) begin
      iv = i; d = 8'h60 + iv;
      env.seq.recv_byte(d);
    end
    env.seq.drain_rx(`UART_FIFO_DEPTH);
    env.check_status;

    env.require_checks(0, 12);
    env.finish_test("tb_uart_auto_rx");
  end

endmodule
