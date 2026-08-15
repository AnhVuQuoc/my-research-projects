`timescale 1ns/1ps
`include "apb_defs.vh"

module cmd_ctrl #(
  parameter N = `APB_INTC_N
)(
  input  wire         clk,
  input  wire         rst_n,
  input  wire         start_i,
  input  wire [31:0]  code_i,
  output reg          busy_o,
  output reg          c_we_o,
  output reg  [1:0]   c_addr_o,
  output reg  [N-1:0] c_wdata_o
);

  localparam ST_IDLE = 2'd0;
  localparam ST_RUN  = 2'd1;
  localparam ST_DONE = 2'd2;

  reg [1:0]  state;
  reg [31:0] code_q;
  reg [7:0]  step;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= ST_IDLE;
      code_q    <= 32'd0;
      step      <= 8'd0;
      busy_o    <= 1'b0;
      c_we_o    <= 1'b0;
      c_addr_o  <= 2'd0;
      c_wdata_o <= {N{1'b0}};
    end else begin
      c_we_o <= 1'b0;

      case (state)
        ST_IDLE: begin
          busy_o <= 1'b0;
          if (start_i) begin
            code_q <= code_i;
            step   <= 8'd0;
            state  <= ST_RUN;
            busy_o <= 1'b1;
          end
        end
		
        ST_RUN: begin
          case (code_q)
            `CMD_DRAIN: begin
              c_we_o    <= 1'b1;
              c_addr_o  <= `ADDR_EOI;
              c_wdata_o <= {N{1'b0}};
              step      <= step + 8'd1;
              if (step == (N - 1)) state <= ST_DONE;
            end

            `CMD_DISABLE_ALL: begin
              c_we_o    <= 1'b1;
              c_addr_o  <= `ADDR_MASK;
              c_wdata_o <= {N{1'b0}};
              state     <= ST_DONE;
            end

            `CMD_ENABLE_ALL: begin
              c_we_o    <= 1'b1;
              c_addr_o  <= `ADDR_MASK;
              c_wdata_o <= {N{1'b1}};
              state     <= ST_DONE;
            end

            default: state <= ST_DONE;
          endcase
        end

        ST_DONE: begin
          state  <= ST_IDLE;
          busy_o <= 1'b0;
        end

        default: begin
          state  <= ST_IDLE;
          busy_o <= 1'b0;
        end
      endcase
    end
  end

endmodule
