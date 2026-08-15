`timescale 1ns/1ps
`include "tb_defs.vh"

module vip_driver #(
  parameter MAX_GAP = 3          
)(
  input  wire           clk,
  input  wire           rst_n,
  input  wire           cpu_vld_i,
  input  wire [`AW-1:0] cpu_addr_i,
  output wire           drv_rdy_o,
  output reg            req_o,
  output reg  [`AW-1:0] addr_o
);

  integer seed;
  initial seed = 32'h5EED_0001;

  reg [7:0] gap;

  assign drv_rdy_o = (gap == 8'd0);

  wire accept = cpu_vld_i && drv_rdy_o;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_o  <= 1'b0;
      addr_o <= {`AW{1'b0}};
      gap    <= 8'd0;
    end else begin
      req_o <= 1'b0;                       
      if (accept) begin
        req_o  <= 1'b1;
        addr_o <= cpu_addr_i;
        gap    <= (MAX_GAP == 0) ? 8'd0
                                 : ({$random(seed)} % (MAX_GAP + 1));
      end else if (gap != 8'd0) begin
        gap <= gap - 8'd1;
      end
    end
  end

  task set_seed;
    input [31:0] s;
    begin
      seed = s;
    end
  endtask

endmodule
