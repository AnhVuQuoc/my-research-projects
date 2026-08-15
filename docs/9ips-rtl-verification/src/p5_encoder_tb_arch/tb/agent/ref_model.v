`timescale 1ns/1ps
`include "tb_defs.vh"

module ref_model #(
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
  input  wire         iack_i,
  output reg          exp_irq_o,
  output reg  [W-1:0] exp_irq_id_o,
  output reg  [N-1:0] exp_rdata_o,
  output reg  [N-1:0] exp_mask_o,
  output reg  [N-1:0] exp_pend_o,
  output reg  [N-1:0] exp_isr_o
);

  reg [N-1:0] s0, s1, s1d;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s0 <= {N{1'b0}}; s1 <= {N{1'b0}}; s1d <= {N{1'b0}};
    end else begin
      s0 <= irq_i; s1 <= s0; s1d <= s1;
    end
  end

  integer k;
  integer j;

  reg [W-1:0] top_isr;
  reg         isr_busy;
  reg [W-1:0] cand;
  reg         cand_ok;
  reg         offer;

  always @* begin
    top_isr  = {W{1'b0}};
    isr_busy = 1'b0;
    for (k = N-1; k >= 0; k = k - 1)
      if (exp_isr_o[k] && !isr_busy) begin
        top_isr  = k;
        isr_busy = 1'b1;
      end
    cand    = {W{1'b0}};
    cand_ok = 1'b0;
    for (k = N-1; k >= 0; k = k - 1)
      if (exp_pend_o[k] && exp_mask_o[k] && !cand_ok) begin
        cand    = k;
        cand_ok = 1'b1;
      end
    if (!cand_ok)        offer = 1'b0;
    else if (!isr_busy)  offer = 1'b1;
    else                 offer = (cand > top_isr);
  end

  wire        rd_take = iack_i && exp_irq_o;
  wire        rd_eoi  = cfg_we_i && (cfg_addr_i == `ADDR_EOI) && isr_busy;
  wire [N-1:0] rise   = s1 & ~s1d;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      exp_mask_o   <= {N{1'b0}};
      exp_pend_o   <= {N{1'b0}};
      exp_isr_o    <= {N{1'b0}};
      exp_irq_o    <= 1'b0;
      exp_irq_id_o <= {W{1'b0}};
      exp_rdata_o  <= {N{1'b0}};
    end else begin
      if (cfg_we_i && (cfg_addr_i == `ADDR_MASK))
        exp_mask_o <= cfg_wdata_i;
      for (j = 0; j < N; j = j + 1) begin
        if (rd_take && (exp_irq_id_o == j))
          exp_pend_o[j] <= 1'b0;
        if (rise[j])
          exp_pend_o[j] <= 1'b1;
      end
      if (rd_eoi)
        exp_isr_o[top_isr] <= 1'b0;
      if (rd_take)
        exp_isr_o[exp_irq_id_o] <= 1'b1;
      exp_irq_o    <= offer;
      exp_irq_id_o <= cand;
      if (cfg_re_i) begin
        case (cfg_addr_i)
          `ADDR_MASK: exp_rdata_o <= exp_mask_o;
          `ADDR_PEND: exp_rdata_o <= exp_pend_o;
          `ADDR_ISR:  exp_rdata_o <= exp_isr_o;
          default:    exp_rdata_o <= {N{1'b0}};
        endcase
      end
    end
  end

endmodule
