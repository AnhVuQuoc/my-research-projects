`timescale 1ns/1ps
`include "tb_utils.vh"

module tb_decoder_nto2n;

  `TB_DECLARE

  reg         en;
  reg  [4:0]  a;                      

  wire [3:0]  y2;
  wire [7:0]  y3;
  wire [15:0] y4;
  wire [31:0] y5;
  wire [7:0]  y3n;                     

  decoder_nto2n #(.N(2)) u_d2 (.en(en), .a(a[1:0]), .y(y2));
  decoder_nto2n #(.N(3)) u_d3 (.en(en), .a(a[2:0]), .y(y3));
  decoder_nto2n #(.N(4)) u_d4 (.en(en), .a(a[3:0]), .y(y4));
  decoder_nto2n #(.N(5)) u_d5 (.en(en), .a(a[4:0]), .y(y5));
  decoder_nto2n #(.N(3), .ACTIVE_LOW(1)) u_d3n (.en(en), .a(a[2:0]), .y(y3n));

  `TB_DUMP(tb_decoder_nto2n, "tb_decoder_nto2n.vcd")

  integer i, e;

  initial begin
    `TB_BANNER("tb_decoder_nto2n - parameter sweep N=2,3,4,5")

    for (e = 0; e < 2; e = e + 1)
      for (i = 0; i < 32; i = i + 1) begin
        en = e[0];
        a  = i[4:0];
        #1;
        `CHECK_EQ("N2", y2, en ? ( 4'h1 << a[1:0]) :  4'h0)
        `CHECK_EQ("N3", y3, en ? ( 8'h1 << a[2:0]) :  8'h0)
        `CHECK_EQ("N4", y4, en ? (16'h1 << a[3:0]) : 16'h0)
        `CHECK_EQ("N5", y5, en ? (32'h1 << a[4:0]) : 32'h0)
        `CHECK_EQ("N3_active_low", y3n, ~y3)
      end

    `TB_SUMMARY("tb_decoder_nto2n")
    $finish;
  end

endmodule
