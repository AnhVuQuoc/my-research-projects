`timescale 1ns/1ps
`include "tb_defs.vh"

module ref_model (
  input  wire [`AW-1:0] addr_i,
  input  wire           valid_i,
  output reg  [`NS-1:0] sel_o,
  output reg            err_o
);

  always @(*) begin
    sel_o = {`NS{1'b0}};
    if (valid_i) begin
      if ((addr_i >= `BASE0) && (addr_i < (`BASE0 + `SIZE0))) sel_o[0] = 1'b1;
      if ((addr_i >= `BASE1) && (addr_i < (`BASE1 + `SIZE1))) sel_o[1] = 1'b1;
      if ((addr_i >= `BASE2) && (addr_i < (`BASE2 + `SIZE2))) sel_o[2] = 1'b1;
      if ((addr_i >= `BASE3) && (addr_i < (`BASE3 + `SIZE3))) sel_o[3] = 1'b1;
    end
    err_o = valid_i && (sel_o == {`NS{1'b0}});
  end

endmodule
