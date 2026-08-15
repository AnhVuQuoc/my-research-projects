`timescale 1ns/1ps
`include "tb_defs.vh"

module apb_monitor #(
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
  input  wire [DW-1:0] prdata_i,
  input  wire          pready_i,
  input  wire          pslverr_i,
  output reg           tr_vld_o,
  output reg           tr_write_o,
  output reg  [AW-1:0] tr_addr_o,
  output reg  [DW-1:0] tr_wdata_o,
  output reg  [DW-1:0] tr_rdata_o,
  output reg           tr_err_o,
  output reg  [7:0]    tr_waits_o,
  output reg  [31:0]   n_reads_o,
  output reg  [31:0]   n_writes_o,
  output reg  [31:0]   n_errors_o
);

  wire access   = psel_i && penable_i;
  wire complete = access && pready_i;

  reg [7:0] wait_cnt;

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      tr_vld_o   <= 1'b0;
      tr_write_o <= 1'b0;
      tr_addr_o  <= {AW{1'b0}};
      tr_wdata_o <= {DW{1'b0}};
      tr_rdata_o <= {DW{1'b0}};
      tr_err_o   <= 1'b0;
      tr_waits_o <= 8'd0;
      wait_cnt   <= 8'd0;
      n_reads_o  <= 32'd0;
      n_writes_o <= 32'd0;
      n_errors_o <= 32'd0;
    end else begin
      if (access && !pready_i) wait_cnt <= wait_cnt + 8'd1;
      else if (!access)        wait_cnt <= 8'd0;

      if (complete) begin
        tr_vld_o   <= 1'b1;
        tr_write_o <= pwrite_i;
        tr_addr_o  <= paddr_i;
        tr_wdata_o <= pwdata_i;
        tr_rdata_o <= prdata_i;
        tr_err_o   <= pslverr_i;
        tr_waits_o <= wait_cnt;
        wait_cnt   <= 8'd0;
        if (pwrite_i) n_writes_o <= n_writes_o + 32'd1;
        else          n_reads_o  <= n_reads_o  + 32'd1;
        if (pslverr_i) n_errors_o <= n_errors_o + 32'd1;
      end else begin
        tr_vld_o <= 1'b0;
      end
    end
  end

endmodule
