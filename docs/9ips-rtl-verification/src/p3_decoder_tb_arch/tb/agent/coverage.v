`timescale 1ns/1ps
`include "tb_defs.vh"

module coverage (
  input wire           clk,
  input wire           rst_n,
  input wire           req_i,         
  input wire           mon_vld_i,
  input wire [`AW-1:0] mon_addr_i,
  input wire [`NS-1:0] mon_sel_i,
  input wire           mon_err_i
);

  localparam NBINS = 16;

  integer bins [0:NBINS-1];
  integer i;

  reg req_d;
  reg b2b;                

  initial
    for (i = 0; i < NBINS; i = i + 1) bins[i] = 0;

  reg b2b_s1;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_d  <= 1'b0;
      b2b_s1 <= 1'b0;
      b2b    <= 1'b0;
    end else begin
      req_d  <= req_i;
      b2b_s1 <= req_i && req_d;
      b2b    <= b2b_s1;
    end
  end

  always @(posedge clk) begin
    if (rst_n && mon_vld_i) begin
      if (mon_sel_i[0]) bins[0] = bins[0] + 1;
      if (mon_sel_i[1]) bins[1] = bins[1] + 1;
      if (mon_sel_i[2]) bins[2] = bins[2] + 1;
      if (mon_sel_i[3]) bins[3] = bins[3] + 1;
      if (mon_err_i)    bins[4] = bins[4] + 1;
      if (mon_addr_i == `BASE0) bins[5] = bins[5] + 1;
      if (mon_addr_i == `BASE1) bins[6] = bins[6] + 1;
      if (mon_addr_i == `BASE2) bins[7] = bins[7] + 1;
      if (mon_addr_i == `BASE3) bins[8] = bins[8] + 1;
      if (mon_addr_i == (`BASE0 + `SIZE0 - 1)) bins[9]  = bins[9]  + 1;
      if (mon_addr_i == (`BASE1 + `SIZE1 - 1)) bins[10] = bins[10] + 1;
      if (mon_addr_i == (`BASE2 + `SIZE2 - 1)) bins[11] = bins[11] + 1;
      if (mon_addr_i == (`BASE3 + `SIZE3 - 1)) bins[12] = bins[12] + 1;
      if ((mon_addr_i == (`BASE0 + `SIZE0)) ||
          (mon_addr_i == (`BASE1 + `SIZE1)) ||
          (mon_addr_i == (`BASE2 + `SIZE2)) ||
          (mon_addr_i == (`BASE3 + `SIZE3))) bins[13] = bins[13] + 1;

      if (b2b)  bins[14] = bins[14] + 1;
      else      bins[15] = bins[15] + 1;
    end
  end

  function [8*24-1:0] bin_name;
    input integer idx;
    begin
      case (idx)
        0 : bin_name = "slave0_FLASH";
        1 : bin_name = "slave1_SRAM";
        2 : bin_name = "slave2_GPIO";
        3 : bin_name = "slave3_UART";
        4 : bin_name = "decode_error";
        5 : bin_name = "base_FLASH";
        6 : bin_name = "base_SRAM";
        7 : bin_name = "base_GPIO";
        8 : bin_name = "base_UART";
        9 : bin_name = "last_FLASH";
        10: bin_name = "last_SRAM";
        11: bin_name = "last_GPIO";
        12: bin_name = "last_UART";
        13: bin_name = "one_past_end";
        14: bin_name = "back_to_back";
        15: bin_name = "with_idle_gap";
        default: bin_name = "unknown";
      endcase
    end
  endfunction

  integer hit;

  task report;
    begin
      hit = 0;
      $display("");
      $display("- FUNCTIONAL COVERAGE -");
      $display("  %-24s %10s %8s", "bin", "count", "status");
      for (i = 0; i < NBINS; i = i + 1) begin
        if (bins[i] > 0) hit = hit + 1;
        $display("  %-24s %10d %8s", bin_name(i), bins[i],
                 (bins[i] > 0) ? "HIT" : "MISS");
      end
      $display("----------------------");
      $display("  bins hit : %0d / %0d  (%0d %%)", hit, NBINS,
               (hit * 100) / NBINS);
      $display("----------------------");
    end
  endtask

  function integer coverage_pct;
    integer k, h;
    begin
      h = 0;
      for (k = 0; k < NBINS; k = k + 1)
        if (bins[k] > 0) h = h + 1;
      coverage_pct = (h * 100) / NBINS;
    end
  endfunction

endmodule
