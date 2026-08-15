`timescale 1ns/1ps
`include "tb_defs.vh"

module rx_predictor (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        rx_i,
  input  wire [15:0] cfg_div_i,
  input  wire        cfg_par_en_i,
  input  wire        cfg_par_odd_i,
  input  wire        cfg_stop2_i,
  input  wire        cfg_en_i,
  output reg         pred_vld_o,
  output reg  [7:0]  pred_data_o,
  output reg         pred_frame_o,
  output reg         pred_parity_o
);

  reg s0, s1, s1d;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin s0 <= 1'b1; s1 <= 1'b1; s1d <= 1'b1; end
    else        begin s0 <= rx_i; s1 <= s0; s1d <= s1; end
  end

  wire falling = s1d & ~s1;

  localparam P_IDLE  = 3'd0;
  localparam P_START = 3'd1;
  localparam P_DATA  = 3'd2;
  localparam P_PAR   = 3'd3;
  localparam P_STOP1 = 3'd4;
  localparam P_STOP2 = 3'd5;

  reg [2:0]  state;
  reg [15:0] cnt;
  reg [2:0]  bitn;
  reg [7:0]  sh;
  reg        par;

  wire [15:0] half = {1'b0, cfg_div_i[15:1]};

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state        <= P_IDLE;
      cnt          <= 16'd0;
      bitn         <= 3'd0;
      sh           <= 8'd0;
      par          <= 1'b0;
      pred_vld_o   <= 1'b0;
      pred_data_o  <= 8'd0;
      pred_frame_o <= 1'b0;
      pred_parity_o<= 1'b0;
    end else begin
      pred_vld_o    <= 1'b0;
      pred_frame_o  <= 1'b0;
      pred_parity_o <= 1'b0;

      if (!cfg_en_i) begin
        state <= P_IDLE;
      end else begin
        case (state)
          P_IDLE: if (falling) begin
            cnt   <= half;
            state <= P_START;
          end
		  
          P_START: if (cnt == 16'd0) begin
            if (s1) begin
              state <= P_IDLE;
            end else begin
              cnt   <= cfg_div_i;
              bitn  <= 3'd0;
              par   <= 1'b0;
              state <= P_DATA;
            end
          end else cnt <= cnt - 16'd1;

          P_DATA: if (cnt == 16'd0) begin
            sh  <= {s1, sh[7:1]};
            par <= par ^ s1;
            cnt <= cfg_div_i;
            if (bitn == 3'd7) state <= cfg_par_en_i ? P_PAR : P_STOP1;
            else              bitn  <= bitn + 3'd1;
          end else cnt <= cnt - 16'd1;

          P_PAR: if (cnt == 16'd0) begin
            if (s1 !== (cfg_par_odd_i ? ~par : par))
              pred_parity_o <= 1'b1;
            cnt   <= cfg_div_i;
            state <= P_STOP1;
          end else cnt <= cnt - 16'd1;

          P_STOP1: if (cnt == 16'd0) begin
            if (!s1) begin
              pred_frame_o <= 1'b1;
              state        <= P_IDLE;
            end else if (cfg_stop2_i) begin
              cnt   <= cfg_div_i;
              state <= P_STOP2;
            end else begin
              pred_data_o <= sh;
              pred_vld_o  <= 1'b1;
              state       <= P_IDLE;
            end
          end else cnt <= cnt - 16'd1;

          P_STOP2: if (cnt == 16'd0) begin
            if (!s1) pred_frame_o <= 1'b1;
            else begin
              pred_data_o <= sh;
              pred_vld_o  <= 1'b1;
            end
            state <= P_IDLE;
          end else cnt <= cnt - 16'd1;

          default: state <= P_IDLE;
        endcase
      end
    end
  end

endmodule
