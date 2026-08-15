`timescale 1ns/1ps

module sync_fifo #(
  parameter WIDTH = 8,
  parameter DEPTH = 4,
  parameter AW    = 2,
  parameter CNTW  = 3
)(
  input  wire             clk,
  input  wire             rst_n,

  input  wire             wr_i,
  input  wire [WIDTH-1:0] wdata_i,
  input  wire             rd_i,
  output wire [WIDTH-1:0] rdata_o,

  output wire             empty_o,
  output wire             full_o,
  output wire [CNTW-1:0]  count_o,
  output reg              overflow_o
);

  localparam [CNTW-1:0] DEPTH_C = DEPTH;

  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [AW-1:0]    wptr, rptr;
  reg [CNTW-1:0]  count;

  assign empty_o = (count == {CNTW{1'b0}});
  assign full_o  = (count == DEPTH_C);
  assign count_o = count;

  wire do_wr = wr_i && !full_o;
  wire do_rd = rd_i && !empty_o;

  assign rdata_o = mem[rptr];

  integer i;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr       <= {AW{1'b0}};
      rptr       <= {AW{1'b0}};
      count      <= {CNTW{1'b0}};
      overflow_o <= 1'b0;
      for (i = 0; i < DEPTH; i = i + 1) mem[i] <= {WIDTH{1'b0}};
    end else begin
      overflow_o <= wr_i && full_o;

      if (do_wr) begin
        mem[wptr] <= wdata_i;
        wptr      <= wptr + {{(AW-1){1'b0}}, 1'b1};
      end

      if (do_rd)
        rptr <= rptr + {{(AW-1){1'b0}}, 1'b1};
      case ({do_wr, do_rd})
        2'b10:   count <= count + {{(CNTW-1){1'b0}}, 1'b1};
        2'b01:   count <= count - {{(CNTW-1){1'b0}}, 1'b1};
        default: count <= count;
      endcase
    end
  end

endmodule
