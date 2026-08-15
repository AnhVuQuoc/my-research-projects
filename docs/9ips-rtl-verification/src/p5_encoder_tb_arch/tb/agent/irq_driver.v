`timescale 1ns/1ps
`include "tb_defs.vh"

module irq_driver #(
  parameter N = `INTC_N
)(
  input  wire         clk,
  input  wire         rst_n,
  output reg  [N-1:0] irq_o
);

  integer style;
  integer seed;
  integer drv_events;

  initial begin
    irq_o      = {N{1'b0}};
    style      = `IRQ_ALIGNED;
    seed       = 32'h5EED_0005;
    drv_events = 0;
  end

  task set_style;
    input integer s;
    begin style = s; end
  endtask

  task set_seed;
    input integer s;
    begin seed = s; end
  endtask

  task wait_drive_point;
    integer off;
    begin
      @(negedge clk);
      case (style)
        `IRQ_SKEWED: begin
          off = $random(seed);
          if (off < 0) off = -off;
          #(off % `CLK_PERIOD);
        end
        `IRQ_HOSTILE: begin
          #((`CLK_PERIOD/2) - 1);
        end
        default: ;
      endcase
    end
  endtask
  task line_set;
    input integer id;
    reg [N-1:0] one;
    begin
      one = {{(N-1){1'b0}}, 1'b1};
      wait_drive_point;
      irq_o      = irq_o | (one << id);
      drv_events = drv_events + 1;
    end
  endtask

  task line_clr;
    input integer id;
    reg [N-1:0] one;
    begin
      one = {{(N-1){1'b0}}, 1'b1};
      wait_drive_point;
      irq_o      = irq_o & ~(one << id);
      drv_events = drv_events + 1;
    end
  endtask
  task line_pulse;
    input integer id;
    input integer cycles;
    integer c;
    begin
      line_set(id);
      for (c = 0; c < cycles; c = c + 1) @(posedge clk);
      line_clr(id);
    end
  endtask
  task lines_drive;
    input [N-1:0] v;
    begin
      wait_drive_point;
      irq_o      = v;
      drv_events = drv_events + 1;
    end
  endtask

  task lines_pulse;
    input [N-1:0] v;
    input integer cycles;
    integer c;
    begin
      lines_drive(v);
      for (c = 0; c < cycles; c = c + 1) @(posedge clk);
      lines_drive({N{1'b0}});
    end
  endtask

  task idle;
    input integer cycles;
    integer c;
    begin
      for (c = 0; c < cycles; c = c + 1) @(posedge clk);
    end
  endtask

endmodule
