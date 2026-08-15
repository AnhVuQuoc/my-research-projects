`timescale 1ns/1ps

module full_adder (
  input  wire a,
  input  wire b,
  input  wire cin,
  output wire sum,
  output wire cout
);

  wire ab, acin, bcin, axb;

  xor  u_x0 (axb , a   , b   );
  xor  u_x1 (sum , axb , cin );

  and  u_a0 (ab  , a   , b   );
  and  u_a1 (acin, a   , cin );
  and  u_a2 (bcin, b   , cin );
  or   u_o0 (cout, ab  , acin, bcin);

endmodule
