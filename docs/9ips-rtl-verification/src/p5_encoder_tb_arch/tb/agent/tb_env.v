`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_env #(
  parameter N         = `INTC_N,
  parameter W         = `INTC_W,
  parameter WD_CYCLES = `WD_CYCLES
);

  reg clk;
  reg rst_n;

  initial begin
    clk = 1'b0;
    forever #(`CLK_PERIOD/2) clk = ~clk;
  end

  wire [N-1:0] irq;
  wire         cfg_we, cfg_re;
  wire [1:0]   cfg_addr;
  wire [N-1:0] cfg_wdata;
  wire [N-1:0] cfg_rdata;
  wire         iack;
  wire         irq_out;
  wire [W-1:0] irq_id;
  wire         exp_irq;
  wire [W-1:0] exp_irq_id;
  wire [N-1:0] exp_rdata, exp_mask, exp_pend, exp_isr;
  wire         mon_offer_vld, mon_ack_vld, mon_eoi_vld, mon_eoi_eff, mon_cfg_vld;
  wire [W-1:0] mon_offer_id, mon_ack_id;
  wire         mon_cfg_we;
  wire [1:0]   mon_cfg_addr;
  wire [N-1:0] mon_cfg_wdata, mon_cfg_rdata, mon_arrive;
  wire [31:0]  n_offers, n_acks, n_eois, n_cfg;

  intc_top #(.N(N)) dut (
    .clk         (clk),
    .rst_n       (rst_n),
    .irq_i       (irq),
    .cfg_we_i    (cfg_we),
    .cfg_re_i    (cfg_re),
    .cfg_addr_i  (cfg_addr),
    .cfg_wdata_i (cfg_wdata),
    .cfg_rdata_o (cfg_rdata),
    .iack_i      (iack),
    .irq_o       (irq_out),
    .irq_id_o    (irq_id)
  );

  cpu_model #(.N(N), .W(W)) u_cpu (
    .clk         (clk),
    .rst_n       (rst_n),
    .irq_o       (irq),
    .cfg_we_o    (cfg_we),
    .cfg_re_o    (cfg_re),
    .cfg_addr_o  (cfg_addr),
    .cfg_wdata_o (cfg_wdata),
    .iack_o      (iack),
    .cfg_rdata_i (cfg_rdata),
    .irq_i       (irq_out),
    .irq_id_i    (irq_id)
  );

  intc_monitor #(.N(N), .W(W)) u_mon (
    .clk               (clk),
    .rst_n             (rst_n),
    .irq_i             (irq),
    .cfg_we_i          (cfg_we),
    .cfg_re_i          (cfg_re),
    .cfg_addr_i        (cfg_addr),
    .cfg_wdata_i       (cfg_wdata),
    .cfg_rdata_i       (cfg_rdata),
    .iack_i            (iack),
    .irq_o_i           (irq_out),
    .irq_id_i          (irq_id),
    .mon_offer_vld     (mon_offer_vld),
    .mon_offer_id      (mon_offer_id),
    .mon_ack_vld       (mon_ack_vld),
    .mon_ack_id        (mon_ack_id),
    .mon_eoi_vld       (mon_eoi_vld),
    .mon_eoi_effective (mon_eoi_eff),
    .mon_cfg_vld       (mon_cfg_vld),
    .mon_cfg_we        (mon_cfg_we),
    .mon_cfg_addr      (mon_cfg_addr),
    .mon_cfg_wdata     (mon_cfg_wdata),
    .mon_cfg_rdata     (mon_cfg_rdata),
    .mon_arrive        (mon_arrive),
    .n_offers          (n_offers),
    .n_acks            (n_acks),
    .n_eois            (n_eois),
    .n_cfg             (n_cfg)
  );

  ref_model #(.N(N), .W(W)) u_ref (
    .clk          (clk),
    .rst_n        (rst_n),
    .irq_i        (irq),
    .cfg_we_i     (cfg_we),
    .cfg_re_i     (cfg_re),
    .cfg_addr_i   (cfg_addr),
    .cfg_wdata_i  (cfg_wdata),
    .iack_i       (iack),
    .exp_irq_o    (exp_irq),
    .exp_irq_id_o (exp_irq_id),
    .exp_rdata_o  (exp_rdata),
    .exp_mask_o   (exp_mask),
    .exp_pend_o   (exp_pend),
    .exp_isr_o    (exp_isr)
  );

  checker #(.N(N), .W(W)) chk (
    .clk           (clk),
    .rst_n         (rst_n),
    .irq_i         (irq),
    .cfg_we_i      (cfg_we),
    .cfg_re_i      (cfg_re),
    .cfg_addr_i    (cfg_addr),
    .cfg_wdata_i   (cfg_wdata),
    .cfg_rdata_i   (cfg_rdata),
    .iack_i        (iack),
    .irq_o_i       (irq_out),
    .irq_id_i      (irq_id),
    .exp_irq_i     (exp_irq),
    .exp_irq_id_i  (exp_irq_id),
    .exp_rdata_i   (exp_rdata),
    .mon_ack_vld_i (mon_ack_vld),
    .mon_ack_id_i  (mon_ack_id)
  );

  coverage #(.N(N), .W(W)) cov (
    .clk           (clk),
    .rst_n         (rst_n),
    .irq_i         (irq),
    .cfg_we_i      (cfg_we),
    .cfg_addr_i    (cfg_addr),
    .iack_i        (iack),
    .irq_o_i       (irq_out),
    .irq_id_i      (irq_id),
    .mon_ack_vld_i (mon_ack_vld),
    .mon_ack_id_i  (mon_ack_id),
    .mon_eoi_vld_i (mon_eoi_vld),
    .mon_arrive_i  (mon_arrive)
  );

  `TB_WATCHDOG(clk, WD_CYCLES)

  task banner;
    input [255:0] name;
    begin
      $display("TEST START : %0s", name);
    end
  endtask

  task reset_dut;
    begin
      rst_n = 1'b0;
      repeat (4) @(posedge clk);
      @(negedge clk);
      rst_n = 1'b1;
      repeat (2) @(posedge clk);
    end
  endtask

  task settle;
    input integer cycles;
    begin
      repeat (cycles) @(posedge clk);
    end
  endtask

  task finish_test;
    input [255:0] name;
    begin
      settle(20);
      $display("");
      $display("monitor: offers=%0d acks=%0d eois=%0d cfg=%0d",
               n_offers, n_acks, n_eois, n_cfg);
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
