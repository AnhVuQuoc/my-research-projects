`timescale 1ns/1ps
`include "tb_defs.vh"

module intc_monitor #(
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
  output reg          mon_offer_vld,
  output reg  [W-1:0] mon_offer_id,
  output reg          mon_ack_vld,
  output reg  [W-1:0] mon_ack_id,
  output reg          mon_eoi_vld,
  output reg          mon_eoi_effective,
  output reg          mon_cfg_vld,
  output reg          mon_cfg_we,
  output reg  [1:0]   mon_cfg_addr,
  output reg  [N-1:0] mon_cfg_wdata,
  output reg  [N-1:0] mon_cfg_rdata,
  output reg  [N-1:0] mon_arrive,
  output reg [31:0]   n_offers,
  output reg [31:0]   n_acks,
  output reg [31:0]   n_eois,
  output reg [31:0]   n_cfg
);

  reg [N-1:0] irq_d;
  reg         irq_o_d;
  reg [W-1:0] irq_id_d;
  reg         s1_vld, s1_we;
  reg [1:0]   s1_addr;
  reg [N-1:0] s1_wdata;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      irq_d             <= {N{1'b0}};
      irq_o_d           <= 1'b0;
      irq_id_d          <= {W{1'b0}};
      s1_vld            <= 1'b0;
      s1_we             <= 1'b0;
      s1_addr           <= 2'd0;
      s1_wdata          <= {N{1'b0}};
      mon_offer_vld     <= 1'b0;
      mon_offer_id      <= {W{1'b0}};
      mon_ack_vld       <= 1'b0;
      mon_ack_id        <= {W{1'b0}};
      mon_eoi_vld       <= 1'b0;
      mon_eoi_effective <= 1'b0;
      mon_cfg_vld       <= 1'b0;
      mon_cfg_we        <= 1'b0;
      mon_cfg_addr      <= 2'd0;
      mon_cfg_wdata     <= {N{1'b0}};
      mon_cfg_rdata     <= {N{1'b0}};
      mon_arrive        <= {N{1'b0}};
      n_offers          <= 32'd0;
      n_acks            <= 32'd0;
      n_eois            <= 32'd0;
      n_cfg             <= 32'd0;
    end else begin
      irq_d    <= irq_i;
      irq_o_d  <= irq_o_i;
      irq_id_d <= irq_id_i;
      mon_arrive <= irq_i & ~irq_d;
      if (irq_o_i && (!irq_o_d || (irq_id_i !== irq_id_d))) begin
        mon_offer_vld <= 1'b1;
        mon_offer_id  <= irq_id_i;
        n_offers      <= n_offers + 32'd1;
      end else begin
        mon_offer_vld <= 1'b0;
      end
      if (iack_i && irq_o_i) begin
        mon_ack_vld <= 1'b1;
        mon_ack_id  <= irq_id_i;
        n_acks      <= n_acks + 32'd1;
      end else begin
        mon_ack_vld <= 1'b0;
      end
      if (cfg_we_i && (cfg_addr_i == `ADDR_EOI)) begin
        mon_eoi_vld <= 1'b1;
        n_eois      <= n_eois + 32'd1;
      end else begin
        mon_eoi_vld <= 1'b0;
      end
      mon_eoi_effective <= cfg_we_i && (cfg_addr_i == `ADDR_EOI);
      s1_vld   <= (cfg_we_i || cfg_re_i);
      s1_we    <= cfg_we_i;
      s1_addr  <= cfg_addr_i;
      s1_wdata <= cfg_wdata_i;

      if (s1_vld) begin
        mon_cfg_vld   <= 1'b1;
        mon_cfg_we    <= s1_we;
        mon_cfg_addr  <= s1_addr;
        mon_cfg_wdata <= s1_wdata;
        mon_cfg_rdata <= cfg_rdata_i;
        n_cfg         <= n_cfg + 32'd1;
      end else begin
        mon_cfg_vld   <= 1'b0;
      end
    end
  end

endmodule
