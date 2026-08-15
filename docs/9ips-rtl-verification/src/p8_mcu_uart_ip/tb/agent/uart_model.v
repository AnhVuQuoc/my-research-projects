`timescale 1ns/1ps
`include "tb_defs.vh"

module uart_model #(
  parameter DEPTH = `UART_FIFO_DEPTH
);
  reg [7:0]  tx_q [0:DEPTH-1];
  reg [7:0]  rx_q [0:DEPTH-1];
  integer    tx_n, rx_n;
  integer    tx_head, rx_head;

  reg [`CTRL_WIDTH-1:0] ctrl;
  reg [`U_DIVW-1:0]     baud;
  reg err_frame, err_parity, err_overrun;

  integer n_tx_pushed, n_tx_dropped, n_rx_pushed, n_rx_dropped, n_rx_popped;

  integer i;

  task reset_model;
    begin
      tx_n = 0; rx_n = 0; tx_head = 0; rx_head = 0;
      ctrl = 0;
      baud = `UART_BAUD_MIN;
      err_frame = 1'b0; err_parity = 1'b0; err_overrun = 1'b0;
      n_tx_pushed = 0; n_tx_dropped = 0;
      n_rx_pushed = 0; n_rx_dropped = 0; n_rx_popped = 0;
      for (i = 0; i < DEPTH; i = i + 1) begin
        tx_q[i] = 8'd0;
        rx_q[i] = 8'd0;
      end
    end
  endtask

  initial reset_model;
  
  task write_ctrl;
    input [31:0] d;
    begin ctrl = d[`CTRL_WIDTH-1:0]; end
  endtask

  task write_baud;
    input [31:0] d;
    begin

      baud = (d[`U_DIVW-1:0] < `UART_BAUD_MIN) ? `UART_BAUD_MIN
                                               : d[`U_DIVW-1:0];
    end
  endtask

  task push_tx;
    input [7:0] d;
    begin
      if (tx_n < DEPTH) begin
        tx_q[(tx_head + tx_n) % DEPTH] = d;
        tx_n        = tx_n + 1;
        n_tx_pushed = n_tx_pushed + 1;
      end else begin
        n_tx_dropped = n_tx_dropped + 1;
      end
    end
  endtask

  task pop_tx;
    begin
      if (tx_n > 0) begin
        tx_head = (tx_head + 1) % DEPTH;
        tx_n    = tx_n - 1;
      end
    end
  endtask

  task push_rx;
    input [7:0] d;
    begin
      if (rx_n < DEPTH) begin
        rx_q[(rx_head + rx_n) % DEPTH] = d;
        rx_n        = rx_n + 1;
        n_rx_pushed = n_rx_pushed + 1;
      end else begin
        err_overrun  = 1'b1;
        n_rx_dropped = n_rx_dropped + 1;
      end
    end
  endtask

  function [7:0] peek_rx;
    input integer dummy;
    begin
      peek_rx = (rx_n > 0) ? rx_q[rx_head] : 8'd0;
    end
  endfunction

  task pop_rx;
    begin
      if (rx_n > 0) begin
        rx_head     = (rx_head + 1) % DEPTH;
        rx_n        = rx_n - 1;
        n_rx_popped = n_rx_popped + 1;
      end
    end
  endtask

  task set_err_frame;  begin err_frame  = 1'b1; end endtask
  task set_err_parity; begin err_parity = 1'b1; end endtask

  task clear_errors;
    input [31:0] d;
    begin
      if (d[`ICLR_FRAME])   err_frame   = 1'b0;
      if (d[`ICLR_PARITY])  err_parity  = 1'b0;
      if (d[`ICLR_OVERRUN]) err_overrun = 1'b0;
    end
  endtask

  function [31:0] exp_ctrl;   input integer d; begin exp_ctrl = {{(32-`CTRL_WIDTH){1'b0}}, ctrl}; end endfunction
  function [31:0] exp_baud;   input integer d; begin exp_baud = {{(32-`U_DIVW){1'b0}}, baud}; end endfunction

  function [31:0] exp_status;
    input integer tx_busy;
    reg [`ST_WIDTH-1:0] s;
    begin
      s = 0;
      s[`ST_TX_EMPTY]    = (tx_n == 0);
      s[`ST_TX_FULL]     = (tx_n == DEPTH);
      s[`ST_RX_EMPTY]    = (rx_n == 0);
      s[`ST_RX_FULL]     = (rx_n == DEPTH);
      s[`ST_TX_BUSY]     = (tx_busy != 0);
      s[`ST_ERR_FRAME]   = err_frame;
      s[`ST_ERR_PARITY]  = err_parity;
      s[`ST_ERR_OVERRUN] = err_overrun;
      exp_status = {{(32-`ST_WIDTH){1'b0}}, s};
    end
  endfunction

  function [31:0] exp_irq;
    input integer d;
    begin
      exp_irq = (ctrl[`CTRL_IRQ_EN] && ((rx_n != 0) || err_frame || err_parity || err_overrun)) ? 32'd1 : 32'd0;
    end
  endfunction

  task report;
    begin
      $display("model: tx pushed=%0d dropped=%0d | rx pushed=%0d dropped=%0d popped=%0d",
               n_tx_pushed, n_tx_dropped, n_rx_pushed, n_rx_dropped, n_rx_popped);
    end
  endtask

endmodule
