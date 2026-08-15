`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_uart_auto_tx;

  tb_env env();
  `TB_DUMP(tb_uart_auto_tx, "tb_uart_auto_tx.vcd")

  integer i;
  reg ok;
  reg [7:0] d;

  initial begin
    env.banner("tb_uart_auto_tx");
    env.reset_dut;
    env.seq.set_seed(32'h00A0_0001);

    env.chk.note("1: bit-order patterns at the nominal rate");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    for (i = 0; i < 6; i = i + 1) begin
      case (i)
        0: d = 8'h00; 1: d = 8'hFF; 2: d = 8'h01;
        3: d = 8'h80; 4: d = 8'hAA; default: d = 8'h55;
      endcase
      env.seq.send_byte_fc(d, ok);
      env.settle(`FRAME_CYCLES(`BAUD_DIV, 10) + 8);
    end
    env.check_status;

    env.chk.note("2: burst larger than the FIFO, flow-controlled");
    env.seq.send_burst(20);
    env.settle(`FRAME_CYCLES(`BAUD_DIV, 10) * 24);
    env.check_status;

    env.chk.note("3: alternate baud rate");
    env.seq.configure(`BAUD_DIV_ALT, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    env.seq.send_burst(8);
    env.settle(`FRAME_CYCLES(`BAUD_DIV_ALT, 10) * 12);
    env.check_status;

    env.chk.note("4: even parity, two stop bits");
    env.seq.configure(`BAUD_DIV, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0);
    env.seq.send_burst(8);
    env.settle(`FRAME_CYCLES(`BAUD_DIV, 12) * 12);
    env.check_status;

    env.require_checks(20, 0);
    env.finish_test("tb_uart_auto_tx");
  end

endmodule
