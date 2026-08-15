`timescale 1ns/1ps
`include "apb_defs.vh"

module apb_slave #(
  parameter AW          = `APB_AW,
  parameter DW          = `APB_DW,
  parameter WAIT_STATES = 0
)(
  input  wire           pclk,
  input  wire           presetn,
  input  wire           psel_i,
  input  wire           penable_i,
  input  wire           pwrite_i,
  input  wire [AW-1:0]  paddr_i,
  input  wire [DW-1:0]  pwdata_i,
  output wire [DW-1:0]  prdata_o,
  output wire           pready_o,
  output wire           pslverr_o,
  output wire           reg_we_o,
  output wire           reg_re_o,
  output wire [AW-1:0]  reg_addr_o,
  output wire [DW-1:0]  reg_wdata_o,
  input  wire [DW-1:0]  reg_rdata_i,
  input  wire           reg_err_i
);

  localparam ST_IDLE   = 1'b0;
  localparam ST_ACCESS = 1'b1;

  reg        state;
  reg [7:0]  wcnt;

  wire setup_seen = psel_i && !penable_i;
  wire ready_now  = (WAIT_STATES == 0) ? 1'b1 : (wcnt >= WAIT_STATES[7:0]);

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      state <= ST_IDLE;
      wcnt  <= 8'd0;
    end else begin
      case (state)
        ST_IDLE: begin
          wcnt <= 8'd0;
          if (setup_seen) state <= ST_ACCESS;
        end
        ST_ACCESS: begin
          if (ready_now) begin
            state <= ST_IDLE;
            wcnt  <= 8'd0;
          end else begin
            wcnt  <= wcnt + 8'd1;
          end
        end
        default: state <= ST_IDLE;
      endcase
    end
  end
  assign reg_addr_o  = paddr_i;
  assign reg_wdata_o = pwdata_i;
  assign reg_re_o    = setup_seen && !pwrite_i && !reg_err_i;
  assign reg_we_o    = psel_i && penable_i && pwrite_i && ready_now && !reg_err_i;
  assign prdata_o    = reg_rdata_i;
  assign pready_o    = (state == ST_ACCESS) ? ready_now : 1'b1;
  assign pslverr_o   = (state == ST_ACCESS) && ready_now && reg_err_i;

endmodule
