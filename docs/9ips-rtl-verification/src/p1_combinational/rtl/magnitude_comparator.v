`timescale 1ns/1ps

module magnitude_comparator #(
  parameter WIDTH  = 8,
  parameter SIGNED = 0          // 0 = unsigned, 1 = two's complement
)(
  input  wire [WIDTH-1:0] a,
  input  wire [WIDTH-1:0] b,
  output wire             eq,
  output wire             lt,
  output wire             gt
);

  localparam MSB = WIDTH-1;

  wire lt_u = (a < b);          // plain unsigned compare
  wire lt_s = (a[MSB] ^ b[MSB]) ? a[MSB] : lt_u;

  assign eq = (a == b);
  assign lt = SIGNED ? lt_s : lt_u;
  assign gt = ~eq & ~lt;

endmodule
