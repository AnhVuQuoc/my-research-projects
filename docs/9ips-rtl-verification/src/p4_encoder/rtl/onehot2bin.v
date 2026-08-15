`timescale 1ns/1ps

module onehot2bin #(
  parameter N = 8
)(
  input  wire [N-1:0]        onehot_i,
  output wire [clog2(N)-1:0] bin_o,
  output wire                vld_o,   
  output wire                err_o    
);

  function integer clog2;
    input integer value;
    integer v;
    begin
      v = value - 1;
      for (clog2 = 0; v > 0; clog2 = clog2 + 1)
        v = v >> 1;
    end
  endfunction

  localparam W = clog2(N);

  genvar b, i;
  generate
    for (b = 0; b < W; b = b + 1) begin : g_bit
      wire [N-1:0] contrib;
      for (i = 0; i < N; i = i + 1) begin : g_term
        assign contrib[i] = onehot_i[i] & (((i >> b) & 1) != 0);
      end
      assign bin_o[b] = |contrib;
    end
  endgenerate

  assign vld_o = |onehot_i;

  function integer popcount;
    input [N-1:0] v;
    integer k;
    begin
      popcount = 0;
      for (k = 0; k < N; k = k + 1)
        if (v[k]) popcount = popcount + 1;
    end
  endfunction

  assign err_o = (popcount(onehot_i) > 1);

endmodule
