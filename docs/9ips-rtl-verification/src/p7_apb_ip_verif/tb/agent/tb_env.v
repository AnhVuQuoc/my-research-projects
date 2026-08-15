`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_env #(
  parameter N  = `APB_INTC_N,
  parameter W  = `APB_INTC_W,
  parameter AW = `APB_AW,
  parameter DW = `APB_DW
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
  wire [N-1:0]  irq;
  wire          iack;
  wire          irq_out;
  wire [W-1:0]  irq_id;
  wire          tr_vld, tr_write, tr_err;
  wire [AW-1:0] tr_addr;
  wire [DW-1:0] tr_wdata, tr_rdata;
  wire [7:0]    tr_waits;
  wire [31:0]   n_reads, n_writes, n_errors;
  wire [N-1:0]  m_mask, m_pend, m_isr;
  wire          m_irq;
  wire [W-1:0]  m_irq_id;
  wire          mask_we, eoi_we;
  wire [N-1:0]  mask_data;
  wire          exp_err, pred_busy;
  wire [DW-1:0] exp_rdata;
  wire [31:0]   n_prot_errors, n_prot_checks;
  
  apb_intc #(.N(N), .AW(AW), .DW(DW)) dut (
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
    .irq_i     (irq),
    .iack_i    (iack),
    .irq_o     (irq_out),
    .irq_id_o  (irq_id)
  );

  apb_seq #(.N(N), .AW(AW), .DW(DW)) seq (
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
    .irq_o     (irq),
    .iack_o    (iack),
    .irq_i     (irq_out)
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

  intc_model #(.N(N), .W(W)) fmodel (
    .clk         (pclk),
    .rst_n       (presetn),
    .irq_i       (irq),
    .iack_i      (iack),
    .mask_we_i   (mask_we),
    .mask_data_i (mask_data),
    .eoi_we_i    (eoi_we),
    .m_mask_o    (m_mask),
    .m_pend_o    (m_pend),
    .m_isr_o     (m_isr),
    .m_irq_o     (m_irq),
    .m_irq_id_o  (m_irq_id)
  );

  reg_model #(.N(N), .W(W), .AW(AW), .DW(DW)) rmodel (
    .pclk        (pclk),
    .presetn     (presetn),
    .psel_i      (psel),
    .penable_i   (penable),
    .pwrite_i    (pwrite),
    .paddr_i     (paddr),
    .pwdata_i    (pwdata),
    .pready_i    (pready),
    .m_mask_i    (m_mask),
    .m_pend_i    (m_pend),
    .m_isr_i     (m_isr),
    .m_irq_i     (m_irq),
    .m_irq_id_i  (m_irq_id),
    .mask_we_o   (mask_we),
    .mask_data_o (mask_data),
    .eoi_we_o    (eoi_we),
    .exp_err_o   (exp_err),
    .exp_rdata_o (exp_rdata),
    .pred_busy_o (pred_busy)
  );

  checker #(.N(N), .W(W), .AW(AW), .DW(DW)) chk (
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
    .m_mask_i        (m_mask),
    .m_pend_i        (m_pend),
    .m_isr_i         (m_isr),
    .irq_i           (irq),
    .iack_i          (iack),
    .irq_o_i         (irq_out),
    .irq_id_i        (irq_id),
    .n_prot_errors_i (n_prot_errors),
    .n_prot_checks_i (n_prot_checks)
  );

  coverage #(.N(N), .W(W), .AW(AW), .DW(DW)) cov (
    .pclk        (pclk),
    .presetn     (presetn),
    .tr_vld_i    (tr_vld),
    .tr_write_i  (tr_write),
    .tr_addr_i   (tr_addr),
    .tr_wdata_i  (tr_wdata),
    .tr_err_i    (tr_err),
    .tr_waits_i  (tr_waits),
    .psel_i      (psel),
    .irq_i       (irq),
    .iack_i      (iack),
    .irq_o_i     (irq_out),
    .m_isr_i     (m_isr),
    .pred_busy_i (pred_busy)
  );

  `TB_WATCHDOG(pclk, `WD_CYCLES)

  task banner;
    input [255:0] name;
    begin
      $display(" TEST START : %0s", name);
    end
  endtask

  task reset_dut;
    begin
      presetn = 1'b0;
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
  task check_state;
    reg [DW-1:0] v_mask, v_pend, v_isr;
    begin
      settle(`SETTLE_CYCLES);
      seq.rd(`REG_MASK); v_mask = seq.m.last_rdata;
      seq.rd(`REG_PEND); v_pend = seq.m.last_rdata;
      seq.rd(`REG_ISR ); v_isr  = seq.m.last_rdata;
      chk.compare_state(v_mask, v_pend, v_isr);
    end
  endtask

  task finish_test;
    input [255:0] name;
    begin
      settle(`SETTLE_CYCLES);
      $display("");
      $display("monitor: reads=%0d writes=%0d error-responses=%0d", n_reads, n_writes, n_errors);
      cov.report(name);
      chk.report(name);
      $finish;
    end
  endtask

  task require_coverage;
    input integer pct;
    begin
      if (cov.coverage_pct(0) < pct) begin
        $display("[%0t] ERROR coverage %0d%% is below the required floor %0d%%",
                 $time, cov.coverage_pct(0), pct);
        $display("RESULT: FAILED");
        $finish;
      end
    end
  endtask

endmodule
