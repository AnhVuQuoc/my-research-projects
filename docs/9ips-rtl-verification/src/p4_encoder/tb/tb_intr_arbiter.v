`timescale 1ns/1ps
`include "tb_utils.vh"

module tb_intr_arbiter;

  `TB_DECLARE
  `TB_DUMP(tb_intr_arbiter, "tb_intr_arbiter.vcd")

  localparam N = 8;

  reg  [N-1:0] irq;
  reg  [N-1:0] mask;
  reg          active;
  reg  [2:0]   active_id;

  wire [N-1:0] pend;
  wire [2:0]   irq_id;
  wire         irq_vld;
  wire         any_pend;

  intr_arbiter #(.N(N)) dut (
    .irq_i       (irq),
    .mask_i      (mask),
    .active_i    (active),
    .active_id_i (active_id),
    .pend_o      (pend),
    .irq_id_o    (irq_id),
    .irq_vld_o   (irq_vld),
    .any_pend_o  (any_pend)
  );

  reg [N-1:0] m_pend;
  reg [2:0]   m_id;
  reg         m_vld;
  reg         m_cand_vld;

  task ref_arbiter;
    input [N-1:0] irq_v;
    input [N-1:0] mask_v;
    input         act;
    input [2:0]   act_id;
    integer k;
    begin
      m_pend     = irq_v & mask_v;
      m_id       = 3'd0;
      m_cand_vld = 1'b0;
      for (k = N-1; k >= 0; k = k - 1)
        if (m_pend[k] && !m_cand_vld) begin
          m_id       = k;
          m_cand_vld = 1'b1;
        end
      if (!m_cand_vld)      m_vld = 1'b0;
      else if (!act)        m_vld = 1'b1;
      else                  m_vld = (m_id > act_id);
    end
  endtask

  task check_props;
    reg [3:0] idw;
    begin
      `CHECK_EQ("Q1.pend", pend, (irq & mask))
      `CHECK_EQ("Q2.any_pend", any_pend, (|(irq & mask)))
      if (irq_vld) begin
        `CHECK_TRUE("Q3.winner_pending", pend[irq_id] === 1'b1)
        idw = {1'b0, irq_id} + 4'd1;
        `CHECK_TRUE("Q4.no_higher_pending", (pend >> idw) == {N{1'b0}})
        `CHECK_TRUE("Q5.preempt_strict", (!active) || (irq_id > active_id))
      end
      if (!any_pend)
        `CHECK_EQ("Q6.no_pend_no_irq", irq_vld, 1'b0)
    end
  endtask

  task check_vs_ref;
    begin
      ref_arbiter(irq, mask, active, active_id);
      `CHECK_EQ("ref.pend", pend,    m_pend)
      `CHECK_EQ("ref.vld",  irq_vld, m_vld)
      if (m_cand_vld)
        `CHECK_EQ("ref.id", irq_id, m_id)
    end
  endtask

  task apply;
    input [N-1:0] irq_v;
    input [N-1:0] mask_v;
    input         act;
    input [2:0]   act_id;
    begin
      irq       = irq_v;
      mask      = mask_v;
      active    = act;
      active_id = act_id;
      #1;
      check_vs_ref;
      check_props;
    end
  endtask

  integer i, j, n_iter, seed;
  reg [N-1:0] mv, iv;
  reg [2:0]   i3, j3;
  reg [31:0]  rnd;

  initial begin
    `TB_BANNER("tb_intr_arbiter")
    seed = 32'h1234_ABCD;
    irq = 0; mask = 0; active = 0; active_id = 0;

    `INFO("TP1 : nothing requesting -> no interrupt")
    apply(8'h00, 8'hFF, 1'b0, 3'd0);
    `CHECK_EQ("TP1.vld",  irq_vld,  1'b0)
    `CHECK_EQ("TP1.pend", pend,     8'h00)
    `CHECK_EQ("TP1.any",  any_pend, 1'b0)

    `INFO("TP2 : each source alone and enabled -> that source wins")
    for (i = 0; i < N; i = i + 1) begin
      i3 = i;
      apply((8'd1 << i), 8'hFF, 1'b0, 3'd0);
      `CHECK_EQ("TP2.id",  irq_id,  i3)
      `CHECK_EQ("TP2.vld", irq_vld, 1'b1)
    end

    `INFO("TP3 : each source alone but masked -> silence")
    for (i = 0; i < N; i = i + 1) begin
      apply((8'd1 << i), ~(8'd1 << i), 1'b0, 3'd0);
      `CHECK_EQ("TP3.vld",  irq_vld,  1'b0)
      `CHECK_EQ("TP3.pend", pend,     8'h00)
    end

    `INFO("TP4 : all requesting, mask swept -> highest ENABLED source wins")
    for (i = 0; i < N; i = i + 1) begin
      i3 = i;
      mv = (8'hFF >> (7 - i));
      apply(8'hFF, mv, 1'b0, 3'd0);
      `CHECK_EQ("TP4.winner", irq_id,  i3)
      `CHECK_EQ("TP4.vld",    irq_vld, 1'b1)
    end
    for (i = 0; i < 256; i = i + 1) begin
      iv = i;
      for (j = 0; j < 256; j = j + 1) begin
        mv = j;
        apply(iv, mv, 1'b0, 3'd0);
      end
    end

    `INFO("TP5 : preemption boundary - <, and > for every pair")
    for (i = 0; i < N; i = i + 1) begin 
      for (j = 0; j < N; j = j + 1) begin
        i3 = i;  j3 = j;
        apply((8'd1 << i), 8'hFF, 1'b1, j3);
        if (i > j) begin
          `CHECK_EQ("TP5.higher_preempts", irq_vld, 1'b1)
          `CHECK_EQ("TP5.higher_id",       irq_id,  i3)
        end else begin
          `CHECK_EQ("TP5.equal_or_lower_blocked", irq_vld, 1'b0)
        end
        `CHECK_EQ("TP5.pend_still_visible", pend, (8'd1 << i))
        `CHECK_EQ("TP5.any_pend_visible",   any_pend, 1'b1)
      end
    end
    apply(8'b0000_1000, 8'hFF, 1'b1, 3'd3);
    `CHECK_EQ("TP5.self_preempt_blocked", irq_vld, 1'b0)
    $display("source 3 pending while ISR 3 is running -> irq_vld = %0b", irq_vld);
    $display("(a '>=' here would restart the ISR forever: live-lock)");

    `INFO("TP6 : masked sources must have NO influence on the winner")
    begin : influence
      reg [2:0]   base_id;
      reg         base_vld;
      reg [N-1:0] base_pend;
      integer     b;

      for (i = 0; i < 64; i = i + 1) begin
        rnd  = $random(seed);
        iv   = rnd[7:0];
        mv   = rnd[15:8];
        apply(iv, mv, 1'b0, 3'd0);
        base_id   = irq_id;
        base_vld  = irq_vld;
        base_pend = pend;
        for (b = 0; b < N; b = b + 1) begin
          if (!mv[b]) begin
            apply(iv ^ (8'd1 << b), mv, 1'b0, 3'd0);
            `CHECK_EQ("TP6.vld_unchanged",  irq_vld, base_vld)
            `CHECK_EQ("TP6.pend_unchanged", pend,    base_pend)
            if (base_vld)
              `CHECK_EQ("TP6.id_unchanged", irq_id, base_id)
          end
        end
      end
    end

    `INFO("TP7 : pend_o is exactly irq & mask (status register contract)")
    apply(8'b1010_1010, 8'b1100_1100, 1'b0, 3'd0);
    `CHECK_EQ("TP7.pend", pend, 8'b1000_1000)

    `INFO("TP8 : constrained random, 20000 vectors")
    for (n_iter = 0; n_iter < 20000; n_iter = n_iter + 1) begin
      rnd = $random(seed);
      iv  = rnd[7:0];
      mv  = rnd[15:8];
      irq = iv; mask = mv; #1;
      if (rnd[16] && any_pend)
        j3 = irq_id;
      else
        j3 = rnd[19:17];
      apply(iv, mv, rnd[20], j3);
    end

    `TB_SUMMARY("tb_intr_arbiter")
    $finish;
  end

endmodule
