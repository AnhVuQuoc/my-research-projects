`timescale 1ns/1ps
`include "uart_defs.vh"

module uart_tx (
  input  wire       clk,
  input  wire       rst_n,

  input  wire       en_i,
  input  wire       bit_tick_i,
  input  wire       par_en_i,
  input  wire       par_odd_i,
  input  wire       stop2_i,

  input  wire       start_i,
  input  wire [7:0] data_i,
  output reg        busy_o,
  output reg        done_o,

  output reg        tx_o
);

  localparam S_IDLE  = 3'd0;
  localparam S_START = 3'd1;
  localparam S_DATA  = 3'd2;
  localparam S_PAR   = 3'd3;
  localparam S_STOP1 = 3'd4;
  localparam S_STOP2 = 3'd5;

  reg [2:0] state;
  reg [7:0] sh;
  reg [2:0] bitn;
  reg       par;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state  <= S_IDLE;
      sh     <= 8'd0;
      bitn   <= 3'd0;
      par    <= 1'b0;
      tx_o   <= 1'b1;
      busy_o <= 1'b0;
      done_o <= 1'b0;
    end else begin
      done_o <= 1'b0;

      if (!en_i) begin
        state  <= S_IDLE;
        tx_o   <= 1'b1;
        busy_o <= 1'b0;
      end else begin
        case (state)
          S_IDLE: begin
            tx_o   <= 1'b1;
            busy_o <= 1'b0;
            if (start_i) begin
              sh     <= data_i;
              par    <= ^data_i;
              bitn   <= 3'd0;
              busy_o <= 1'b1;
              state  <= S_START;
            end
          end
          S_START: if (bit_tick_i) begin
            tx_o  <= 1'b0;
            state <= S_DATA;
          end

          S_DATA: if (bit_tick_i) begin
            tx_o <= sh[0];
            sh   <= {1'b0, sh[7:1]};
            if (bitn == 3'd7) state <= par_en_i ? S_PAR : S_STOP1;
            else bitn  <= bitn + 3'd1;
          end

          S_PAR: if (bit_tick_i) begin
            tx_o  <= par_odd_i ? ~par : par;
            state <= S_STOP1;
          end

          S_STOP1: if (bit_tick_i) begin
            tx_o  <= 1'b1;
            state <= stop2_i ? S_STOP2 : S_IDLE;
            if (!stop2_i) begin
              busy_o <= 1'b0;
              done_o <= 1'b1;
            end
          end

          S_STOP2: if (bit_tick_i) begin
            tx_o   <= 1'b1;
            busy_o <= 1'b0;
            done_o <= 1'b1;
            state  <= S_IDLE;
          end

          default: state <= S_IDLE;
        endcase
      end
    end
  end

endmodule
