`timescale 1ns/1ps
`include "tb_defs.vh"

module vip_monitor (
  input  wire           clk,
  input  wire           rst_n,
  input  wire           req_i,
  input  wire [`AW-1:0] addr_i,
  input  wire [`NS-1:0] sel_i,
  input  wire           err_i,
  input  wire           ack_i,
  output reg            mon_vld_o,
  output reg  [`AW-1:0] mon_addr_o,
  output reg  [`NS-1:0] mon_sel_o,
  output reg            mon_err_o,
  output reg            mon_ack_o,
  output reg  [31:0]    mon_count_o
);

  reg           s1_vld;
  reg [`AW-1:0] s1_addr;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s1_vld      <= 1'b0;
      s1_addr     <= {`AW{1'b0}};
      mon_vld_o   <= 1'b0;
      mon_addr_o  <= {`AW{1'b0}};
      mon_sel_o   <= {`NS{1'b0}};
      mon_err_o   <= 1'b0;
      mon_ack_o   <= 1'b0;
      mon_count_o <= 32'd0;
    end else begin
      s1_vld  <= req_i;
      s1_addr <= addr_i;
      mon_vld_o  <= s1_vld;
      mon_addr_o <= s1_addr;
      mon_sel_o  <= sel_i;
      mon_err_o  <= err_i;
      mon_ack_o  <= ack_i;

      if (s1_vld)
        mon_count_o <= mon_count_o + 32'd1;
    end
  end

endmodule
