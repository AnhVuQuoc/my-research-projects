`timescale 1ns/1ps
`include "uart_defs.vh"

module apb_uart #(
  parameter AW          = 8,
  parameter DW          = 32,
  parameter DIVW        = 16,
  parameter FIFO_DEPTH  = `UART_FIFO_DEPTH,
  parameter OVERSAMPLE  = `UART_OVERSAMPLE,
  parameter WAIT_STATES = 0
)(
  input  wire          pclk,
  input  wire          presetn,
  input  wire          psel_i,
  input  wire          penable_i,
  input  wire          pwrite_i,
  input  wire [AW-1:0] paddr_i,
  input  wire [DW-1:0] pwdata_i,
  output wire [DW-1:0] prdata_o,
  output wire          pready_o,
  output wire          pslverr_o,
  input  wire          rx_i,
  output wire          tx_o,
  output wire          irq_o
);

  wire          reg_we, reg_re;
  wire [AW-1:0] reg_addr;
  wire [DW-1:0] reg_wdata;
  wire [DW-1:0] reg_rdata;
  wire          reg_err;

  apb_slave #(
    .AW          (AW),
    .DW          (DW),
    .WAIT_STATES (WAIT_STATES)
  ) u_apb (
    .pclk        (pclk),
    .presetn     (presetn),
    .psel_i      (psel_i),
    .penable_i   (penable_i),
    .pwrite_i    (pwrite_i),
    .paddr_i     (paddr_i),
    .pwdata_i    (pwdata_i),
    .prdata_o    (prdata_o),
    .pready_o    (pready_o),
    .pslverr_o   (pslverr_o),
    .reg_we_o    (reg_we),
    .reg_re_o    (reg_re),
    .reg_addr_o  (reg_addr),
    .reg_wdata_o (reg_wdata),
    .reg_rdata_i (reg_rdata),
    .reg_err_i   (reg_err)
  );

  wire hit_ctrl   = (reg_addr == `UREG_CTRL);
  wire hit_baud   = (reg_addr == `UREG_BAUD);
  wire hit_status = (reg_addr == `UREG_STATUS);
  wire hit_txdata = (reg_addr == `UREG_TXDATA);
  wire hit_rxdata = (reg_addr == `UREG_RXDATA);
  wire hit_iclr   = (reg_addr == `UREG_ICLR);
  wire hit_id     = (reg_addr == `UREG_ID);
  wire mapped    = hit_ctrl | hit_baud | hit_status | hit_txdata |  hit_rxdata | hit_iclr | hit_id;
  wire read_only = hit_status | hit_rxdata | hit_id;
  wire bad_baud = pwrite_i && hit_baud && (pwdata_i[DIVW-1:0] < `UART_BAUD_MIN);

  assign reg_err = (!mapped) || (pwrite_i && read_only) || bad_baud;

  wire [2:0] reg_idx = hit_ctrl   ? 3'd0 :
                       hit_baud   ? 3'd1 :
                       hit_status ? 3'd2 :
                       hit_txdata ? 3'd3 :
                       hit_rxdata ? 3'd4 :
                       hit_iclr   ? 3'd5 :
                                    3'd6;
  wire core_we = reg_we && !reg_err;
  wire core_re = reg_re && !reg_err;
  wire [DW-1:0] core_rdata;

  uart_core #(
    .DIVW       (DIVW),
    .FIFO_DEPTH (FIFO_DEPTH),
    .OVERSAMPLE (OVERSAMPLE)
  ) u_core (
    .clk         (pclk),
    .rst_n       (presetn),
    .reg_we_i    (core_we),
    .reg_re_i    (core_re),
    .reg_idx_i   (reg_idx),
    .reg_wdata_i (reg_wdata),
    .reg_rdata_o (core_rdata),
    .rx_i        (rx_i),
    .tx_o        (tx_o),
    .irq_o       (irq_o)
  );
  assign reg_rdata = mapped ? core_rdata : {DW{1'b0}};

endmodule
