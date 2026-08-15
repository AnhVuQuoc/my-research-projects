`timescale 1ns/1ps
`include "tb_utils.vh"

module tb_addr_decoder;

  `TB_DECLARE

  localparam AW = 32;
  localparam NS = 4;

  reg  [AW-1:0] addr;
  reg           valid;
  wire [NS-1:0] sel;
  wire          err;

  addr_decoder #(.AW(AW), .NS(NS)) u_dut (
    .addr_i (addr ),
    .valid_i(valid),
    .sel_o  (sel  ),
    .err_o  (err  ));

  `TB_DUMP(tb_addr_decoder, "tb_addr_decoder.vcd")

  reg [31:0] base [0:NS-1];
  reg [31:0] size [0:NS-1];

  function integer count_ones_ns;
    input [NS-1:0] v;
    integer k;
    begin
      count_ones_ns = 0;
      for (k = 0; k < NS; k = k + 1)
        count_ones_ns = count_ones_ns + v[k];
    end
  endfunction


  function [NS-1:0] ref_sel;
    input [31:0] ad;
    input        vl;
    integer k;
    begin
      ref_sel = {NS{1'b0}};
      if (vl)
        for (k = 0; k < NS; k = k + 1)
          if ((ad >= base[k]) && (ad < (base[k] + size[k])))
            ref_sel[k] = 1'b1;
    end
  endfunction

  task drive_check;
    input [31:0] ad;
    input        vl;
    reg [NS-1:0] e_sel;
    begin
      addr  = ad;
      valid = vl;
      #1;
      e_sel = ref_sel(ad, vl);
      `CHECK_EQ("sel", sel, e_sel)
      `CHECK_EQ("err", err, (vl && (e_sel == {NS{1'b0}})))
      `CHECK_TRUE("TP7_one_hot_or_zero", count_ones_ns(sel) <= 1)
      `CHECK_TRUE("TP6_sel_err_excl",    !(err && (|sel)))
    end
  endtask

  integer k, i, seed;

  initial begin
    seed = 32'hA5A5_1234;

    base[0] = 32'h0000_0000; size[0] = 32'h0004_0000;  
    base[1] = 32'h2000_0000; size[1] = 32'h0000_8000; 
    base[2] = 32'h4000_0000; size[2] = 32'h0000_1000;  
    base[3] = 32'h4000_1000; size[3] = 32'h0000_1000;  

    `TB_BANNER("tb_addr_decoder - boundary value analysis")

    `INFO("TP1-TP4 : region boundaries")
    for (k = 0; k < NS; k = k + 1) begin
      drive_check(base[k],                        1'b1);  
      drive_check(base[k] + size[k] - 1,          1'b1); 
      drive_check(base[k] + (size[k] >> 1),       1'b1);  
      drive_check(base[k] - 1,                    1'b1);  
      drive_check(base[k] + size[k],              1'b1); 
    end


    `INFO("TP5 : unmapped addresses")
    drive_check(32'h1000_0000, 1'b1);   
    drive_check(32'h3FFF_FFFF, 1'b1);   
    drive_check(32'h4000_2000, 1'b1);   
    drive_check(32'hFFFF_FFFF, 1'b1);   


    `INFO("TP8 : valid qualification")
    for (k = 0; k < NS; k = k + 1)
      drive_check(base[k], 1'b0);       
    `INFO("Random phase : 5000 vectors, 50% biased near a region")
    for (i = 0; i < 5000; i = i + 1) begin
      if (i % 2 == 0) begin
        k = {$random(seed)} % NS;
        drive_check(base[k] + ({$random(seed)} % (size[k] + 64)) - 32, 1'b1);
      end else begin
        drive_check($random(seed), 1'b1);
      end
    end
    `TB_SUMMARY("tb_addr_decoder")
    $finish;
  end

endmodule
