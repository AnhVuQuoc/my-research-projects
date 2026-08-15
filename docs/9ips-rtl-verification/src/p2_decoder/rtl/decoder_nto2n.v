`timescale 1ns/1ps

module decoder_nto2n #(
  parameter N          = 3,     
  parameter ACTIVE_LOW = 0     
)(
  input  wire            en,
  input  wire [N-1:0]    a,
  output wire [2**N-1:0] y
);

  localparam WOUT = 2**N;

  wire [WOUT-1:0] onehot = en ? ({{(WOUT-1){1'b0}}, 1'b1} << a): {WOUT{1'b0}};

  assign y = ACTIVE_LOW ? ~onehot : onehot;

endmodule
