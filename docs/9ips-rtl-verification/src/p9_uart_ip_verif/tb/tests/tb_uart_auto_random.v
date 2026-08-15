`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_uart_auto_random;

  tb_env env();
  `TB_DUMP(tb_uart_auto_random, "tb_uart_auto_random.vcd")

  initial begin
    env.banner("tb_uart_auto_random");
    env.reset_dut;

    env.chk.note("phase 1: base config, mixed traffic");
    env.seq.set_seed(32'h0900_0001);
    env.seq.configure(`BAUD_DIV, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    env.seq.random_traffic(150, `UPROF_MIXED);
    env.drain_serial(40);
    env.seq.drain_rx(`UART_FIFO_DEPTH);
    env.seq.clear_errors;
    env.check_status;

    env.chk.note("phase 2: provoke errors");
    env.seq.set_seed(32'h0900_0002);
    env.seq.configure(`BAUD_DIV, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);  // parity on
    env.seq.recv_bad_stop(8'h5A);   env.settle(20); env.seq.clear_errors;
    env.seq.recv_bad_parity(8'h3C); env.settle(20); env.seq.clear_errors;
    env.seq.random_traffic(80, `UPROF_RX);   // may overrun the FIFO -> overrun bin
    env.drain_serial(40);
    env.seq.drain_rx(`UART_FIFO_DEPTH);
    env.seq.clear_errors;
    env.sb.resync_rx;
    env.check_status;

    env.chk.note("phase 3: coverage-driven closure");
    env.run_until_covered(`AUTO_COV_FLOOR, `AUTO_MAX_ROUNDS);
    env.check_status;

    env.chk.note("phase 4: second seed");
    env.seq.set_seed(32'hBEEF_0904);
    env.seq.random_config(0, 1);
    env.seq.random_traffic(150, `UPROF_MIXED);
    env.drain_serial(40);
    env.seq.drain_rx(`UART_FIFO_DEPTH);
    env.seq.clear_errors;
    env.check_status;

    env.require_checks(4, 4);
    env.require_coverage(`AUTO_COV_FLOOR);
    env.finish_test("tb_uart_auto_random");
  end

endmodule
