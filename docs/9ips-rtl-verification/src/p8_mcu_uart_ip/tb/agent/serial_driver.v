`timescale 1ns/1ps
`include "tb_defs.vh"

module serial_driver (
  output reg line_o
);

  real bit_ns;
  integer style;
  integer n_frames;

  initial begin
    line_o   = 1'b1;      // idle high
    bit_ns   = `BAUD_DIV * `CLK_PERIOD;
    style    = `LINE_EXACT;
    n_frames = 0;
  end

  task set_bit_period_cycles;
    input integer div;
    begin bit_ns = div * `CLK_PERIOD; end
  endtask

  task set_style;
    input integer s;
    begin style = s; end
  endtask

  function real eff_period;
    input integer dummy;
    begin
      case (style)
        `LINE_FAST: eff_period = bit_ns * 0.97;
        `LINE_SLOW: eff_period = bit_ns * 1.03;
        default:    eff_period = bit_ns;
      endcase
    end
  endfunction

  task send_bit;
    input v;
    begin
      line_o = v;
      #(eff_period(0));
    end
  endtask

  task send_frame;
    input [7:0] data;
    input       par_en;
    input       par_odd;
    input       stop2;
    integer i;
    reg p;
    begin
      send_bit(1'b0);
      p = 1'b0;
      for (i = 0; i < 8; i = i + 1) begin
        send_bit(data[i]);
        p = p ^ data[i];
      end
      if (par_en) send_bit(par_odd ? ~p : p);
      send_bit(1'b1);
      if (stop2) send_bit(1'b1);
      n_frames = n_frames + 1;
    end
  endtask

  task send_frame_bad_stop;
    input [7:0] data;
    input       par_en;
    input       par_odd;
    integer i;
    reg p;
    begin
      send_bit(1'b0);
      p = 1'b0;
      for (i = 0; i < 8; i = i + 1) begin
        send_bit(data[i]);
        p = p ^ data[i];
      end
      if (par_en) send_bit(par_odd ? ~p : p);
      send_bit(1'b0);
      send_bit(1'b1);
      n_frames = n_frames + 1;
    end
  endtask

  task send_frame_bad_parity;
    input [7:0] data;
    input       par_odd;
    integer i;
    reg p;
    begin
      send_bit(1'b0);
      p = 1'b0;
      for (i = 0; i < 8; i = i + 1) begin
        send_bit(data[i]);
        p = p ^ data[i];
      end
      send_bit(par_odd ? p : ~p);
      send_bit(1'b1);
      n_frames = n_frames + 1;
    end
  endtask

  task send_glitch;
    input real ns;
    begin
      line_o = 1'b0;
      #(ns);
      line_o = 1'b1;
    end
  endtask

  task idle_bits;
    input integer n;
    integer i;
    begin
      line_o = 1'b1;
      for (i = 0; i < n; i = i + 1) #(eff_period(0));
    end
  endtask

endmodule
