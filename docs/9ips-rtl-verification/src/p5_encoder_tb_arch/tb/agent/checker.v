`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module checker #(
  parameter N = `INTC_N,
  parameter W = `INTC_W
)(
  input  wire         clk,
  input  wire         rst_n,
  input  wire [N-1:0] irq_i,
  input  wire         cfg_we_i,
  input  wire         cfg_re_i,
  input  wire [1:0]   cfg_addr_i,
  input  wire [N-1:0] cfg_wdata_i,
  input  wire [N-1:0] cfg_rdata_i,
  input  wire         iack_i,
  input  wire         irq_o_i,
  input  wire [W-1:0] irq_id_i,
  input  wire         exp_irq_i,
  input  wire [W-1:0] exp_irq_id_i,
  input  wire [N-1:0] exp_rdata_i,
  input  wire         mon_ack_vld_i,
  input  wire [W-1:0] mon_ack_id_i
);

  `TB_DECLARE

  integer n_sb_irq, n_sb_id, n_sb_rd;
  integer n_a1, n_a2, n_a3, n_a4, n_a5;
  integer enable_sb;

  initial begin
    n_sb_irq = 0; n_sb_id = 0; n_sb_rd = 0;
    n_a1 = 0; n_a2 = 0; n_a3 = 0; n_a4 = 0; n_a5 = 0;
    enable_sb = 1;
  end

  reg [N-1:0] shadow_mask;
  reg [N-1:0] ever_arrived;
  reg [N-1:0] irq_d;

  reg         ack_d;
  reg [W-1:0] ack_id_d;
  reg         irq_o_d;
  reg [W-1:0] irq_id_d;
  reg         iack_d;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shadow_mask  <= {N{1'b0}};
      ever_arrived <= {N{1'b0}};
      irq_d        <= {N{1'b0}};
      ack_d        <= 1'b0;
      ack_id_d     <= {W{1'b0}};
      irq_o_d      <= 1'b0;
      irq_id_d     <= {W{1'b0}};
      iack_d       <= 1'b0;
    end else begin
      if (cfg_we_i && (cfg_addr_i == `ADDR_MASK))
        shadow_mask <= cfg_wdata_i;
      ever_arrived <= ever_arrived | (irq_i & ~irq_d);
      irq_d        <= irq_i;
      ack_d        <= mon_ack_vld_i;
      ack_id_d     <= mon_ack_id_i;
      irq_o_d      <= irq_o_i;
      irq_id_d     <= irq_id_i;
      iack_d       <= iack_i;
    end
  end

  always @(posedge clk) begin
    if (rst_n && enable_sb) begin

      `CHECK_EQ("SB_irq", irq_o_i, exp_irq_i)
      n_sb_irq = n_sb_irq + 1;

      if (exp_irq_i) begin
        `CHECK_EQ("SB_irq_id", irq_id_i, exp_irq_id_i)
        n_sb_id = n_sb_id + 1;
      end

      `CHECK_EQ("SB_rdata", cfg_rdata_i, exp_rdata_i)
      n_sb_rd = n_sb_rd + 1;
    end
  end

  always @(posedge clk) begin
    if (rst_n) begin

      if (ack_d) begin
        n_a1 = n_a1 + 1;
        `CHECK_TRUE("A1_no_self_preempt", !(irq_o_i && (irq_id_i === ack_id_d)))
      end

      if (irq_o_i) begin
        n_a2 = n_a2 + 1;
        `CHECK_TRUE("A2_offer_is_enabled", shadow_mask[irq_id_i] === 1'b1)
      end

      if (irq_o_d && irq_o_i && !ack_d && !iack_d) begin
        n_a4 = n_a4 + 1;
        `CHECK_TRUE("A4_offer_monotonic", (irq_id_i >= irq_id_d))
      end

      if (irq_o_i) begin
        n_a5 = n_a5 + 1;
        `CHECK_TRUE("A5_offer_was_requested", ever_arrived[irq_id_i] === 1'b1)
      end
    end
  end

  always @(negedge rst_n) begin
    #1;
    n_a3 = n_a3 + 1;
    `CHECK_TRUE("A3_reset_clears_irq", irq_o_i === 1'b0)
    `CHECK_EQ  ("A3_reset_clears_rdata", cfg_rdata_i, {N{1'b0}})
  end

  task expect_eq;
    input [255:0] nm;
    input [31:0]  act;
    input [31:0]  exp;
    begin
      `CHECK_EQ(nm, act, exp)
    end
  endtask

  task expect_true;
    input [255:0] nm;
    input         cond;
    begin
      `CHECK_TRUE(nm, cond)
    end
  endtask

  task note;
    input [255:0] msg;
    begin
      $display("[%0t] INFO  %0s", $time, msg);
    end
  endtask

  task set_verbose;
    input integer v;
    begin tb_verbose = v; end
  endtask

  task set_scoreboard;
    input integer e;
    begin enable_sb = e; end
  endtask

  task report;
    input [255:0] name;
    begin
      $display("CHECKER REPORT : %0s", name);
      $display("scoreboard irq        : %0d comparisons", n_sb_irq);
      $display("coreboard  irq_id     : %0d comparisons", n_sb_id);
      $display("scoreboard rdata      : %0d comparisons", n_sb_rd);
      $display("assertion  A1 no-self-preempt : %0d evaluations", n_a1);
      $display("assertion  A2 offer-enabled   : %0d evaluations", n_a2);
      $display("assertion  A3 reset-clean     : %0d evaluations", n_a3);
      $display("assertion  A4 offer-monotonic : %0d evaluations", n_a4);
      $display("assertion  A5 offer-requested : %0d evaluations", n_a5);
      `TB_SUMMARY(name)
    end
  endtask

  task require_evaluations;
    input integer min_a1;
    input integer min_a2;
    begin
      `CHECK_TRUE("A1 was exercised", n_a1 >= min_a1)
      `CHECK_TRUE("A2 was exercised", n_a2 >= min_a2)
    end
  endtask

endmodule
