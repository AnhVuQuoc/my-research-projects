`timescale 1ns/1ps
`include "tb_utils.vh"

module tb_mux_cmp;

  `TB_DECLARE


  reg  [4*8-1:0] d4;
  reg  [1:0]     s4;
  wire [7:0]     y4;

  reg  [8*8-1:0] d8;
  reg  [2:0]     s8;
  wire [7:0]     y8;

  mux_param #(.N(4), .DW(8)) u_mux4 (.data_i(d4), .sel_i(s4), .data_o(y4));
  mux_param #(.N(8), .DW(8)) u_mux8 (.data_i(d8), .sel_i(s8), .data_o(y8));


  reg  [3:0] ca, cb;
  wire eq_u, lt_u, gt_u;
  wire eq_s, lt_s, gt_s;

  magnitude_comparator #(.WIDTH(4), .SIGNED(0)) u_cmp_u
    (.a(ca), .b(cb), .eq(eq_u), .lt(lt_u), .gt(gt_u));
  magnitude_comparator #(.WIDTH(4), .SIGNED(1)) u_cmp_s
    (.a(ca), .b(cb), .eq(eq_s), .lt(lt_s), .gt(gt_s));

  `TB_DUMP(tb_mux_cmp, "tb_mux_cmp.vcd")

  integer i, k, seed;
  reg [7:0] expected;

  initial begin
    seed = 32'hDEAD_BEEF;
    `TB_BANNER("tb_mux_cmp")


    `INFO("mux : deterministic channel walk (N=4 and N=8)")
    for (k = 0; k < 4; k = k + 1)
      d4[k*8 +: 8] = 8'h11 * (k + 1);
    for (k = 0; k < 8; k = k + 1)
      d8[k*8 +: 8] = 8'h11 * (k + 1);

    for (k = 0; k < 4; k = k + 1) begin
      s4 = k[1:0]; #1;
      `CHECK_EQ("mux4_channel", y4, 8'h11 * (k + 1))
    end
    for (k = 0; k < 8; k = k + 1) begin
      s8 = k[2:0]; #1;
      `CHECK_EQ("mux8_channel", y8, 8'h11 * (k + 1))
    end


    `INFO("mux : 2000 random vectors")
    for (i = 0; i < 2000; i = i + 1) begin
      for (k = 0; k < 8; k = k + 1)
        d8[k*8 +: 8] = $random(seed);
      s8 = $random(seed);
      #1;
      expected = d8[s8*8 +: 8];      
      `CHECK_EQ("mux8_random", y8, expected)
    end


    `INFO("cmp : exhaustive 256 vectors, signed and unsigned")
    for (i = 0; i < 16; i = i + 1)
      for (k = 0; k < 16; k = k + 1) begin
        ca = i[3:0]; cb = k[3:0];
        #1;

        `CHECK_EQ("cmp_u_eq", eq_u, (ca == cb))
        `CHECK_EQ("cmp_u_lt", lt_u, (ca <  cb))
        `CHECK_EQ("cmp_u_gt", gt_u, (ca >  cb))

        `CHECK_EQ("cmp_s_eq", eq_s, ($signed(ca) == $signed(cb)))
        `CHECK_EQ("cmp_s_lt", lt_s, ($signed(ca) <  $signed(cb)))
        `CHECK_EQ("cmp_s_gt", gt_s, ($signed(ca) >  $signed(cb)))
 
        `CHECK_EQ("cmp_onehot", eq_u + lt_u + gt_u, 1)
      end


    ca = 4'h8; cb = 4'h7; #1;    
    `CHECK_TRUE("signed_lt_here",    lt_s == 1'b1)
    `CHECK_TRUE("unsigned_gt_here",  gt_u == 1'b1)

    `TB_SUMMARY("tb_mux_cmp")
    $finish;
  end

endmodule
