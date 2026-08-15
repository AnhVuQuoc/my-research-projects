`timescale 1ns/1ps

module decoder_3to8_struct (
  input  wire       en,
  input  wire [2:0] a,
  output wire [7:0] y
);

  wire na0, na1, na2;

  not u_n0 (na0, a[0]);
  not u_n1 (na1, a[1]);
  not u_n2 (na2, a[2]);
  and u_y0 (y[0], en, na2, na1, na0);
  and u_y1 (y[1], en, na2, na1, a[0]);
  and u_y2 (y[2], en, na2, a[1], na0);
  and u_y3 (y[3], en, na2, a[1], a[0]);
  and u_y4 (y[4], en, a[2], na1, na0);
  and u_y5 (y[5], en, a[2], na1, a[0]);
  and u_y6 (y[6], en, a[2], a[1], na0);
  and u_y7 (y[7], en, a[2], a[1], a[0]);

endmodule
