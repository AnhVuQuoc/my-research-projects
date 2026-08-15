`timescale 1ns/1ps
`include "tb_defs.vh"

module coverage #(
  parameter N = `INTC_N,
  parameter W = `INTC_W
)(
  input  wire         clk,
  input  wire         rst_n,
  input  wire [N-1:0] irq_i,
  input  wire         cfg_we_i,
  input  wire [1:0]   cfg_addr_i,
  input  wire         iack_i,
  input  wire         irq_o_i,
  input  wire [W-1:0] irq_id_i,
  input  wire         mon_ack_vld_i,
  input  wire [W-1:0] mon_ack_id_i,
  input  wire         mon_eoi_vld_i,
  input  wire [N-1:0] mon_arrive_i
);

  localparam NBINS = 21;

  integer cov [0:NBINS-1];
  integer i;

  localparam B_SRC0    = 0;
  localparam B_DEPTH0  = 8;
  localparam B_EOI_EMPTY   = 12;
  localparam B_ACK_NOOFF   = 13;
  localparam B_ARR_ACK     = 14;
  localparam B_MASK_PEND   = 15;
  localparam B_OFF_SUBST   = 16;
  localparam B_STORM       = 17;
  localparam B_B2B_ACK     = 18;
  localparam B_EOI_AFT_ACK = 19;
  localparam B_PREEMPT     = 20;

  integer depth;
  reg     ack_d;
  reg [W-1:0] irq_id_d;
  reg         irq_o_d;

  integer ones;

  initial begin
    for (i = 0; i < NBINS; i = i + 1) cov[i] = 0;
    depth = 0;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ack_d    <= 1'b0;
      irq_id_d <= {W{1'b0}};
      irq_o_d  <= 1'b0;
      depth     = 0;
    end else begin
      ack_d    <= mon_ack_vld_i;
      irq_id_d <= irq_id_i;
      irq_o_d  <= irq_o_i;

      if (mon_ack_vld_i) begin
        cov[B_SRC0 + mon_ack_id_i] = cov[B_SRC0 + mon_ack_id_i] + 1;
        if (depth > 0) cov[B_PREEMPT] = cov[B_PREEMPT] + 1;
        depth = depth + 1;
      end

      if (mon_eoi_vld_i) begin
        if (depth == 0) cov[B_EOI_EMPTY] = cov[B_EOI_EMPTY] + 1;
        else            depth = depth - 1;
        if (ack_d)      cov[B_EOI_AFT_ACK] = cov[B_EOI_AFT_ACK] + 1;
      end

      if (depth >= 3) cov[B_DEPTH0 + 3] = cov[B_DEPTH0 + 3] + 1;
      else            cov[B_DEPTH0 + depth] = cov[B_DEPTH0 + depth] + 1;

      if (iack_i && !irq_o_i)
        cov[B_ACK_NOOFF] = cov[B_ACK_NOOFF] + 1;

      if (mon_ack_vld_i && (|mon_arrive_i))
        cov[B_ARR_ACK] = cov[B_ARR_ACK] + 1;

      if (cfg_we_i && (cfg_addr_i == `ADDR_MASK) && irq_o_i)
        cov[B_MASK_PEND] = cov[B_MASK_PEND] + 1;

      if (irq_o_i && irq_o_d && (irq_id_i !== irq_id_d))
        cov[B_OFF_SUBST] = cov[B_OFF_SUBST] + 1;

      if (mon_ack_vld_i && ack_d)
        cov[B_B2B_ACK] = cov[B_B2B_ACK] + 1;

      ones = 0;
      for (i = 0; i < N; i = i + 1)
        if (mon_arrive_i[i]) ones = ones + 1;
      if (ones >= 4) cov[B_STORM] = cov[B_STORM] + 1;
    end
  end

  function integer hits;
    input integer dummy;
    integer k;
    begin
      hits = 0;
      for (k = 0; k < NBINS; k = k + 1)
        if (cov[k] > 0) hits = hits + 1;
    end
  endfunction

  function integer coverage_pct;
    input integer dummy;
    begin
      coverage_pct = (hits(0) * 100) / NBINS;
    end
  endfunction

  task show_bin;
    input [255:0] nm;
    input integer idx;
    begin
      if (cov[idx] > 0)
        $display("[HIT ] %-24s %0d", nm, cov[idx]);
      else
        $display("[MISS] %-24s", nm);
    end
  endtask

  task report;
    input [255:0] name;
    integer k;
    begin
      $display("FUNCTIONAL COVERAGE : %0s", name);
      $display("-source acknowledged-");
      for (k = 0; k < N; k = k + 1) begin
        if (cov[B_SRC0 + k] > 0)
          $display("[HIT ] source %0d          %0d", k, cov[B_SRC0 + k]);
        else
          $display("[MISS] source %0d", k);
      end
      $display("-nesting depth-");
      show_bin("depth 0",  B_DEPTH0 + 0);
      show_bin("depth 1",  B_DEPTH0 + 1);
      show_bin("depth 2",  B_DEPTH0 + 2);
      show_bin("depth 3+", B_DEPTH0 + 3);
      $display("-situations-");
      show_bin("eoi_on_empty",      B_EOI_EMPTY);
      show_bin("ack_no_offer",      B_ACK_NOOFF);
      show_bin("arrive_during_ack", B_ARR_ACK);
      show_bin("mask_write_pending",B_MASK_PEND);
      show_bin("offer_substituted", B_OFF_SUBST);
      show_bin("storm_4plus",       B_STORM);
      show_bin("back_to_back_ack",  B_B2B_ACK);
      show_bin("eoi_after_ack",     B_EOI_AFT_ACK);
      show_bin("preemption",        B_PREEMPT);
      $display("--------");
      $display("bins hit : %0d / %0d   =  %0d %%",
               hits(0), NBINS, coverage_pct(0));
    end
  endtask

endmodule
