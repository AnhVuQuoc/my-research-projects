`timescale 1ns/1ps
`include "uart_defs.vh"

module uart_rx #(
  parameter OVERSAMPLE = `UART_OVERSAMPLE
)(
  input  wire       clk,
  input  wire       rst_n,

  input  wire       en_i,
  input  wire       os_tick_i,
  input  wire       par_en_i,
  input  wire       par_odd_i,
  input  wire       stop2_i,

  input  wire       rx_i,

  output reg        restart_o,
  output reg        valid_o,
  output reg  [7:0] data_o,
  output reg        err_frame_o,
  output reg        err_parity_o
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

  localparam [OSW-1:0] OS_LAST = OVERSAMPLE - 1;

  localparam S_IDLE  = 3'd0;
  localparam S_START = 3'd1;
  localparam S_DATA  = 3'd2;
  localparam S_PAR   = 3'd3;
  localparam S_STOP1 = 3'd4;
  localparam S_STOP2 = 3'd5;

  reg [2:0]     state;
  reg [OSW-1:0] os_cnt;
  reg [2:0]     bitn;
  reg [7:0]     sh;
  reg           par;
  reg           rx_d;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state        <= S_IDLE;
      os_cnt       <= {OSW{1'b0}};
      bitn         <= 3'd0;
      sh           <= 8'd0;
      par          <= 1'b0;
      rx_d         <= 1'b1;
      restart_o    <= 1'b0;
      valid_o      <= 1'b0;
      data_o       <= 8'd0;
      err_frame_o  <= 1'b0;
      err_parity_o <= 1'b0;
    end else begin
      restart_o    <= 1'b0;
      valid_o      <= 1'b0;
      err_frame_o  <= 1'b0;
      err_parity_o <= 1'b0;
      rx_d         <= rx_i;

      if (!en_i) begin
        state <= S_IDLE;
      end else begin
        case (state)
          S_IDLE: begin
            if (rx_d && !rx_i) begin
              restart_o <= 1'b1;
              os_cnt    <= {OSW{1'b0}};
              state     <= S_START;
            end
          end
          S_START: if (os_tick_i) begin
            if (rx_i) begin
              state <= S_IDLE;
            end else begin
              os_cnt <= {OSW{1'b0}};
              bitn   <= 3'd0;
              par    <= 1'b0;
              state  <= S_DATA;
            end
          end
          S_DATA: if (os_tick_i) begin
            os_cnt <= os_cnt + {{(OSW-1){1'b0}}, 1'b1};
            if (os_cnt == OS_LAST) begin
              sh  <= {rx_i, sh[7:1]};
              par <= par ^ rx_i;
              if (bitn == 3'd7) state <= par_en_i ? S_PAR : S_STOP1;
              else              bitn  <= bitn + 3'd1;
            end
          end
          S_PAR: if (os_tick_i) begin
            os_cnt <= os_cnt + {{(OSW-1){1'b0}}, 1'b1};
            if (os_cnt == OS_LAST) begin
              if (rx_i !== (par_odd_i ? ~par : par))
                err_parity_o <= 1'b1;
              state <= S_STOP1;
            end
          end
          S_STOP1: if (os_tick_i) begin
            os_cnt <= os_cnt + {{(OSW-1){1'b0}}, 1'b1};
            if (os_cnt == OS_LAST) begin
              if (!rx_i) begin
                err_frame_o <= 1'b1;
                state       <= S_IDLE;
              end else if (stop2_i) begin
                state <= S_STOP2;
              end else begin
                data_o  <= sh;
                valid_o <= 1'b1;
                state   <= S_IDLE;
              end
            end
          end

          S_STOP2: if (os_tick_i) begin
            os_cnt <= os_cnt + {{(OSW-1){1'b0}}, 1'b1};
            if (os_cnt == OS_LAST) begin
              if (!rx_i) begin
                err_frame_o <= 1'b1;
              end else begin
                data_o  <= sh;
                valid_o <= 1'b1;
              end
              state <= S_IDLE;
            end
          end

          default: state <= S_IDLE;
        endcase
      end
    end
  end

endmodule
