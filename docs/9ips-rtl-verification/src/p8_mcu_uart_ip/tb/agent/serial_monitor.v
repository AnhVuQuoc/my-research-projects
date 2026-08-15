`timescale 1ns/1ps
`include "tb_defs.vh"

module serial_monitor (
  input  wire       line_i,
  output reg        byte_vld_o,
  output reg  [7:0] byte_o,
  output reg        par_bit_o,
  output reg        stop_ok_o,
  output reg [31:0] n_bytes_o
);

  real bit_ns;
  reg  par_en, par_odd, stop2;

  real t_start_edge;
  real measured_bit_ns;

  integer i;
  reg [7:0] acc;

  initial begin
    byte_vld_o      = 1'b0;
    byte_o          = 8'd0;
    par_bit_o       = 1'b0;
    stop_ok_o       = 1'b0;
    n_bytes_o       = 32'd0;
    bit_ns          = `BAUD_DIV * `CLK_PERIOD;
    par_en          = 1'b0;
    par_odd         = 1'b0;
    stop2           = 1'b0;
    measured_bit_ns = 0.0;
  end

  task configure;
    input integer div_cycles;
    input         pe;
    input         po;
    input         s2;
    begin
      bit_ns  = div_cycles * `CLK_PERIOD;
      par_en  = pe;
      par_odd = po;
      stop2   = s2;
    end
  endtask

  always begin
    byte_vld_o = 1'b0;

    @(negedge line_i);
    t_start_edge = $realtime;

    #(bit_ns * 1.5);

    acc = 8'd0;
    for (i = 0; i < 8; i = i + 1) begin
      acc[i] = line_i;
      if (i < 7) #(bit_ns);
    end

    #(bit_ns);
    if (par_en) begin
      par_bit_o = line_i;
      #(bit_ns);
    end

    stop_ok_o = line_i;

    byte_o     = acc;
    n_bytes_o  = n_bytes_o + 32'd1;
    byte_vld_o = 1'b1;
    measured_bit_ns = ($realtime - t_start_edge) /
                      (9.0 + (par_en ? 1.0 : 0.0));

    #(bit_ns / 4.0);
    byte_vld_o = 1'b0;
    if (!line_i) @(posedge line_i);
  end

  function real last_bit_period;
    input integer dummy;
    begin last_bit_period = measured_bit_ns; end
  endfunction

endmodule
