`timescale 1ns/1ps
`include "uart_defs.vh"

module baud_gen #(
  parameter DIVW       = 16,
  parameter OVERSAMPLE = `UART_OVERSAMPLE
)(
  input  wire            clk,
  input  wire            rst_n,
  input  wire            en_i,
  input  wire [DIVW-1:0] div_i,
  input  wire            rx_restart_i,
  output wire            bit_tick_o,
  output wire            os_tick_o
);

  function integer clog2;
    input integer value;
    integer v;
    begin
      v = value - 1;
      for (clog2 = 0; v > 0; clog2 = clog2 + 1) v = v >> 1;
    end
  endfunction

  localparam OSW = clog2(OVERSAMPLE);

  wire [DIVW-1:0] os_period = div_i >> OSW;

  reg [DIVW-1:0] os_cnt;
  reg            os_tick_q;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      os_cnt    <= {DIVW{1'b0}};
      os_tick_q <= 1'b0;
    end else if (!en_i) begin
      os_cnt    <= {DIVW{1'b0}};
      os_tick_q <= 1'b0;
    end else if (rx_restart_i) begin
      os_cnt    <= {1'b0, os_period[DIVW-1:1]};
      os_tick_q <= 1'b0;
    end else if (os_cnt >= os_period) begin
      os_cnt    <= {DIVW{1'b0}};
      os_tick_q <= 1'b1;
    end else begin
      os_cnt    <= os_cnt + {{(DIVW-1){1'b0}}, 1'b1};
      os_tick_q <= 1'b0;
    end
  end

  assign os_tick_o = os_tick_q;
  reg [OSW-1:0] os_phase;
  reg           bit_tick_q;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      os_phase   <= {OSW{1'b0}};
      bit_tick_q <= 1'b0;
    end else if (!en_i) begin
      os_phase   <= {OSW{1'b0}};
      bit_tick_q <= 1'b0;
    end else if (os_tick_q) begin
      os_phase   <= os_phase + {{(OSW-1){1'b0}}, 1'b1};
      bit_tick_q <= (os_phase == {OSW{1'b1}});
    end else begin
      bit_tick_q <= 1'b0;
    end
  end

  assign bit_tick_o = bit_tick_q;

endmodule
