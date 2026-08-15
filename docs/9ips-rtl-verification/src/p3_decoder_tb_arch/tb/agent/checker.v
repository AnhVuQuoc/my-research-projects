`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module checker (
  input wire           clk,
  input wire           rst_n,
  input wire           req_i,
  input wire [`AW-1:0] addr_i,
  input wire [`NS-1:0] sel_i,
  input wire           err_i,
  input wire           ack_i,
  input wire           mon_vld_i,
  input wire [`AW-1:0] mon_addr_i,
  input wire [`NS-1:0] mon_sel_i,
  input wire           mon_err_i,
  input wire           mon_ack_i,
  input wire [`NS-1:0] ref_sel_i,
  input wire           ref_err_i
);

  `TB_DECLARE

  reg [31:0] n_trans;
  initial     n_trans = 32'd0;

  always @(posedge clk) begin
    if (rst_n && mon_vld_i) begin
      n_trans = n_trans + 32'd1;
      `CHECK_EQ("SB_sel", mon_sel_i, ref_sel_i)
      `CHECK_EQ("SB_err", mon_err_i, ref_err_i)
      `CHECK_EQ("SB_ack", mon_ack_i, 1'b1)
    end
  end

  function integer ones_ns;
    input [`NS-1:0] v;
    integer k;
    begin
      ones_ns = 0;
      for (k = 0; k < `NS; k = k + 1)
        ones_ns = ones_ns + v[k];
    end
  endfunction

  reg req_d;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) req_d <= 1'b0;
    else        req_d <= req_i;
  end

  always @(posedge clk) begin
    if (rst_n) begin
      `CHECK_EQ("C1_ack_latency", ack_i, req_d)
      `CHECK_TRUE("C2_sel_onehot0", ones_ns(sel_i) <= 1)
      `CHECK_TRUE("C3_sel_err_excl", !(err_i && (|sel_i)))
      if (!req_d) begin
        `CHECK_EQ("C4_idle_sel", sel_i, {`NS{1'b0}})
        `CHECK_EQ("C4_idle_err", err_i, 1'b0)
        `CHECK_EQ("C4_idle_ack", ack_i, 1'b0)
      end
    end
  end

  always @(negedge rst_n) begin
    #1;
    `CHECK_EQ("C5_reset_sel", sel_i, {`NS{1'b0}})
    `CHECK_EQ("C5_reset_err", err_i, 1'b0)
    `CHECK_EQ("C5_reset_ack", ack_i, 1'b0)
  end

  task report;
    input [8*32-1:0] name;
    begin
      $display("");
      $display(" transactions scoreboarded : %0d", n_trans);
      `TB_SUMMARY(name)
    end
  endtask

  task expect_min_trans;
    input [31:0] n;
    begin
      `CHECK_TRUE("min transactions reached", n_trans >= n)
    end
  endtask

endmodule
