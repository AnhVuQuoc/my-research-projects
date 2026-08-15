`timescale 1ns/1ps
`include "tb_defs.vh"

module reg_model #(
  parameter AW = `U_AW,
  parameter DW = `U_DW
)(
  input  wire          pclk,
  input  wire          presetn,
  input  wire          psel_i,
  input  wire          penable_i,
  input  wire          pwrite_i,
  input  wire [AW-1:0] paddr_i,
  input  wire [DW-1:0] pwdata_i,
  input  wire          pready_i,
  input  wire          tx_busy_i,
  output wire          exp_err_o,
  output reg  [DW-1:0] exp_rdata_o
);
  wire hit_ctrl   = (paddr_i == `UREG_CTRL);
  wire hit_baud   = (paddr_i == `UREG_BAUD);
  wire hit_status = (paddr_i == `UREG_STATUS);
  wire hit_txdata = (paddr_i == `UREG_TXDATA);
  wire hit_rxdata = (paddr_i == `UREG_RXDATA);
  wire hit_iclr   = (paddr_i == `UREG_ICLR);
  wire hit_id     = (paddr_i == `UREG_ID);

  wire mapped    = hit_ctrl | hit_baud | hit_status | hit_txdata |
                   hit_rxdata | hit_iclr | hit_id;
  wire read_only = hit_status | hit_rxdata | hit_id;

  wire bad_baud  = pwrite_i && hit_baud && (pwdata_i[`U_DIVW-1:0] < `UART_BAUD_MIN);

  assign exp_err_o = (!mapped) || (pwrite_i && read_only) || bad_baud;

  wire complete  = psel_i && penable_i && pready_i;
  wire wr_commit = complete &&  pwrite_i && !exp_err_o;
  wire rd_commit = complete && !pwrite_i && !exp_err_o;

  always @* begin
    if      (hit_ctrl)   exp_rdata_o = tb_env.fmodel.exp_ctrl(0);
    else if (hit_baud)   exp_rdata_o = tb_env.fmodel.exp_baud(0);
    else if (hit_status) exp_rdata_o = tb_env.fmodel.exp_status({31'd0, tx_busy_i});
    else if (hit_rxdata) exp_rdata_o = {24'd0, tb_env.fmodel.peek_rx(0)};
    else if (hit_id)     exp_rdata_o = `UART_ID_VALUE;
    else                 exp_rdata_o = {DW{1'b0}};
  end

  always @(posedge pclk) begin
    if (presetn) begin
      if (wr_commit) begin
        if (hit_ctrl)   tb_env.fmodel.write_ctrl(pwdata_i);
        if (hit_baud)   tb_env.fmodel.write_baud(pwdata_i);
        if (hit_txdata) tb_env.fmodel.push_tx(pwdata_i[7:0]);
        if (hit_iclr)   tb_env.fmodel.clear_errors(pwdata_i);
      end
      if (rd_commit && hit_rxdata) tb_env.fmodel.pop_rx;
    end
  end

endmodule
