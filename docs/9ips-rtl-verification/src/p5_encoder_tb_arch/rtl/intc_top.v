`timescale 1ns/1ps
`include "intc_defs.vh"

module intc_top #(
  parameter N = 8
)(
  input  wire                clk,
  input  wire                rst_n,
  input  wire [N-1:0]        irq_i,
  input  wire                cfg_we_i,
  input  wire                cfg_re_i,
  input  wire [1:0]          cfg_addr_i,
  input  wire [N-1:0]        cfg_wdata_i,
  output reg  [N-1:0]        cfg_rdata_o,
  input  wire                iack_i,
  output reg                 irq_o,
  output reg  [clog2(N)-1:0] irq_id_o
);

  function integer clog2;
    input integer value;
    integer v;
    begin
      v = value - 1;
      for (clog2 = 0; v > 0; clog2 = clog2 + 1)
        v = v >> 1;
    end
  endfunction

  localparam W = clog2(N);

  reg [N-1:0] sync0, sync1, sync1_d;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync0   <= {N{1'b0}};
      sync1   <= {N{1'b0}};
      sync1_d <= {N{1'b0}};
    end else begin
      sync0   <= irq_i;
      sync1   <= sync0;
      sync1_d <= sync1;
    end
  end

  wire [N-1:0] irq_rise = sync1 & ~sync1_d;
  reg [N-1:0] mask_q;
  wire cfg_write = cfg_we_i;
  wire wr_mask   = cfg_write && (cfg_addr_i == `ADDR_MASK);
  wire wr_eoi    = cfg_write && (cfg_addr_i == `ADDR_EOI);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)      mask_q <= {N{1'b0}};
    else if (wr_mask) mask_q <= cfg_wdata_i;
  end

  reg  [N-1:0] isr_q;
  wire [W-1:0] isr_top_id;
  wire         isr_any;

  prio_enc_param #(.N(N), .MSB_FIRST(1)) u_isr_top (
    .req_i (isr_q),
    .idx_o (isr_top_id),
    .vld_o (isr_any)
  );

  reg  [N-1:0] pend_q;
  wire [N-1:0] masked_pend;
  wire [W-1:0] cand_id;
  wire         cand_vld;
  wire         any_pend;

  intr_arbiter #(.N(N)) u_arb (
    .irq_i       (pend_q),
    .mask_i      (mask_q),
    .active_i    (isr_any),
    .active_id_i (isr_top_id),
    .pend_o      (masked_pend),
    .irq_id_o    (cand_id),
    .irq_vld_o   (cand_vld),
    .any_pend_o  (any_pend)
  );

  wire take    = iack_i && irq_o;
  wire eoi_hit = wr_eoi && isr_any;
  wire [N-1:0] one     = {{(N-1){1'b0}}, 1'b1};
  wire [N-1:0] take_oh = take    ? (one << irq_id_o)   : {N{1'b0}};
  wire [N-1:0] eoi_oh  = eoi_hit ? (one << isr_top_id) : {N{1'b0}};

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) pend_q <= {N{1'b0}};
    else        pend_q <= (pend_q & ~take_oh) | irq_rise;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) isr_q <= {N{1'b0}};
    else        isr_q <= (isr_q & ~eoi_oh) | take_oh;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      irq_o    <= 1'b0;
      irq_id_o <= {W{1'b0}};
    end else begin
      irq_o    <= cand_vld;
      irq_id_o <= cand_id;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cfg_rdata_o <= {N{1'b0}};
    end else if (cfg_re_i) begin
      case (cfg_addr_i)
        `ADDR_MASK: cfg_rdata_o <= mask_q;
        `ADDR_PEND: cfg_rdata_o <= pend_q;
        `ADDR_ISR:  cfg_rdata_o <= isr_q;
        default:    cfg_rdata_o <= {N{1'b0}};
      endcase
    end
  end

  wire _unused = &{1'b0, masked_pend, any_pend, 1'b0};

endmodule
