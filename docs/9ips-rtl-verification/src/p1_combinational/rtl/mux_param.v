`timescale 1ns/1ps

module mux_param #(
  parameter N  = 4,             
  parameter DW = 8,             
  parameter SW = (N <= 2)  ? 1 :
                 (N <= 4)  ? 2 :
                 (N <= 8)  ? 3 :
                 (N <= 16) ? 4 : 5
)(
  input  wire [N*DW-1:0] data_i,
  input  wire [SW-1:0]   sel_i,
  output reg  [DW-1:0]   data_o
);

  integer k;

  always @(*) begin
    data_o = {DW{1'b0}};                      
    for (k = 0; k < N; k = k + 1)
      if (sel_i == k)
        data_o = data_i[k*DW +: DW];         
  end

endmodule
