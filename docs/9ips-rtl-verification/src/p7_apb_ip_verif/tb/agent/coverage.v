`timescale 1ns/1ps
`include "tb_defs.vh"

module coverage #(
  parameter N  = `APB_INTC_N,
  parameter W  = `APB_INTC_W,
  parameter AW = `APB_AW,
  parameter DW = `APB_DW
)(
  input  wire          pclk,
  input  wire          presetn,
  input  wire          tr_vld_i,
  input  wire          tr_write_i,
  input  wire [AW-1:0] tr_addr_i,
  input  wire [DW-1:0] tr_wdata_i,
  input  wire          tr_err_i,
  input  wire [7:0]    tr_waits_i,
  input  wire          psel_i,
  input  wire [N-1:0]  irq_i,
  input  wire          iack_i,
  input  wire          irq_o_i,
  input  wire [N-1:0]  m_isr_i,
  input  wire          pred_busy_i
);

  localparam NBINS = 26;

  integer cov [0:NBINS-1];
  integer i;

  localparam B_RD0        = 0;
  localparam B_WR0        = 7;
  localparam B_ERR_UNMAP  = 14;
  localparam B_ERR_WRRO   = 15;
  localparam B_ERR_BADCMD = 16;
  localparam B_ERR_BUSY   = 17;
  localparam B_WAITSTATE  = 18;
  localparam B_B2B        = 19;
  localparam B_CMD_DRAIN  = 20;
  localparam B_CMD_DIS    = 21;
  localparam B_CMD_EN     = 22;
  localparam B_IRQ_IN_XFER= 23;
  localparam B_RD_WHILE_IRQ = 24;
  localparam B_NEST2      = 25;

  reg [N-1:0] irq_d;
  reg         tr_vld_d;
  integer     ones;

  function integer reg_index;
    input [AW-1:0] a;
    begin
      case (a)
        `REG_MASK:   reg_index = 0;
        `REG_PEND:   reg_index = 1;
        `REG_ISR:    reg_index = 2;
        `REG_EOI:    reg_index = 3;
        `REG_STATUS: reg_index = 4;
        `REG_CMD:    reg_index = 5;
        `REG_ID:     reg_index = 6;
        default:     reg_index = -1;
      endcase
    end
  endfunction

  integer idx;

  initial begin
    for (i = 0; i < NBINS; i = i + 1) cov[i] = 0;
  end

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      irq_d    <= {N{1'b0}};
      tr_vld_d <= 1'b0;
    end else begin
      irq_d    <= irq_i;
      tr_vld_d <= tr_vld_i;

      if (tr_vld_i) begin
        idx = reg_index(tr_addr_i);
        if (idx >= 0) begin
          if (tr_write_i) cov[B_WR0 + idx] = cov[B_WR0 + idx] + 1;
          else            cov[B_RD0 + idx] = cov[B_RD0 + idx] + 1;
        end
        if (tr_err_i && (idx < 0))
          cov[B_ERR_UNMAP] = cov[B_ERR_UNMAP] + 1;
        if (tr_err_i && tr_write_i && (idx == 1 || idx == 2 || idx == 4 || idx == 6))
          cov[B_ERR_WRRO] = cov[B_ERR_WRRO] + 1;
        if (tr_err_i && tr_write_i && (idx == 5))
          cov[B_ERR_BADCMD] = cov[B_ERR_BADCMD] + 1;
        if (tr_err_i && pred_busy_i)
          cov[B_ERR_BUSY] = cov[B_ERR_BUSY] + 1;

        if (tr_waits_i > 8'd0) cov[B_WAITSTATE] = cov[B_WAITSTATE] + 1;
        if (tr_vld_d) cov[B_B2B] = cov[B_B2B] + 1;
        if (tr_write_i && (idx == 5) && !tr_err_i) begin
          if (tr_wdata_i == `CMD_DRAIN)       cov[B_CMD_DRAIN] = cov[B_CMD_DRAIN] + 1;
          if (tr_wdata_i == `CMD_DISABLE_ALL) cov[B_CMD_DIS]   = cov[B_CMD_DIS]   + 1;
          if (tr_wdata_i == `CMD_ENABLE_ALL)  cov[B_CMD_EN]    = cov[B_CMD_EN]    + 1;
        end
        if (!tr_write_i && irq_o_i) cov[B_RD_WHILE_IRQ] = cov[B_RD_WHILE_IRQ] + 1;
      end
      if (psel_i && (|(irq_i & ~irq_d)))
        cov[B_IRQ_IN_XFER] = cov[B_IRQ_IN_XFER] + 1;
      ones = 0;
      for (i = 0; i < N; i = i + 1)
        if (m_isr_i[i]) ones = ones + 1;
      if (ones >= 2) cov[B_NEST2] = cov[B_NEST2] + 1;
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
    begin coverage_pct = (hits(0) * 100) / NBINS; end
  endfunction

  task show;
    input [255:0] nm;
    input integer idx2;
    begin
      if (cov[idx2] > 0) $display("[HIT ] %-22s %0d", nm, cov[idx2]);
      else               $display("[MISS] %-22s", nm);
    end
  endtask

  task report;
    input [255:0] name;
    integer k;
    begin
      $display("FUNCTIONAL COVERAGE : %0s", name);
      $display("- register reads -");
      for (k = 0; k < 7; k = k + 1)
        if (cov[B_RD0 + k] > 0) $display("[HIT ] read  reg %0d      %0d", k, cov[B_RD0 + k]);
        else                    $display("[MISS] read  reg %0d", k);
      $display("- register writes -");
      for (k = 0; k < 7; k = k + 1)
        if (cov[B_WR0 + k] > 0) $display("[HIT ] write reg %0d      %0d", k, cov[B_WR0 + k]);
        else                    $display("[MISS] write reg %0d", k);
      $display("- error responses -");
      show("err_unmapped",   B_ERR_UNMAP);
      show("err_write_ro",   B_ERR_WRRO);
      show("err_bad_command",B_ERR_BADCMD);
      show("err_while_busy", B_ERR_BUSY);
      $display("- bus shapes -");
      show("wait_states",    B_WAITSTATE);
      show("back_to_back",   B_B2B);
      $display("- commands -");
      show("cmd_drain",      B_CMD_DRAIN);
      show("cmd_disable_all",B_CMD_DIS);
      show("cmd_enable_all", B_CMD_EN);
      $display("- crossings -");
      show("irq_during_xfer",B_IRQ_IN_XFER);
      show("read_while_irq", B_RD_WHILE_IRQ);
      show("nesting_depth2", B_NEST2);
      $display("-------------");
      $display("bins hit : %0d / %0d  =  %0d %%", hits(0), NBINS, coverage_pct(0));
    end
  endtask

endmodule
