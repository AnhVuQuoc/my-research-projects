`timescale 1ns/1ps

module encoder_8to3_simple (
  input  wire [7:0] d_i,
  output wire [2:0] y_o
);

  assign y_o[0] = d_i[1] | d_i[3] | d_i[5] | d_i[7];
  assign y_o[1] = d_i[2] | d_i[3] | d_i[6] | d_i[7];
  assign y_o[2] = d_i[4] | d_i[5] | d_i[6] | d_i[7];

endmodule
