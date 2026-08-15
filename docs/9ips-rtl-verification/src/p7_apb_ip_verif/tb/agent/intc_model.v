`timescale 1ns/1ps
`include "tb_defs.vh"

module intc_model #(
  parameter N = `APB_INTC_N,
  parameter W = `APB_INTC_W
)(
  input  wire         clk,
  input  wire         rst_n,
  input  wire [N-1:0] irq_i,
  input  wire         iack_i,
  input  wire         mask_we_i,
  input  wire [N-1:0] mask_data_i,
  input  wire         eoi_we_i,
  output reg  [N-1:0] m_mask_o,
  output reg  [N-1:0] m_pend_o,
  output reg  [N-1:0] m_isr_o,
  output reg          m_irq_o,
  output reg  [W-1:0] m_irq_id_o
);
  reg [N-1:0] s0, s1, s1d;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s0 <= {N{1'b0}}; s1 <= {N{1'b0}}; s1d <= {N{1'b0}};
    end else begin
      s0 <= irq_i; s1 <= s0; s1d <= s1;
    end
  end

  wire [N-1:0] rise = s1 & ~s1d;
  integer k, j;

  reg [W-1:0] top_isr;
  reg         isr_busy;
  reg [W-1:0] cand;
  reg         cand_ok;
  reg         offer;

  always @* begin
    top_isr  = {W{1'b0}};
    isr_busy = 1'b0;
    for (k = N-1; k >= 0; k = k - 1)
      if (m_isr_o[k] && !isr_busy) begin
        top_isr  = k;
        isr_busy = 1'b1;
      end

    cand    = {W{1'b0}};
    cand_ok = 1'b0;
    for (k = N-1; k >= 0; k = k - 1)
      if (m_pend_o[k] && m_mask_o[k] && !cand_ok) begin
        cand    = k;
        cand_ok = 1'b1;
      end

    if      (!cand_ok)  offer = 1'b0;
    else if (!isr_busy) offer = 1'b1;
    else                offer = (cand > top_isr);
  end

  wire take    = iack_i && m_irq_o;
  wire eoi_eff = eoi_we_i && isr_busy;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_mask_o   <= {N{1'b0}};
      m_pend_o   <= {N{1'b0}};
      m_isr_o    <= {N{1'b0}};
      m_irq_o    <= 1'b0;
      m_irq_id_o <= {W{1'b0}};
    end else begin
      if (mask_we_i) m_mask_o <= mask_data_i;
      for (j = 0; j < N; j = j + 1) begin
        if (take && (m_irq_id_o == j)) m_pend_o[j] <= 1'b0;
        if (rise[j])                   m_pend_o[j] <= 1'b1;
      end

      if (eoi_eff) m_isr_o[top_isr]    <= 1'b0;
      if (take)    m_isr_o[m_irq_id_o] <= 1'b1;

      m_irq_o    <= offer;
      m_irq_id_o <= cand;
    end
  end

endmodule
