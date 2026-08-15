`timescale 1ns/1ps

module decoder_top #(
  parameter AW = 32,
  parameter NS = 4
)(
  input  wire           clk,
  input  wire           rst_n,
  input  wire           req_i,
  input  wire [AW-1:0]  addr_i,
  output reg  [NS-1:0]  sel_o,
  output reg            err_o,
  output reg            ack_o
);

  wire [NS-1:0] sel_c;
  wire          err_c;

  addr_decoder #(.AW(AW), .NS(NS)) u_dec (
    .addr_i (addr_i),
    .valid_i(req_i ),
    .sel_o  (sel_c ),
    .err_o  (err_c )
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sel_o <= {NS{1'b0}};
      err_o <= 1'b0;
      ack_o <= 1'b0;
    end else begin
      sel_o <= sel_c;
      err_o <= err_c;
      ack_o <= req_i;
    end
  end

endmodule
