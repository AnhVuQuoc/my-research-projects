`timescale 1ns/1ps
`include "tb_utils.vh"

module tb_decoder_3to8;

  `TB_DECLARE

  reg        en;
  reg  [2:0] a;
  wire [7:0] y_struct;
  wire [7:0] y_behav;

  decoder_3to8_struct         u_struct (.en(en), .a(a), .y(y_struct));
  decoder_nto2n #(.N(3), .ACTIVE_LOW(0)) u_behav (.en(en), .a(a), .y(y_behav));

  `TB_DUMP(tb_decoder_3to8, "tb_decoder_3to8.vcd")

  function integer count_ones;
    input [31:0] v;
    input integer nbits;
    integer k;
    begin
      count_ones = 0;
      for (k = 0; k < nbits; k = k + 1)
        count_ones = count_ones + v[k];
    end
  endfunction

  integer i, e, ones;
  reg [7:0] exp;

  initial begin
    `TB_BANNER("tb_decoder_3to8 - exhaustive + properties")

    for (e = 0; e < 2; e = e + 1)
      for (i = 0; i < 8; i = i + 1) begin
        en = e[0];
        a  = i[2:0];
        #1;
        exp = en ? (8'h01 << a) : 8'h00;
        `CHECK_EQ("struct_value", y_struct, exp)
        `CHECK_EQ("struct_vs_behav", y_struct, y_behav)
        ones = count_ones({24'h0, y_struct}, 8);
        if (en)
          `CHECK_EQ("P1_one_hot",  ones, 1)
        else
          `CHECK_EQ("P2_all_zero", ones, 0)
      end
    en = 1'b1; a = 3'bx0x; #1;
    `CHECK_TRUE("X_propagates", (^y_struct === 1'bx) || (y_struct === 8'h00))
    `TB_SUMMARY("tb_decoder_3to8")
    $finish;
  end

endmodule
