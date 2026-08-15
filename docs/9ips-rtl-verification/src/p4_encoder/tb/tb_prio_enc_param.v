`timescale 1ns/1ps
`include "tb_utils.vh"

module tb_prio_enc_param;

  `TB_DECLARE
  `TB_DUMP(tb_prio_enc_param, "tb_prio_enc_param.vcd")

  reg [31:0] stim;

  wire [0:0] i2_m,  i2_l;    wire v2_m,  v2_l;
  wire [1:0] i4_m,  i4_l;    wire v4_m,  v4_l;
  wire [3:0] i16_m, i16_l;   wire v16_m, v16_l;
  wire [4:0] i32_m, i32_l;   wire v32_m, v32_l;

  prio_enc_param #(.N(2),  .MSB_FIRST(1)) u2m  (.req_i(stim[1:0]),  .idx_o(i2_m),  .vld_o(v2_m));
  prio_enc_param #(.N(2),  .MSB_FIRST(0)) u2l  (.req_i(stim[1:0]),  .idx_o(i2_l),  .vld_o(v2_l));
  prio_enc_param #(.N(4),  .MSB_FIRST(1)) u4m  (.req_i(stim[3:0]),  .idx_o(i4_m),  .vld_o(v4_m));
  prio_enc_param #(.N(4),  .MSB_FIRST(0)) u4l  (.req_i(stim[3:0]),  .idx_o(i4_l),  .vld_o(v4_l));
  prio_enc_param #(.N(16), .MSB_FIRST(1)) u16m (.req_i(stim[15:0]), .idx_o(i16_m), .vld_o(v16_m));
  prio_enc_param #(.N(16), .MSB_FIRST(0)) u16l (.req_i(stim[15:0]), .idx_o(i16_l), .vld_o(v16_l));
  prio_enc_param #(.N(32), .MSB_FIRST(1)) u32m (.req_i(stim),       .idx_o(i32_m), .vld_o(v32_m));
  prio_enc_param #(.N(32), .MSB_FIRST(0)) u32l (.req_i(stim),       .idx_o(i32_l), .vld_o(v32_l));

  reg [4:0] r_idx;
  reg       r_vld;

  task ref_prio;
    input [31:0] v;
    input integer n;
    input         msb_first;
    integer k;
    begin
      r_idx = 5'd0;
      r_vld = 1'b0;
      if (msb_first) begin
        for (k = n-1; k >= 0; k = k - 1)
          if (v[k] && !r_vld) begin r_idx = k; r_vld = 1'b1; end
      end else begin
        for (k = 0; k < n; k = k + 1)
          if (v[k] && !r_vld) begin r_idx = k; r_vld = 1'b1; end
      end
    end
  endtask

  task check_props;
    input [31:0]  v;
    input integer n;
    input [4:0]   idx;
    input         vld;
    reg   [31:0]  masked;
    reg   [5:0]   idx_wide;
    begin
      masked = v & ((n == 32) ? 32'hFFFF_FFFF : ((32'd1 << n) - 32'd1));
      `CHECK_EQ("Pn.vld", vld, (|masked))
      if (vld) begin
        `CHECK_TRUE("Pn.winner_requested", masked[idx] === 1'b1)
        idx_wide = {1'b0, idx} + 6'd1;
        `CHECK_TRUE("Pn.no_higher_pending", (masked >> idx_wide) == 32'd0)
      end else begin
        `CHECK_EQ("Pn.idle_zero", idx, 5'd0)
      end
    end
  endtask

  integer   n_iter, seed;
  reg [5:0] c2;
  reg [7:0] c4;
  integer   w;

  initial begin
    `TB_BANNER("tb_prio_enc_param")
    seed = 32'hE0C0_DE01;

    `INFO("1: N=2 exhaustive (4 codes) - degenerate 1-bit index")
    for (c2 = 0; c2 < 4; c2 = c2 + 1) begin
      stim = {30'd0, c2[1:0]};
      #1;
      ref_prio(stim, 2, 1);  `CHECK_EQ("n2.msb.idx", {4'd0,i2_m}, r_idx)
                             `CHECK_EQ("n2.msb.vld", v2_m, r_vld)
      ref_prio(stim, 2, 0);  `CHECK_EQ("n2.lsb.idx", {4'd0,i2_l}, r_idx)
                             `CHECK_EQ("n2.lsb.vld", v2_l, r_vld)
      check_props(stim, 2, {4'd0,i2_m}, v2_m);
    end
    stim = 32'd3; #1;
    `CHECK_EQ("n2.both.msb", i2_m, 1'b1)
    `CHECK_EQ("n2.both.lsb", i2_l, 1'b0)

    `INFO("2: N=4 exhaustive (16 codes)")
    for (c4 = 0; c4 < 16; c4 = c4 + 1) begin
      stim = {28'd0, c4[3:0]};
      #1;
      ref_prio(stim, 4, 1);  `CHECK_EQ("n4.msb.idx", {3'd0,i4_m}, r_idx)
                             `CHECK_EQ("n4.msb.vld", v4_m, r_vld)
      ref_prio(stim, 4, 0);  `CHECK_EQ("n4.lsb.idx", {3'd0,i4_l}, r_idx)
                             `CHECK_EQ("n4.lsb.vld", v4_l, r_vld)
      check_props(stim, 4, {3'd0,i4_m}, v4_m);
    end

    `INFO("3: N=16 exhaustive (65536 codes) - this may take a few seconds")
    for (n_iter = 0; n_iter < 65536; n_iter = n_iter + 1) begin
      stim = n_iter;
      #1;
      ref_prio(stim, 16, 1);  `CHECK_EQ("n16.msb.idx", {1'b0,i16_m}, r_idx)
                              `CHECK_EQ("n16.msb.vld", v16_m, r_vld)
      ref_prio(stim, 16, 0);  `CHECK_EQ("n16.lsb.idx", {1'b0,i16_l}, r_idx)
                              `CHECK_EQ("n16.lsb.vld", v16_l, r_vld)
      if ((n_iter % 16) == 0)
        check_props(stim, 16, {1'b0,i16_m}, v16_m);
    end

    `INFO("4a: N=32 one-hot walk - every bit position, including the last")
    for (w = 0; w < 32; w = w + 1) begin
      stim = (32'd1 << w);
      #1;
      ref_prio(stim, 32, 1);  `CHECK_EQ("n32.walk.msb", i32_m, r_idx)
      ref_prio(stim, 32, 0);  `CHECK_EQ("n32.walk.lsb", i32_l, r_idx)
      `CHECK_EQ("n32.walk.vld", v32_m, 1'b1)
      check_props(stim, 32, i32_m, v32_m);
    end

    `INFO("4b: N=32 corners")
    stim = 32'h0000_0000; #1;
    `CHECK_EQ("n32.zero.vld", v32_m, 1'b0)
    `CHECK_EQ("n32.zero.idx", i32_m, 5'd0)

    stim = 32'hFFFF_FFFF; #1;
    `CHECK_EQ("n32.all.msb", i32_m, 5'd31)
    `CHECK_EQ("n32.all.lsb", i32_l, 5'd0)

    stim = 32'h8000_0001; #1;
    `CHECK_EQ("n32.ends.msb", i32_m, 5'd31)
    `CHECK_EQ("n32.ends.lsb", i32_l, 5'd0)

    stim = 32'h8000_0000; #1;
    `CHECK_EQ("n32.top_only", i32_m, 5'd31)
    `CHECK_EQ("n32.top_vld",  v32_m, 1'b1)

    `INFO("4c: N=32 random sampling (20000 vectors)")
    for (n_iter = 0; n_iter < 20000; n_iter = n_iter + 1) begin
      stim = $random(seed);
      #1;
      ref_prio(stim, 32, 1);  `CHECK_EQ("n32.rnd.msb.idx", i32_m, r_idx)
                              `CHECK_EQ("n32.rnd.msb.vld", v32_m, r_vld)
      ref_prio(stim, 32, 0);  `CHECK_EQ("n32.rnd.lsb.idx", i32_l, r_idx)
      check_props(stim, 32, i32_m, v32_m);
    end

    $display("");
    $display("Note: N=32 was sampled (20032 of 4.29e9 codes = 5e-7 %%),");
    $display("not proven.  Uniform random on 32 bits sets the top bit in");
    $display("half of all draws, so the high-priority path is well");
    $display("exercised, but the low-index winners are rare: a fault that");
    $display("only shows when bits 31..1 are all clear has probability");
    $display("2^-31 per vector of being hit.  The one-hot walk in 4a is");
    $display("what actually covers those cases.");

    `TB_SUMMARY("tb_prio_enc_param")
    $finish;
  end

endmodule
