`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module byte_scoreboard #(
  parameter DEPTH = 256
)(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        tx_push_i,
  input  wire [7:0]  tx_push_data_i,
  input  wire        tx_wire_i,
  input  wire [7:0]  tx_wire_data_i,
  input  wire        rx_pred_i,
  input  wire [7:0]  rx_pred_data_i,
  input  wire        rx_read_i,
  input  wire [7:0]  rx_read_data_i,
  output reg  [31:0] n_tx_checked_o,
  output reg  [31:0] n_tx_mismatch_o,
  output reg  [31:0] n_rx_checked_o,
  output reg  [31:0] n_rx_mismatch_o
);

  reg [7:0] txq [0:DEPTH-1];
  reg [7:0] rxq [0:DEPTH-1];
  integer   tx_head, tx_n;
  integer   rx_head, rx_n;

  integer i;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_head = 0; tx_n = 0;
      rx_head = 0; rx_n = 0;
      n_tx_checked_o  <= 32'd0;
      n_tx_mismatch_o <= 32'd0;
      n_rx_checked_o  <= 32'd0;
      n_rx_mismatch_o <= 32'd0;
      for (i = 0; i < DEPTH; i = i + 1) begin
        txq[i] = 8'd0; rxq[i] = 8'd0;
      end
    end else begin
      if (tx_push_i) begin
        if (tx_n < DEPTH) begin
          txq[(tx_head + tx_n) % DEPTH] = tx_push_data_i;
          tx_n = tx_n + 1;
        end else begin
          $display("[%0t] ERROR byte_scoreboard TX queue overflow", $time);
          n_tx_mismatch_o <= n_tx_mismatch_o + 32'd1;
        end
      end
      if (tx_wire_i) begin
        n_tx_checked_o <= n_tx_checked_o + 32'd1;
        if (tx_n == 0) begin
          $display("[%0t] ERROR tx wire byte 0x%02x with nothing queued", $time, tx_wire_data_i);
          n_tx_mismatch_o <= n_tx_mismatch_o + 32'd1;
        end else begin
          if (tx_wire_data_i !== txq[tx_head]) begin
            $display("[%0t] ERROR tx mismatch: wire 0x%02x expected 0x%02x", $time, tx_wire_data_i, txq[tx_head]);
            n_tx_mismatch_o <= n_tx_mismatch_o + 32'd1;
          end
          tx_head = (tx_head + 1) % DEPTH;
          tx_n    = tx_n - 1;
        end
      end
      if (rx_pred_i) begin
        if (rx_n < DEPTH) begin
          rxq[(rx_head + rx_n) % DEPTH] = rx_pred_data_i;
          rx_n = rx_n + 1;
        end
      end
      if (rx_read_i) begin
        n_rx_checked_o <= n_rx_checked_o + 32'd1;
        if (rx_n == 0) begin
          $display("[%0t] ERROR rx read 0x%02x with nothing predicted", $time, rx_read_data_i);
          n_rx_mismatch_o <= n_rx_mismatch_o + 32'd1;
        end else begin
          if (rx_read_data_i !== rxq[rx_head]) begin
            $display("[%0t] ERROR rx mismatch: read 0x%02x expected 0x%02x", $time, rx_read_data_i, rxq[rx_head]);
            n_rx_mismatch_o <= n_rx_mismatch_o + 32'd1;
          end
          rx_head = (rx_head + 1) % DEPTH;
          rx_n    = rx_n - 1;
        end
      end
    end
  end
  function integer tx_outstanding; input integer d; begin tx_outstanding = tx_n; end endfunction
  function integer rx_outstanding; input integer d; begin rx_outstanding = rx_n; end endfunction

  task resync_rx; begin rx_head = 0; rx_n = 0; end endtask

  task report;
    begin
      $display("byte scoreboard : TX %0d checked / %0d mismatch  |  RX %0d checked / %0d mismatch",
               n_tx_checked_o, n_tx_mismatch_o, n_rx_checked_o, n_rx_mismatch_o);
      if (tx_n != 0)
        $display("note: %0d TX bytes still queued (never reached the wire)", tx_n);
    end
  endtask

endmodule
