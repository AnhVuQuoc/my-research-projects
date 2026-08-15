`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_uart_cfg_sweep;

  tb_env env();
  `TB_DUMP(tb_uart_cfg_sweep, "tb_uart_cfg_sweep.vcd")

  integer par, stop2, baud_sel, div;
  reg     pen, podd;
  integer nbits;
  reg [7:0] rv;
  reg ok;
  reg [7:0] dtx, drx;
  integer round;

  initial begin
    env.banner("tb_uart_cfg_sweep");
    env.reset_dut;
    env.seq.set_line_style(`LINE_EXACT);
    round = 0;

    for (par = 0; par < 3; par = par + 1)
      for (stop2 = 0; stop2 < 2; stop2 = stop2 + 1)
        for (baud_sel = 0; baud_sel < 2; baud_sel = baud_sel + 1) begin
          div  = baud_sel ? `BAUD_DIV_ALT : `BAUD_DIV;
          pen  = (par != `PAR_NONE);
          podd = (par == `PAR_ODD);
          nbits = 10 + (pen ? 1 : 0) + (stop2 ? 1 : 0);

          env.chk.note("config round");
          env.seq.configure(div, pen, podd, (stop2!=0), 1'b0, 1'b0);

          rv = round; dtx = 8'h40 + rv;
          env.seq.send_byte_fc(dtx, ok);
          env.settle(`FRAME_CYCLES(div, nbits) + 12);

          rv = round; drx = 8'h80 + rv;
          env.seq.recv_byte(drx);
          env.seq.drain_rx(1);
          env.check_status;

          round = round + 1;
        end

    env.require_checks(12, 12);
    env.finish_test("tb_uart_cfg_sweep");
  end

endmodule
