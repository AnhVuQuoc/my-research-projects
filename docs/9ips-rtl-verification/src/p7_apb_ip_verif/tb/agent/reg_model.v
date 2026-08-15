`timescale 1ns/1ps
`include "tb_defs.vh"

module reg_model #(
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
  input  wire [DW-1:0] pwdata_i,
  input  wire          pready_i,
  input  wire [N-1:0]  m_mask_i,
  input  wire [N-1:0]  m_pend_i,
  input  wire [N-1:0]  m_isr_i,
  input  wire          m_irq_i,
  input  wire [W-1:0]  m_irq_id_i,
  output wire          mask_we_o,
  output wire [N-1:0]  mask_data_o,
  output wire          eoi_we_o,
  output wire          exp_err_o,
  output wire [DW-1:0] exp_rdata_o,
  output wire          pred_busy_o
);
  wire hit_mask   = (paddr_i == `REG_MASK);
  wire hit_pend   = (paddr_i == `REG_PEND);
  wire hit_isr    = (paddr_i == `REG_ISR);
  wire hit_eoi    = (paddr_i == `REG_EOI);
  wire hit_status = (paddr_i == `REG_STATUS);
  wire hit_cmd    = (paddr_i == `REG_CMD);
  wire hit_id     = (paddr_i == `REG_ID);
  wire mapped     = hit_mask | hit_pend | hit_isr | hit_eoi | hit_status | hit_cmd | hit_id;
  wire read_only  = hit_pend | hit_isr | hit_status | hit_id;
  wire code_ok    = (pwdata_i == `CMD_DRAIN) || (pwdata_i == `CMD_DISABLE_ALL) || (pwdata_i == `CMD_ENABLE_ALL);

  reg  [7:0] cmd_cnt;
  reg  [1:0] cmd_kind;

  wire complete  = psel_i && penable_i && pready_i;
  wire wr_commit = complete && pwrite_i && !exp_err_o;
  wire cmd_start = wr_commit && hit_cmd && code_ok;

  localparam [7:0] DRAIN_LEN = N + 1;
  localparam [7:0] N8        = N;

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      cmd_cnt  <= 8'd0;
      cmd_kind <= 2'd0;
    end else if (cmd_start) begin
      cmd_cnt  <= (pwdata_i == `CMD_DRAIN) ? DRAIN_LEN : 8'd2;
      cmd_kind <= (pwdata_i == `CMD_DRAIN) ? 2'd1 :
                  (pwdata_i == `CMD_DISABLE_ALL) ? 2'd2 : 2'd3;
    end else if (cmd_cnt != 8'd0) begin
      cmd_cnt <= cmd_cnt - 8'd1;
    end
  end

  assign pred_busy_o = (cmd_cnt != 8'd0);

  wire cmd_apply_short = (cmd_cnt == 8'd1) && (cmd_kind != 2'd1);
  wire cmd_apply_drain = (cmd_kind == 2'd1) && (cmd_cnt <= N8) && (cmd_cnt != 8'd0);

  assign exp_err_o = (!mapped) || (pwrite_i && read_only) || (pwrite_i && hit_cmd && !code_ok) || pred_busy_o;

  wire bus_mask_we = wr_commit && hit_mask;
  wire bus_eoi_we  = wr_commit && hit_eoi;

  assign mask_we_o   = bus_mask_we || cmd_apply_short;
  assign mask_data_o = cmd_apply_short ? ((cmd_kind == 2'd3) ? {N{1'b1}} : {N{1'b0}}) : pwdata_i[N-1:0];
  assign eoi_we_o    = bus_eoi_we || cmd_apply_drain;

  reg [N-1:0] mask_d, pend_d, isr_d;

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      mask_d <= {N{1'b0}};
      pend_d <= {N{1'b0}};
      isr_d  <= {N{1'b0}};
    end else begin
      mask_d <= m_mask_i;
      pend_d <= m_pend_i;
      isr_d  <= m_isr_i;
    end
  end

  wire [DW-1:0] status_word = { {(DW-5){1'b0}}, pred_busy_o, m_irq_id_i, m_irq_i };

  assign exp_rdata_o = hit_mask   ? { {(DW-N){1'b0}}, mask_d } :
                       hit_pend   ? { {(DW-N){1'b0}}, pend_d } :
                       hit_isr    ? { {(DW-N){1'b0}}, isr_d  } :
                       hit_status ? status_word                :
                       hit_id     ? `INTC_ID                   :
                                    {DW{1'b0}};

endmodule
