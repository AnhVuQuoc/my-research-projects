`timescale 1ns/1ps
`include "uart_defs.vh"

module uart_core #(
  parameter DIVW       = 16,
  parameter FIFO_DEPTH = `UART_FIFO_DEPTH,
  parameter OVERSAMPLE = `UART_OVERSAMPLE
)(
  input  wire            clk,
  input  wire            rst_n,

  input  wire            reg_we_i,
  input  wire            reg_re_i,
  input  wire [2:0]      reg_idx_i,
  input  wire [31:0]     reg_wdata_i,
  output reg  [31:0]     reg_rdata_o,
  input  wire            rx_i,
  output wire            tx_o,
  output wire            irq_o
);
  localparam IDX_CTRL   = 3'd0;
  localparam IDX_BAUD   = 3'd1;
  localparam IDX_STATUS = 3'd2;
  localparam IDX_TXDATA = 3'd3;
  localparam IDX_RXDATA = 3'd4;
  localparam IDX_ICLR   = 3'd5;
  localparam IDX_ID     = 3'd6;

  reg [`CTRL_WIDTH-1:0] ctrl_q;
  reg [DIVW-1:0]        baud_q;

  wire en       = ctrl_q[`CTRL_EN];
  wire par_en   = ctrl_q[`CTRL_PAR_EN];
  wire par_odd  = ctrl_q[`CTRL_PAR_ODD];
  wire stop2    = ctrl_q[`CTRL_STOP2];
  wire loopback = ctrl_q[`CTRL_LOOPBACK];
  wire irq_en   = ctrl_q[`CTRL_IRQ_EN];

  localparam [DIVW-1:0] BAUD_MIN_C = `UART_BAUD_MIN;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ctrl_q <= {`CTRL_WIDTH{1'b0}};
      baud_q <= BAUD_MIN_C;
    end else begin
      if (reg_we_i && (reg_idx_i == IDX_CTRL)) ctrl_q <= reg_wdata_i[`CTRL_WIDTH-1:0];
      if (reg_we_i && (reg_idx_i == IDX_BAUD)) baud_q <= (reg_wdata_i[DIVW-1:0] < BAUD_MIN_C) ? BAUD_MIN_C : reg_wdata_i[DIVW-1:0];
    end
  end

  wire rx_restart, bit_tick, os_tick;

  baud_gen #(.DIVW(DIVW), .OVERSAMPLE(OVERSAMPLE)) u_baud (
    .clk          (clk),
    .rst_n        (rst_n),
    .en_i         (en),
    .div_i        (baud_q),
    .rx_restart_i (rx_restart),
    .bit_tick_o   (bit_tick),
    .os_tick_o    (os_tick)
  );
  wire       tx_fifo_empty, tx_fifo_full, tx_ovf;
  wire [7:0] tx_fifo_data;
  wire [2:0] tx_fifo_count;
  wire       tx_busy, tx_done;

  wire tx_push = reg_we_i && (reg_idx_i == IDX_TXDATA);
  wire tx_start = en && !tx_busy && !tx_fifo_empty;

  sync_fifo #(.WIDTH(8), .DEPTH(FIFO_DEPTH)) u_txfifo (
    .clk        (clk),
    .rst_n      (rst_n),
    .wr_i       (tx_push),
    .wdata_i    (reg_wdata_i[7:0]),
    .rd_i       (tx_start),
    .rdata_o    (tx_fifo_data),
    .empty_o    (tx_fifo_empty),
    .full_o     (tx_fifo_full),
    .count_o    (tx_fifo_count),
    .overflow_o (tx_ovf)
  );

  uart_tx u_tx (
    .clk        (clk),
    .rst_n      (rst_n),
    .en_i       (en),
    .bit_tick_i (bit_tick),
    .par_en_i   (par_en),
    .par_odd_i  (par_odd),
    .stop2_i    (stop2),
    .start_i    (tx_start),
    .data_i     (tx_fifo_data),
    .busy_o     (tx_busy),
    .done_o     (tx_done),
    .tx_o       (tx_o)
  );
  wire rx_pin = loopback ? tx_o : rx_i;

  reg s0, s1;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin s0 <= 1'b1; s1 <= 1'b1; end
    else        begin s0 <= rx_pin; s1 <= s0; end
  end

  wire       rx_valid, rx_err_frame, rx_err_parity;
  wire [7:0] rx_byte;

  uart_rx #(.OVERSAMPLE(OVERSAMPLE)) u_rx (
    .clk          (clk),
    .rst_n        (rst_n),
    .en_i         (en),
    .os_tick_i    (os_tick),
    .par_en_i     (par_en),
    .par_odd_i    (par_odd),
    .stop2_i      (stop2),
    .rx_i         (s1),
    .restart_o    (rx_restart),
    .valid_o      (rx_valid),
    .data_o       (rx_byte),
    .err_frame_o  (rx_err_frame),
    .err_parity_o (rx_err_parity)
  );

  wire       rx_fifo_empty, rx_fifo_full, rx_ovf;
  wire [7:0] rx_fifo_data;
  wire [2:0] rx_fifo_count;

  wire rx_pop = reg_re_i && (reg_idx_i == IDX_RXDATA) && !rx_fifo_empty;

  sync_fifo #(.WIDTH(8), .DEPTH(FIFO_DEPTH)) u_rxfifo (
    .clk        (clk),
    .rst_n      (rst_n),
    .wr_i       (rx_valid),
    .wdata_i    (rx_byte),
    .rd_i       (rx_pop),
    .rdata_o    (rx_fifo_data),
    .empty_o    (rx_fifo_empty),
    .full_o     (rx_fifo_full),
    .count_o    (rx_fifo_count),
    .overflow_o (rx_ovf)
  );
  reg err_frame_q, err_parity_q, err_overrun_q;

  wire iclr_we = reg_we_i && (reg_idx_i == IDX_ICLR);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      err_frame_q   <= 1'b0;
      err_parity_q  <= 1'b0;
      err_overrun_q <= 1'b0;
    end else begin
      if (iclr_we && reg_wdata_i[`ICLR_FRAME])   err_frame_q   <= 1'b0;
      if (iclr_we && reg_wdata_i[`ICLR_PARITY])  err_parity_q  <= 1'b0;
      if (iclr_we && reg_wdata_i[`ICLR_OVERRUN]) err_overrun_q <= 1'b0;

      if (rx_err_frame)  err_frame_q   <= 1'b1;
      if (rx_err_parity) err_parity_q  <= 1'b1;
      if (rx_ovf)        err_overrun_q <= 1'b1;
    end
  end

  wire [`ST_WIDTH-1:0] status_word = {
    err_overrun_q,
    err_parity_q,
    err_frame_q,
    tx_busy,
    rx_fifo_full,
    rx_fifo_empty,
    tx_fifo_full,
    tx_fifo_empty
  };

  always @* begin
    case (reg_idx_i)
      IDX_CTRL:   reg_rdata_o = {{(32-`CTRL_WIDTH){1'b0}}, ctrl_q};
      IDX_BAUD:   reg_rdata_o = {{(32-DIVW){1'b0}}, baud_q};
      IDX_STATUS: reg_rdata_o = {{(32-`ST_WIDTH){1'b0}}, status_word};
      IDX_RXDATA: reg_rdata_o = {24'd0, rx_fifo_data};
      IDX_ID:     reg_rdata_o = `UART_ID_VALUE;
      default:    reg_rdata_o = 32'd0;
    endcase
  end
  assign irq_o = irq_en && (!rx_fifo_empty || err_frame_q || err_parity_q || err_overrun_q);

endmodule
