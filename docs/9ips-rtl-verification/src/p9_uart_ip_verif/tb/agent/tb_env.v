`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_env #(
  parameter AW = `U_AW,
  parameter DW = `U_DW
);
  reg pclk, presetn;
  initial begin
    pclk = 1'b0;
    forever #(`CLK_PERIOD/2) pclk = ~pclk;
  end

  wire          psel, penable, pwrite, pready, pslverr;
  wire [AW-1:0] paddr;
  wire [DW-1:0] pwdata, prdata;
  wire          rx_line, tx_line, irq;
  wire          tr_vld, tr_write, tr_err;
  wire [AW-1:0] tr_addr;
  wire [DW-1:0] tr_wdata, tr_rdata;
  wire [7:0]    tr_waits;
  wire [31:0]   n_reads, n_writes, n_errors;
  wire          exp_err;
  wire [DW-1:0] exp_rdata;
  wire [31:0]   n_prot_errors, n_prot_checks;
  wire          byte_vld;
  wire [7:0]    tx_byte_seen;
  wire          par_bit_seen, stop_ok_seen;
  wire [31:0]   n_bytes_seen;
  wire          pred_vld, pred_frame, pred_parity;
  wire [7:0]    pred_data;
  wire [31:0]   sb_tx_chk, sb_tx_mis, sb_rx_chk, sb_rx_mis;

  apb_uart #(.AW(AW), .DW(DW)) dut (
    .pclk      (pclk),   .presetn (presetn),
    .psel_i    (psel),   .penable_i(penable), .pwrite_i(pwrite),
    .paddr_i   (paddr),  .pwdata_i (pwdata),
    .prdata_o  (prdata), .pready_o (pready),  .pslverr_o(pslverr),
    .rx_i      (rx_line),.tx_o     (tx_line), .irq_o    (irq)
  );

  wire tx_busy = dut.u_core.tx_busy;

  uart_seq_auto #(.AW(AW), .DW(DW)) seq (
    .pclk    (pclk),   .presetn(presetn),
    .psel_o  (psel),   .penable_o(penable), .pwrite_o(pwrite),
    .paddr_o (paddr),  .pwdata_o (pwdata),
    .prdata_i(prdata), .pready_i (pready),  .pslverr_i(pslverr),
    .rx_o    (rx_line)
  );

  apb_monitor #(.AW(AW), .DW(DW)) mon (
    .pclk (pclk), .presetn(presetn),
    .psel_i(psel), .penable_i(penable), .pwrite_i(pwrite),
    .paddr_i(paddr), .pwdata_i(pwdata), .prdata_i(prdata),
    .pready_i(pready), .pslverr_i(pslverr),
    .tr_vld_o(tr_vld), .tr_write_o(tr_write), .tr_addr_o(tr_addr),
    .tr_wdata_o(tr_wdata), .tr_rdata_o(tr_rdata), .tr_err_o(tr_err),
    .tr_waits_o(tr_waits),
    .n_reads_o(n_reads), .n_writes_o(n_writes), .n_errors_o(n_errors)
  );

  apb_protocol_checker #(.AW(AW), .DW(DW)) prot (
    .pclk(pclk), .presetn(presetn),
    .psel_i(psel), .penable_i(penable), .pwrite_i(pwrite),
    .paddr_i(paddr), .pwdata_i(pwdata), .pready_i(pready), .pslverr_i(pslverr),
    .n_prot_errors_o(n_prot_errors), .n_prot_checks_o(n_prot_checks)
  );

  serial_monitor smon (
    .line_i(tx_line),
    .byte_vld_o(byte_vld), .byte_o(tx_byte_seen),
    .par_bit_o(par_bit_seen), .stop_ok_o(stop_ok_seen), .n_bytes_o(n_bytes_seen)
  );

  reg        cfg_en, cfg_par_en, cfg_par_odd, cfg_stop2, cfg_irq_en, cfg_loop;
  reg [15:0] cfg_div;

  initial begin
    cfg_en=0; cfg_par_en=0; cfg_par_odd=0; cfg_stop2=0; cfg_irq_en=0; cfg_loop=0;
    cfg_div = `BAUD_DIV;
  end

  always @(posedge pclk) begin
    if (presetn && tr_vld && tr_write && !tr_err) begin
      if (tr_addr == `UREG_CTRL) begin
        cfg_en      <= tr_wdata[`CTRL_EN];
        cfg_par_en  <= tr_wdata[`CTRL_PAR_EN];
        cfg_par_odd <= tr_wdata[`CTRL_PAR_ODD];
        cfg_stop2   <= tr_wdata[`CTRL_STOP2];
        cfg_loop    <= tr_wdata[`CTRL_LOOPBACK];
        cfg_irq_en  <= tr_wdata[`CTRL_IRQ_EN];
        smon.configure(cfg_div, tr_wdata[`CTRL_PAR_EN], tr_wdata[`CTRL_PAR_ODD], tr_wdata[`CTRL_STOP2]);
      end
      if (tr_addr == `UREG_BAUD) begin
        cfg_div <= (tr_wdata[15:0] < `UART_BAUD_MIN) ? `UART_BAUD_MIN : tr_wdata[15:0];
        smon.configure((tr_wdata[15:0] < `UART_BAUD_MIN) ? `UART_BAUD_MIN : tr_wdata[15:0], cfg_par_en, cfg_par_odd, cfg_stop2);
      end
    end
  end

  wire pred_line = cfg_loop ? tx_line : rx_line;

  rx_predictor rxp (
    .clk(pclk), .rst_n(presetn),
    .rx_i(pred_line),
    .cfg_div_i(cfg_div), .cfg_par_en_i(cfg_par_en),
    .cfg_par_odd_i(cfg_par_odd), .cfg_stop2_i(cfg_stop2), .cfg_en_i(cfg_en),
    .pred_vld_o(pred_vld), .pred_data_o(pred_data),
    .pred_frame_o(pred_frame), .pred_parity_o(pred_parity)
  );

  uart_model fmodel ();

  always @(posedge pclk) begin
    if (presetn) begin
      if (pred_vld)    fmodel.push_rx(pred_data);
      if (pred_frame)  fmodel.set_err_frame;
      if (pred_parity) fmodel.set_err_parity;
    end
  end

  reg_model #(.AW(AW), .DW(DW)) rmodel (
    .pclk(pclk), .presetn(presetn),
    .psel_i(psel), .penable_i(penable), .pwrite_i(pwrite),
    .paddr_i(paddr), .pwdata_i(pwdata), .pready_i(pready),
    .tx_busy_i(tx_busy),
    .exp_err_o(exp_err), .exp_rdata_o(exp_rdata)
  );


  checker #(.AW(AW), .DW(DW)) chk (
    .pclk(pclk), .presetn(presetn),
    .psel_i(psel), .penable_i(penable), .pwrite_i(pwrite),
    .paddr_i(paddr), .prdata_i(prdata), .pready_i(pready), .pslverr_i(pslverr),
    .exp_err_i(exp_err), .exp_rdata_i(exp_rdata),
    .tx_i(tx_line), .rx_i(rx_line), .irq_i(irq),
    .n_prot_errors_i(n_prot_errors), .n_prot_checks_i(n_prot_checks)
  );

  wire tx_push = tr_vld && tr_write && (tr_addr == `UREG_TXDATA) && !tr_err;

  wire rx_read = tr_vld && !tr_write && (tr_addr == `UREG_RXDATA) && !tr_err;

  byte_scoreboard sb (
    .clk(pclk), .rst_n(presetn),
    .tx_push_i(tx_push), .tx_push_data_i(tr_wdata[7:0]),
    .tx_wire_i(byte_vld), .tx_wire_data_i(tx_byte_seen),
    .rx_pred_i(pred_vld), .rx_pred_data_i(pred_data),
    .rx_read_i(rx_read), .rx_read_data_i(tr_rdata[7:0]),
    .n_tx_checked_o(sb_tx_chk), .n_tx_mismatch_o(sb_tx_mis),
    .n_rx_checked_o(sb_rx_chk), .n_rx_mismatch_o(sb_rx_mis)
  );

  coverage_auto #(.AW(AW), .DW(DW)) cov (
    .pclk(pclk), .presetn(presetn),
    .tr_vld_i(tr_vld), .tr_write_i(tr_write), .tr_addr_i(tr_addr),
    .tr_wdata_i(tr_wdata), .tr_rdata_i(tr_rdata), .tr_err_i(tr_err),
    .tx_busy_i(tx_busy), .irq_i(irq),
    .pred_frame_i(pred_frame), .pred_parity_i(pred_parity)
  );

  `TB_WATCHDOG(pclk, `WD_CYCLES)

  real exp_bit_ns, tol_pct;
  initial begin exp_bit_ns = `BAUD_DIV * `CLK_PERIOD; tol_pct = 5.0; end

  always @(posedge byte_vld) begin
    if (presetn)
      chk.check_bit_period(smon.last_bit_period(0),
                           cfg_div * `CLK_PERIOD, 5.0);
  end

  task banner;
    input [255:0] name;
    begin
      $display("TEST START : %0s", name);
    end
  endtask

  task reset_dut;
    begin
      presetn = 1'b0;
      fmodel.reset_model;
      repeat (4) @(posedge pclk);
      @(negedge pclk);
      presetn = 1'b1;
      repeat (2) @(posedge pclk);
    end
  endtask

  task settle; input integer c; begin repeat (c) @(posedge pclk); end endtask

  task check_status;
    begin
      settle(`SETTLE_CYCLES);
      seq.rd(`UREG_STATUS);
      chk.compare_status(seq.m.last_rdata, fmodel.exp_status({31'd0, tx_busy}));
    end
  endtask

  task check_irq_now;
    begin chk.check_irq(irq, (fmodel.exp_irq(0) != 32'd0)); end
  endtask

  task drain_serial;
    input integer max_settle;
    integer g;
    begin
      g = 0;
      while ((sb.tx_outstanding(0) != 0) && (g < max_settle)) begin
        settle(`SETTLE_CYCLES);
        g = g + 1;
      end
      settle(`SETTLE_CYCLES);
    end
  endtask

  task finish_test;
    input [255:0] name;
    begin
      drain_serial(200);
      settle(`SETTLE_CYCLES);
      $display("");
      $display(" apb monitor    : reads=%0d writes=%0d errors=%0d",
               n_reads, n_writes, n_errors);
      $display(" serial monitor : %0d frames observed on tx", n_bytes_seen);
      fmodel.report;
      sb.report;
      chk.expect_eq("byte scoreboard TX mismatches", sb_tx_mis, 32'd0);
      chk.expect_eq("byte scoreboard RX mismatches", sb_rx_mis, 32'd0);
      cov.report(name);
      chk.report(name);
      $finish;
    end
  endtask

  task require_checks;
    input integer min_tx;
    input integer min_rx;
    begin
      chk.expect_true("TX bytes were scoreboard-checked", sb_tx_chk >= min_tx);
      chk.expect_true("RX bytes were scoreboard-checked", sb_rx_chk >= min_rx);
    end
  endtask

  task require_coverage;
    input integer pct;
    begin
      if (cov.coverage_pct(0) < pct) begin
        $display("[%0t] ERROR coverage %0d%% below floor %0d%%", $time, cov.coverage_pct(0), pct);
        $display("RESULT: FAILED");
        $finish;
      end
    end
  endtask

  task run_until_covered;
    input integer floor;
    input integer max_rounds;
    integer r;
    begin
      r = 0;
      while ((cov.coverage_pct(0) < floor) && (r < max_rounds)) begin
        seq.random_config(0, (r % 2));
        seq.set_line_style((r % 3 == 0) ? `LINE_EXACT : (r % 3 == 1) ? `LINE_FAST : `LINE_SLOW);
        seq.random_traffic(60, `UPROF_MIXED);
        drain_serial(40);
        seq.drain_rx(`UART_FIFO_DEPTH);
        seq.clear_errors;
        sb.resync_rx;
        r = r + 1;
      end
      $display(" coverage-driven loop ran %0d round(s), reached %0d%%", r, cov.coverage_pct(0));
    end
  endtask

endmodule
