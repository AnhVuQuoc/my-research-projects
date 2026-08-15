`timescale 1ns/1ps

module ripple_carry_adder #(
  parameter WIDTH = 8
)(
  input  wire [WIDTH-1:0] a,
  input  wire [WIDTH-1:0] b,
  input  wire             cin,
  output wire [WIDTH-1:0] sum,
  output wire             cout,
  output wire             ovf     
);

  wire [WIDTH:0] carry;
  assign carry[0] = cin;

  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : g_fa
      full_adder u_fa (
        .a    (a[i]      ),
        .b    (b[i]      ),
        .cin  (carry[i]  ),
        .sum  (sum[i]    ),
        .cout (carry[i+1])
      );
    end
  endgenerate

  assign cout = carry[WIDTH];

  assign ovf  = carry[WIDTH] ^ carry[WIDTH-1];

endmodule
