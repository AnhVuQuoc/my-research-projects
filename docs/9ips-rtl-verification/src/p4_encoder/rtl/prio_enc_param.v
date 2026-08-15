`timescale 1ns/1ps

module prio_enc_param #(
  parameter N         = 8,
  parameter MSB_FIRST = 1
)(
  input  wire [N-1:0]           req_i,
  output reg  [clog2(N)-1:0]    idx_o,
  output reg                    vld_o
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

  integer i;

  always @* begin
    idx_o = {W{1'b0}};      
    vld_o = 1'b0;
    if (MSB_FIRST) begin
      for (i = 0; i < N; i = i + 1)
        if (req_i[i]) begin
          idx_o = i;
          vld_o = 1'b1;
        end
    end else begin
      for (i = N-1; i >= 0; i = i - 1)
        if (req_i[i]) begin
          idx_o = i;
          vld_o = 1'b1;
        end
    end
  end

endmodule
