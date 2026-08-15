`timescale 1ns/1ps
`include "tb_utils.vh"

module tb_encoder_basic;

  `TB_DECLARE
  `TB_DUMP(tb_encoder_basic, "tb_encoder_basic.vcd")

  reg  [7:0] d;
  wire [2:0] y_simple;
  encoder_8to3_simple u_simple (.d_i(d), .y_o(y_simple));
  wire [2:0] oh_bin;
  wire       oh_vld, oh_err;

  onehot2bin #(.N(8)) u_oh8 (
    .onehot_i (d),
    .bin_o    (oh_bin),
    .vld_o    (oh_vld),
    .err_o    (oh_err)
  );

  reg  [2:0] rt_a;
  reg        rt_en;
  wire [7:0] rt_onehot;
  wire [2:0] rt_bin;
  wire       rt_vld, rt_err;

  decoder_nto2n #(.N(3), .ACTIVE_LOW(0)) u_dec (
    .en (rt_en),
    .a  (rt_a),
    .y  (rt_onehot)
  );

  onehot2bin #(.N(8)) u_oh_rt (
    .onehot_i (rt_onehot),
    .bin_o    (rt_bin),
    .vld_o    (rt_vld),
    .err_o    (rt_err)
  );

  reg [2:0] ref_bin;
  integer   ref_ones;

  task ref_onehot2bin;
    input  [7:0] v;
    integer k;
    begin
      ref_bin  = 0;
      ref_ones = 0;
      for (k = 0; k < 8; k = k + 1) begin
        if (v[k]) begin
          if (ref_ones == 0) ref_bin = k;
          ref_ones = ref_ones + 1;
        end
      end
    end
  endtask

  integer i, j;
  reg [2:0] i3;
  integer n_onehot_ok, n_multihot_wrong;
  reg [8:0] vec;

  initial begin
    `TB_BANNER("tb_encoder_basic")

    `INFO("A1: simple encoder on the 8 one-hot codes")
    n_onehot_ok = 0;
    for (i = 0; i < 8; i = i + 1) begin
      i3 = i;
      d  = (8'd1 << i);
      #1;
      `CHECK_EQ("simple.onehot", y_simple, i3)
      if (y_simple === i3) n_onehot_ok = n_onehot_ok + 1;
    end
    $display("one-hot codes encoded correctly : %0d / 8", n_onehot_ok);

    `INFO("A2: demonstrating the zero-ambiguity failure mode")
    d = 8'b0000_0000; #1;
    `CHECK_EQ("simple.d=0", y_simple, 3'd0)
    d = 8'b0000_0001; #1;
    `CHECK_EQ("simple.d=1", y_simple, 3'd0)
    $display("d=0x00 -> y=0 and d=0x01 -> y=0 : NO valid bit, so the");
    $display("consumer cannot tell 'nothing requested' from 'source 0'.");

    `INFO("A3: demonstrating the multi-hot failure mode")
    d = 8'b0000_0110; #1;
    `CHECK_EQ("simple.d=0x06", y_simple, 3'd3)
    `CHECK_TRUE("simple.d=0x06.not_requested", d[3] === 1'b0)
    $display("d=0x06 (sources 1,2 active) -> y=3, a source that is NOT");
    $display("requesting. The OR tree adds the codes instead of choosing.");

    n_multihot_wrong = 0;
    for (vec = 0; vec < 256; vec = vec + 1) begin
      d = vec[7:0];
      #1;
      ref_onehot2bin(vec[7:0]);
      if (ref_ones > 1 && y_simple !== ref_bin)
        n_multihot_wrong = n_multihot_wrong + 1;
    end
    $display("multi-hot codes giving a non-requested index : %0d / 247",
             n_multihot_wrong);
    `CHECK_TRUE("simple.is_broken_on_multihot", n_multihot_wrong > 0)

    `INFO("B: onehot2bin exhaustive (256 codes) vs independent model")
    for (vec = 0; vec < 256; vec = vec + 1) begin
      d = vec[7:0];
      #1;
      ref_onehot2bin(vec[7:0]);

      `CHECK_EQ("oh.vld", oh_vld, (ref_ones != 0))
      `CHECK_EQ("oh.err", oh_err, (ref_ones > 1))
      if (ref_ones == 1)
        `CHECK_EQ("oh.bin", oh_bin, ref_bin)
      if (ref_ones == 0)
        `CHECK_EQ("oh.bin.zero", oh_bin, 3'd0)
    end

    `INFO("C: round trip decoder -> encoder, en = 1")
    rt_en = 1'b1;
    for (i = 0; i < 8; i = i + 1) begin
      i3   = i;
      rt_a = i3;
      #1;
      `CHECK_EQ("roundtrip.bin", rt_bin, i3)
      `CHECK_TRUE("roundtrip.vld", rt_vld === 1'b1)
      `CHECK_TRUE("roundtrip.no_err", rt_err === 1'b0)
    end

    `INFO("C2: with the decoder disabled the chain must report 'nothing'")
    rt_en = 1'b0;
    for (i = 0; i < 8; i = i + 1) begin
      i3   = i;
      rt_a = i3;
      #1;
      `CHECK_TRUE("roundtrip.dis.vld", rt_vld === 1'b0)
      `CHECK_TRUE("roundtrip.dis.err", rt_err === 1'b0)
    end

    `INFO("D: X propagation")
    d = 8'b0000_00x0; #1;
    `CHECK_TRUE("oh.x_prop", (oh_vld === 1'bx) || (oh_bin[0] === 1'bx) ||
                             (oh_bin[1] === 1'bx))
    d = 8'b0;

    `TB_SUMMARY("tb_encoder_basic")
    $finish;
  end

endmodule
