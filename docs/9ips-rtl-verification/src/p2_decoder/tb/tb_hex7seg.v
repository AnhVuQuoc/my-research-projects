`timescale 1ns/1ps
`include "tb_utils.vh"

module tb_hex7seg;

  `TB_DECLARE

  // seg_o = {g, f, e, d, c, b, a}
  localparam [6:0] SEG_A = 7'b0000001;
  localparam [6:0] SEG_B = 7'b0000010;
  localparam [6:0] SEG_C = 7'b0000100;
  localparam [6:0] SEG_D = 7'b0001000;
  localparam [6:0] SEG_E = 7'b0010000;
  localparam [6:0] SEG_F = 7'b0100000;
  localparam [6:0] SEG_G = 7'b1000000;

  reg  [3:0] val;
  reg        blank;
  
  wire [6:0] seg_cc;    
  wire [6:0] seg_ca;    

  hex7seg #(.COMMON_ANODE(0)) u_cc (.val_i(val), .blank_i(blank), .seg_o(seg_cc));
  hex7seg #(.COMMON_ANODE(1)) u_ca (.val_i(val), .blank_i(blank), .seg_o(seg_ca));

  `TB_DUMP(tb_hex7seg, "tb_hex7seg.vcd")

  function [6:0] ref_pattern;
    input [3:0] v;
    begin
      case (v)
        4'h0: ref_pattern = SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_F;
        4'h1: ref_pattern = SEG_B|SEG_C;
        4'h2: ref_pattern = SEG_A|SEG_B|SEG_D|SEG_E|SEG_G;
        4'h3: ref_pattern = SEG_A|SEG_B|SEG_C|SEG_D|SEG_G;
        4'h4: ref_pattern = SEG_B|SEG_C|SEG_F|SEG_G;
        4'h5: ref_pattern = SEG_A|SEG_C|SEG_D|SEG_F|SEG_G;
        4'h6: ref_pattern = SEG_A|SEG_C|SEG_D|SEG_E|SEG_F|SEG_G;
        4'h7: ref_pattern = SEG_A|SEG_B|SEG_C;
        4'h8: ref_pattern = SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_F|SEG_G;
        4'h9: ref_pattern = SEG_A|SEG_B|SEG_C|SEG_D|SEG_F|SEG_G;
        4'hA: ref_pattern = SEG_A|SEG_B|SEG_C|SEG_E|SEG_F|SEG_G;   
        4'hB: ref_pattern = SEG_C|SEG_D|SEG_E|SEG_F|SEG_G;         
        4'hC: ref_pattern = SEG_A|SEG_D|SEG_E|SEG_F;               
        4'hD: ref_pattern = SEG_B|SEG_C|SEG_D|SEG_E|SEG_G;         
        4'hE: ref_pattern = SEG_A|SEG_D|SEG_E|SEG_F|SEG_G;         
        4'hF: ref_pattern = SEG_A|SEG_E|SEG_F|SEG_G;              
        default: ref_pattern = 7'h00;
      endcase
    end
  endfunction

  integer i, b;
  reg [6:0] exp;

  initial begin
    `TB_BANNER("tb_hex7seg - exhaustive 16 codes x blank x polarity")

    for (b = 0; b < 2; b = b + 1)
      for (i = 0; i < 16; i = i + 1) begin
        val   = i[3:0];
        blank = b[0];
        #1;
        exp = blank ? 7'h00 : ref_pattern(val);
        `CHECK_EQ("common_cathode", seg_cc,  exp)
        `CHECK_EQ("common_anode",   seg_ca, ~exp)
        `CHECK_EQ("polarity_inv",   seg_ca, ~seg_cc)
      end

    begin : distinctness
      integer p, q;
      for (p = 0; p < 16; p = p + 1)
        for (q = p + 1; q < 16; q = q + 1)
          `CHECK_TRUE("patterns_distinct", ref_pattern(p[3:0]) !== ref_pattern(q[3:0]))
    end
	
    `TB_SUMMARY("tb_hex7seg")
    $finish;
  end

endmodule
