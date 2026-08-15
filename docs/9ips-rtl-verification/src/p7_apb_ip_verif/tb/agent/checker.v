`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module checker #(
  parameter N  = `APB_INTC_N,
  parameter W  = `APB_INTC_W,
  parameter AW = `APB_AW,
  parameter DW = `APB_DW
)(
  input  wire          pclk,
  input  wire          presetn,
  input  wire          psel_i,
  input  wire          penable_i,
  input  wire          pwrite_i,
  input  wire [AW-1:0] paddr_i,
  input  wire [DW-1:0] prdata_i,
  input  wire          pready_i,
  input  wire          pslverr_i,
  input  wire          exp_err_i,
  input  wire [DW-1:0] exp_rdata_i,
  input  wire [N-1:0]  m_mask_i,
  input  wire [N-1:0]  m_pend_i,
  input  wire [N-1:0]  m_isr_i,
  input  wire [N-1:0]  irq_i,
  input  wire          iack_i,
  input  wire          irq_o_i,
  input  wire [W-1:0]  irq_id_i,
  input  wire [31:0]   n_prot_errors_i,
  input  wire [31:0]   n_prot_checks_i
);

  `TB_DECLARE

  integer n_sb_rd, n_sb_err, n_a1, n_a2, n_a5, n_state_cmp;
  integer enable_sb;

  initial begin
    n_sb_rd = 0; n_sb_err = 0;
    n_a1 = 0; n_a2 = 0; n_a5 = 0; n_state_cmp = 0;
    enable_sb = 1;
  end

  wire complete = psel_i && penable_i && pready_i;
  always @(posedge pclk) begin
    if (presetn && enable_sb && complete) begin
      `CHECK_EQ("SB_pslverr", pslverr_i, exp_err_i)
      n_sb_err = n_sb_err + 1;
      if (!pwrite_i && !exp_err_i) begin
        `CHECK_EQ("SB_prdata", prdata_i, exp_rdata_i)
        n_sb_rd = n_sb_rd + 1;
      end
    end
  end
  reg         ack_d;
  reg [W-1:0] ack_id_d;
  reg [N-1:0] ever_arrived, irq_d;
  reg [N-1:0] shadow_mask;

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      ack_d        <= 1'b0;
      ack_id_d     <= {W{1'b0}};
      ever_arrived <= {N{1'b0}};
      irq_d        <= {N{1'b0}};
      shadow_mask  <= {N{1'b0}};
    end else begin
      ack_d        <= iack_i && irq_o_i;
      ack_id_d     <= irq_id_i;
      irq_d        <= irq_i;
      ever_arrived <= ever_arrived | (irq_i & ~irq_d);
      shadow_mask  <= m_mask_i;
    end
  end

  always @(posedge pclk) begin
    if (presetn) begin
      if (ack_d) begin
        n_a1 = n_a1 + 1;
        `CHECK_TRUE("A1_no_self_preempt", !(irq_o_i && (irq_id_i === ack_id_d)))
      end
      if (irq_o_i) begin
        n_a2 = n_a2 + 1;
        `CHECK_TRUE("A2_offer_is_enabled", shadow_mask[irq_id_i] === 1'b1)
      end
      if (irq_o_i) begin
        n_a5 = n_a5 + 1;
        `CHECK_TRUE("A5_offer_was_requested", ever_arrived[irq_id_i] === 1'b1)
      end
    end
  end
  task compare_state;
    input [DW-1:0] rd_mask;
    input [DW-1:0] rd_pend;
    input [DW-1:0] rd_isr;
    begin
      n_state_cmp = n_state_cmp + 1;
      `CHECK_EQ("STATE_mask", rd_mask[N-1:0], m_mask_i)
      `CHECK_EQ("STATE_pend", rd_pend[N-1:0], m_pend_i)
      `CHECK_EQ("STATE_isr",  rd_isr[N-1:0],  m_isr_i)
    end
  endtask

  task expect_eq;
    input [255:0] nm;
    input [31:0]  act;
    input [31:0]  exp;
    begin `CHECK_EQ(nm, act, exp) end
  endtask

  task expect_true;
    input [255:0] nm;
    input         cond;
    begin `CHECK_TRUE(nm, cond) end
  endtask

  task note;
    input [255:0] msg;
    begin $display("[%0t] INFO  %0s", $time, msg); end
  endtask

  task set_scoreboard;
    input integer e;
    begin enable_sb = e; end
  endtask

  task set_verbose;
    input integer v;
    begin tb_verbose = v; end
  endtask

  task require_evaluations;
    input integer min_rd;
    input integer min_a2;
    begin
      `CHECK_TRUE("read scoreboard was exercised", n_sb_rd >= min_rd)
      `CHECK_TRUE("A2 was exercised",              n_a2   >= min_a2)
    end
  endtask

  task report;
    input [255:0] name;
    begin
      $display("CHECKER REPORT : %0s", name);
      $display("scoreboard  PSLVERR      : %0d comparisons", n_sb_err);
      $display("scoreboard  PRDATA       : %0d comparisons", n_sb_rd);
      $display("state       comparisons  : %0d", n_state_cmp);
      $display("assertion   A1 no-self-preempt : %0d", n_a1);
      $display("assertion   A2 offer-enabled   : %0d", n_a2);
      $display("assertion   A5 offer-requested : %0d", n_a5);
      $display("APB protocol : %0d cycles checked, %0d violations", n_prot_checks_i, n_prot_errors_i);
      tb_checks = tb_checks + n_prot_checks_i;
      tb_errors = tb_errors + n_prot_errors_i;
      `TB_SUMMARY(name)
    end
  endtask

endmodule
