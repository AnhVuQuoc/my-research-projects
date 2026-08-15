`timescale 1ns/1ps
`include "tb_utils.vh"

module tb_prio_encoder;

  `TB_DECLARE
  `TB_DUMP(tb_prio_encoder, "tb_prio_encoder.vcd")

  reg  [7:0] req;

  wire [2:0] y_casez;
  wire       v_casez;
  priority_encoder_8to3 u_casez (.d_i(req), .y_o(y_casez), .vld_o(v_casez));

  wire [2:0] y_loop;
  wire       v_loop;
  prio_enc_param #(.N(8), .MSB_FIRST(1)) u_loop (.req_i(req), .idx_o(y_loop), .vld_o(v_loop));

  wire [2:0] y_lsb;
  wire       v_lsb;
  prio_enc_param #(.N(8), .MSB_FIRST(0)) u_lsb (.req_i(req), .idx_o(y_lsb), .vld_o(v_lsb));


  reg [2:0] ref_idx;
  reg       ref_vld;

  task ref_prio_msb;
    input [7:0] v;
    integer k;
    begin
      ref_idx = 3'd0;
      ref_vld = 1'b0;
      for (k = 7; k >= 0; k = k - 1)
        if (v[k] && !ref_vld) begin
          ref_idx = k;
          ref_vld = 1'b1;
        end
    end
  endtask

  reg [2:0] ref_idx_l;
  reg       ref_vld_l;

  task ref_prio_lsb;
    input [7:0] v;
    integer k;
    begin
      ref_idx_l = 3'd0;
      ref_vld_l = 1'b0;
      for (k = 0; k < 8; k = k + 1)
        if (v[k] && !ref_vld_l) begin
          ref_idx_l = k;
          ref_vld_l = 1'b1;
        end
    end
  endtask

  task check_properties;
    input [7:0]  v;
    input [2:0]  idx;
    input        vld;
    input [79:0] who;
    reg   [4:0]  idx_wide;
    begin
      `CHECK_EQ("P1.vld", vld, (|v))

      if (vld) begin
        `CHECK_TRUE("P2.winner_requested", v[idx] === 1'b1)

        idx_wide = {2'b00, idx} + 5'd1;
        `CHECK_TRUE("P3.no_higher_pending", (v >> idx_wide) == 8'd0)
      end else begin
        `CHECK_EQ("P4.idle_zero", idx, 3'd0)
      end
      if (tb_verbose) $display("properties ok for %0s", who);
    end
  endtask

  reg [8:0] vec;
  integer   n_lsb_differs;

  initial begin
    `TB_BANNER("tb_prio_encoder")

    `INFO("1: exhaustive sweep of all 256 input codes")
    n_lsb_differs = 0;

    for (vec = 0; vec < 256; vec = vec + 1) begin
      req = vec[7:0];
      #1;

      ref_prio_msb(req);
      ref_prio_lsb(req);

      `CHECK_EQ("casez.idx", y_casez, ref_idx)
      `CHECK_EQ("casez.vld", v_casez, ref_vld)
      `CHECK_EQ("loop.idx",  y_loop,  ref_idx)
      `CHECK_EQ("loop.vld",  v_loop,  ref_vld)
      `CHECK_EQ("lsb.idx",   y_lsb,   ref_idx_l)
      `CHECK_EQ("lsb.vld",   v_lsb,   ref_vld_l)

      check_properties(req, y_casez, v_casez, "casez");
      check_properties(req, y_loop,  v_loop,  "loop");

      `CHECK_EQ("equiv.idx", y_casez, y_loop)
      `CHECK_EQ("equiv.vld", v_casez, v_loop)

      if (v_casez && (y_casez !== y_lsb)) n_lsb_differs = n_lsb_differs + 1;
    end

    $display("codes where MSB and LSB priority disagree : %0d / 256",n_lsb_differs);
    $display("(they agree only on the 8 one-hot codes and on zero -");
    $display("i.e. exactly where a plain encoder would have worked)");

    `INFO("2: directed corner cases")

    req = 8'b0000_0000; #1;
    `CHECK_EQ("corner.none.vld",  v_casez, 1'b0)
    `CHECK_EQ("corner.none.idx",  y_casez, 3'd0)

    req = 8'b1111_1111; #1;
    `CHECK_EQ("corner.all.idx",   y_casez, 3'd7)
    `CHECK_EQ("corner.all.vld",   v_casez, 1'b1)
    `CHECK_EQ("corner.all.lsb",   y_lsb,   3'd0)

    req = 8'b1000_0000; #1;
    `CHECK_EQ("corner.top_only",  y_casez, 3'd7)

    req = 8'b0000_0001; #1;
    `CHECK_EQ("corner.bot_only",  y_casez, 3'd0)
    `CHECK_EQ("corner.bot_vld",   v_casez, 1'b1)

    req = 8'b1000_0001; #1;
    `CHECK_EQ("corner.top_beats_bot", y_casez, 3'd7)

    `INFO("3: lower-priority requests must not disturb the winner")
    begin : lower_indep
      reg [2:0] base_idx;
      reg       base_vld;
      integer   b, k2;
      reg [7:0] stim;
      reg [7:0] k2v;

      for (b = 1; b < 8; b = b + 1) begin
        req = (8'd1 << b); #1;
        base_idx = y_casez;
        base_vld = v_casez;

        for (k2 = 0; k2 < (1 << b); k2 = k2 + 1) begin
          k2v  = k2;
          stim = (8'd1 << b) | k2v;
          req  = stim; #1;
          `CHECK_EQ("P5.lower_ignored.idx", y_casez, base_idx)
          `CHECK_EQ("P5.lower_ignored.vld", v_casez, base_vld)
        end
      end
    end

    `INFO("4: X on the highest-priority input")
    req = 8'bx000_0001; #1;
    `CHECK_TRUE("X.pessimism", (y_casez[2] === 1'bx) || (v_casez === 1'bx) || (y_casez    === 3'd7));
    req = 8'b0;

    `TB_SUMMARY("tb_prio_encoder")
    $finish;
  end

endmodule
