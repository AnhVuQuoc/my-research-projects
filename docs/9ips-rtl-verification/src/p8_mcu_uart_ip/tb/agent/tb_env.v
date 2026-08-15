`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_env #(
  parameter AW = `U_AW,
  parameter DW = `U_DW
);
  reg pclk;
  reg presetn;

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
  wire [7:0]    rx_byte_seen;
  wire          par_bit_seen, stop_ok_seen;
  wire [31:0]   n_bytes_seen;


  apb_uart #(.AW(AW), .DW(DW)) dut (
    .pclk      (pclk),
    .presetn   (presetn),
    .psel_i    (psel),
    .penable_i (penable),
    .pwrite_i  (pwrite),
    .paddr_i   (paddr),
    .pwdata_i  (pwdata),
    .prdata_o  (prdata),
    .pready_o  (pready),
    .pslverr_o (pslverr),
    .rx_i      (rx_line),
    .tx_o      (tx_line),
    .irq_o     (irq)
  );

  wire tx_busy = dut.u_core.tx_busy;
  
  uart_seq #(.AW(AW), .DW(DW)) seq (
    .pclk      (pclk),
    .presetn   (presetn),
    .psel_o    (psel),
    .penable_o (penable),
    .pwrite_o  (pwrite),
    .paddr_o   (paddr),
    .pwdata_o  (pwdata),
    .prdata_i  (prdata),
    .pready_i  (pready),
    .pslverr_i (pslverr),
    .rx_o      (rx_line)
  );

  apb_monitor #(.AW(AW), .DW(DW)) mon (
    .pclk       (pclk),
    .presetn    (presetn),
    .psel_i     (psel),
    .penable_i  (penable),
    .pwrite_i   (pwrite),
    .paddr_i    (paddr),
    .pwdata_i   (pwdata),
    .prdata_i   (prdata),
    .pready_i   (pready),
    .pslverr_i  (pslverr),
    .tr_vld_o   (tr_vld),
    .tr_write_o (tr_write),
    .tr_addr_o  (tr_addr),
    .tr_wdata_o (tr_wdata),
    .tr_rdata_o (tr_rdata),
    .tr_err_o   (tr_err),
    .tr_waits_o (tr_waits),
    .n_reads_o  (n_reads),
    .n_writes_o (n_writes),
    .n_errors_o (n_errors)
  );

  apb_protocol_checker #(.AW(AW), .DW(DW)) prot (
    .pclk            (pclk),
    .presetn         (presetn),
    .psel_i          (psel),
    .penable_i       (penable),
    .pwrite_i        (pwrite),
    .paddr_i         (paddr),
    .pwdata_i        (pwdata),
    .pready_i        (pready),
    .pslverr_i       (pslverr),
    .n_prot_errors_o (n_prot_errors),
    .n_prot_checks_o (n_prot_checks)
  );

  serial_monitor smon (
    .line_i     (tx_line),
    .byte_vld_o (byte_vld),
    .byte_o     (rx_byte_seen),
    .par_bit_o  (par_bit_seen),
    .stop_ok_o  (stop_ok_seen),
    .n_bytes_o  (n_bytes_seen)
  );

  uart_model fmodel ();

  reg_model #(.AW(AW), .DW(DW)) rmodel (
    .pclk        (pclk),
    .presetn     (presetn),
    .psel_i      (psel),
    .penable_i   (penable),
    .pwrite_i    (pwrite),
    .paddr_i     (paddr),
    .pwdata_i    (pwdata),
    .pready_i    (pready),
    .tx_busy_i   (tx_busy),
    .exp_err_o   (exp_err),
    .exp_rdata_o (exp_rdata)
  );

  checker #(.AW(AW), .DW(DW)) chk (
    .pclk            (pclk),
    .presetn         (presetn),
    .psel_i          (psel),
    .penable_i       (penable),
    .pwrite_i        (pwrite),
    .paddr_i         (paddr),
    .prdata_i        (prdata),
    .pready_i        (pready),
    .pslverr_i       (pslverr),
    .exp_err_i       (exp_err),
    .exp_rdata_i     (exp_rdata),
    .tx_i            (tx_line),
    .rx_i            (rx_line),
    .irq_i           (irq),
    .n_prot_errors_i (n_prot_errors),
    .n_prot_checks_i (n_prot_checks)
  );

  coverage #(.AW(AW), .DW(DW)) cov (
    .pclk       (pclk),
    .presetn    (presetn),
    .tr_vld_i   (tr_vld),
    .tr_write_i (tr_write),
    .tr_addr_i  (tr_addr),
    .tr_err_i   (tr_err),
    .tx_busy_i  (tx_busy),
    .irq_i      (irq)
  );

  `TB_WATCHDOG(pclk, `WD_CYCLES)

  reg [7:0]  tx_expect_q [0:255];
  integer    tx_wr, tx_rd;
  integer    check_tx_enable;
  real       exp_bit_ns;
  real       tol_pct;

  initial begin
    tx_wr = 0; tx_rd = 0;
    check_tx_enable = 1;
    exp_bit_ns = `BAUD_DIV * `CLK_PERIOD;
    tol_pct = 5.0;
  end

  task expect_tx;
    input [7:0] d;
    begin
      tx_expect_q[tx_wr % 256] = d;
      tx_wr = tx_wr + 1;
    end
  endtask

  task set_expected_bit_period;
    input integer div_cycles;
    input real    tol;
    begin
      exp_bit_ns = div_cycles * `CLK_PERIOD;
      tol_pct    = tol;
    end
  endtask

  always @(posedge byte_vld) begin
    if (check_tx_enable) begin
      if (tx_rd < tx_wr) begin
        chk.check_frame(rx_byte_seen, tx_expect_q[tx_rd % 256], stop_ok_seen);
        chk.check_bit_period(smon.last_bit_period(0), exp_bit_ns, tol_pct);
        tx_rd = tx_rd + 1;
      end else begin
        chk.expect_true("a frame was transmitted that no test expected", 1'b0);
      end
    end
  end

  task note_rx_byte;
    input [7:0] d;
    begin fmodel.push_rx(d); end
  endtask

  task note_rx_frame_error;  begin fmodel.set_err_frame;  end endtask
  task note_rx_parity_error; begin fmodel.set_err_parity; end endtask

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
      tx_wr = 0; tx_rd = 0;
      repeat (4) @(posedge pclk);
      @(negedge pclk);
      presetn = 1'b1;
      repeat (2) @(posedge pclk);
    end
  endtask

  task settle;
    input integer cycles;
    begin repeat (cycles) @(posedge pclk); end
  endtask

  task check_status;
    begin
      settle(`SETTLE_CYCLES);
      seq.rd(`UREG_STATUS);
      chk.compare_status(seq.m.last_rdata, fmodel.exp_status({31'd0, tx_busy}));
    end
  endtask

  task check_irq_now;
    begin
      chk.check_irq(irq, (fmodel.exp_irq(0) != 32'd0));
    end
  endtask

  task finish_test;
    input [255:0] name;
    begin
      settle(`SETTLE_CYCLES);
      $display("");
      $display("apb monitor : reads=%0d writes=%0d errors=%0d", n_reads, n_writes, n_errors);
      $display("serial monitor : %0d frames observed on tx", n_bytes_seen);
      fmodel.report;
      cov.report(name);
      chk.report(name);
      $finish;
    end
  endtask

  task require_coverage;
    input integer pct;
    begin
      if (cov.coverage_pct(0) < pct) begin
        $display("[%0t] ERROR coverage %0d%% below the required floor %0d%%", $time, cov.coverage_pct(0), pct);
        $display("RESULT: FAILED");
        $finish;
      end
    end
  endtask

endmodule
