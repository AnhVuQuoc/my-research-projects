`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_uart_random;

  tb_env env();
  `TB_DUMP(tb_uart_random, "tb_uart_random.vcd")

  initial begin
    env.banner("tb_uart_random");
    env.reset_dut;

    env.chk.note("phase 1: register traffic only");
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
    env.set_expected_bit_period(`BAUD_DIV, 5.0);
    env.cov.hit_parity_none;
    env.seq.set_seed(32'h0800_0001);
    env.seq.random_traffic(200, `UPROF_REG);
    env.check_status;

    env.chk.note("phase 2: receive traffic - frames arriving at will");
    env.seq.set_seed(32'h0800_0002);
    env.seq.set_line_style(`LINE_EXACT);
    env.seq.random_traffic(120, `UPROF_RX);
    env.seq.drain_rx(`UART_FIFO_DEPTH);
    env.seq.clear_errors;
    env.settle(16);

    env.chk.note("phase 3: transmit traffic - the FIFO under pressure");
    env.seq.set_seed(32'h0800_0003);
    env.seq.random_traffic(120, `UPROF_TX);
    env.settle(`FRAME_CYCLES(`BAUD_DIV, 10) * 6);

    env.chk.note("phase 4: both interfaces at once - the crossing");
    env.seq.set_seed(32'h0800_0004);
    env.seq.random_traffic(250, `UPROF_MIXED);
    env.seq.drain_rx(`UART_FIFO_DEPTH);
    env.seq.clear_errors;
    env.settle(`FRAME_CYCLES(`BAUD_DIV, 10) * 6);
    env.check_status;

    env.chk.note("phase 5: the same, with the far end running fast");
    env.seq.set_line_style(`LINE_FAST);
    env.seq.set_seed(32'h0800_0005);
    env.seq.random_traffic(200, `UPROF_MIXED);
    env.seq.drain_rx(`UART_FIFO_DEPTH);
    env.seq.clear_errors;
    env.settle(`FRAME_CYCLES(`BAUD_DIV, 10) * 6);

    env.chk.note("phase 6: a second seed, and parity enabled");
    env.seq.set_line_style(`LINE_EXACT);
    env.seq.configure(`BAUD_DIV, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1);
    env.cov.hit_parity_even;
    env.seq.set_seed(32'hFEED_0806);
    env.seq.random_traffic(250, `UPROF_MIXED);
    env.seq.drain_rx(`UART_FIFO_DEPTH);
    env.seq.clear_errors;
    env.settle(`FRAME_CYCLES(`BAUD_DIV, 11) * 6);
    env.check_status;

    env.chk.require_evaluations(0, 300);
    env.require_coverage(75);
    env.finish_test("tb_uart_random");
  end

endmodule
