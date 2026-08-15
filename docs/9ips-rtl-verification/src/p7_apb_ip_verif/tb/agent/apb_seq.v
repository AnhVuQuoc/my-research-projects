`timescale 1ns/1ps
`include "tb_defs.vh"

module apb_seq #(
  parameter N  = `APB_INTC_N,
  parameter AW = `APB_AW,
  parameter DW = `APB_DW
)(
  input  wire          pclk,
  input  wire          presetn,
  output wire          psel_o,
  output wire          penable_o,
  output wire          pwrite_o,
  output wire [AW-1:0] paddr_o,
  output wire [DW-1:0] pwdata_o,
  input  wire [DW-1:0] prdata_i,
  input  wire          pready_i,
  input  wire          pslverr_i,
  output wire [N-1:0]  irq_o,
  output reg           iack_o,
  input  wire          irq_i
);

  integer seed;

  initial begin
    iack_o = 1'b0;
    seed   = 32'hA9B8_C7D6;
  end
  apb_master_bfm #(.AW(AW), .DW(DW)) m (
    .pclk      (pclk),
    .presetn   (presetn),
    .psel_o    (psel_o),
    .penable_o (penable_o),
    .pwrite_o  (pwrite_o),
    .paddr_o   (paddr_o),
    .pwdata_o  (pwdata_o),
    .prdata_i  (prdata_i),
    .pready_i  (pready_i),
    .pslverr_i (pslverr_i)
  );

  irq_driver #(.N(N)) u_irq (
    .clk   (pclk),
    .rst_n (presetn),
    .irq_o (irq_o)
  );
  task set_seed;
    input integer s;
    begin
      seed = s;
      u_irq.set_seed(s ^ 32'h1357_9BDF);
    end
  endtask

  task set_irq_style;
    input integer st;
    begin u_irq.set_style(st); end
  endtask

  task wr;  input [AW-1:0] a; input [DW-1:0] d; begin m.write(a, d); end endtask
  task rd;  input [AW-1:0] a;                   begin m.read(a);     end endtask
  task idle; input integer c;                   begin m.idle(c);     end endtask

  task arrive;      input integer id; begin u_irq.line_pulse(id, 2); end endtask
  task arrive_hold; input integer id; begin u_irq.line_set(id);      end endtask
  task depart;      input integer id; begin u_irq.line_clr(id);      end endtask
  task ack;
    begin
      @(negedge pclk);
      iack_o = 1'b1;
      @(negedge pclk);
      iack_o = 1'b0;
    end
  endtask

  reg wait_ok;

  task wait_irq;
    input integer max_cycles;
    integer c;
    begin
      wait_ok = 1'b0;
      for (c = 0; c < max_cycles; c = c + 1) begin
        @(posedge pclk);
        if (irq_i) begin
          wait_ok = 1'b1;
          c = max_cycles;
        end
      end
    end
  task enable_all;  begin m.write(`REG_MASK, {{(DW-N){1'b0}}, {N{1'b1}}}); end endtask
  task disable_all; begin m.write(`REG_MASK, {DW{1'b0}}); end endtask
  task isr_flow;
    input integer id;
    input integer work;
    begin
      arrive(id);
      wait_irq(60);
      if (wait_ok) begin
        ack;
        m.idle(work);
        m.write(`REG_EOI, {DW{1'b0}});
      end
    end
  endtask
  task nest_build;
    input integer depth;
    integer d;
    begin
      for (d = 0; d < depth; d = d + 1) begin
        arrive(d);
        wait_irq(60);
        if (wait_ok) ack;
        m.idle(1);
      end
    end
  endtask

  task nest_unwind;
    input integer depth;
    integer d;
    begin
      for (d = 0; d < depth; d = d + 1) begin
        m.write(`REG_EOI, {DW{1'b0}});
        m.idle(1);
      end
    end
  endtask

  task drain_all;
    begin
      m.write(`REG_CMD, `CMD_DRAIN);
      m.idle(N + 4);
    end
  endtask
  task random_traffic;
    input integer n;
    input integer profile;
    integer t, op, id, r;
    reg [31:0] rv;
    begin
      for (t = 0; t < n; t = t + 1) begin
        r  = $random(seed);
        if (r < 0) r = -r;
        rv = r;
        op = r % 100;
        id = (r / 100) % N;

        case (profile)
          `PROF_REG: begin
            if      (op < 30) m.write(`REG_MASK, {24'd0, rv[7:0]});
            else if (op < 55) m.read (`REG_MASK);
            else if (op < 70) m.read (`REG_PEND);
            else if (op < 85) m.read (`REG_ISR);
            else if (op < 95) m.read (`REG_ID);
            else              m.read (`REG_STATUS);
          end

          `PROF_IRQ: begin
            if      (op < 45) arrive(id);
            else if (op < 65) begin wait_irq(3); if (wait_ok) ack; end
            else if (op < 85) m.write(`REG_EOI, {DW{1'b0}});
            else              m.idle(1 + (op % 4));
          end

          `PROF_ERROR: begin
            if      (op < 25) m.write(`REG_PEND, rv);
            else if (op < 45) m.write(`REG_ISR,  rv);
            else if (op < 60) m.write(`REG_ID,   rv);
            else if (op < 75) m.write(`REG_CMD,  32'd99);
            else if (op < 90) m.read ({1'b1, rv[6:0]});
            else              m.write({1'b1, rv[6:0]}, rv);
          end

          default: begin
            if      (op < 20) arrive(id);
            else if (op < 32) begin wait_irq(3); if (wait_ok) ack; end
            else if (op < 42) m.write(`REG_EOI, {DW{1'b0}});
            else if (op < 52) m.write(`REG_MASK, {24'd0, rv[7:0]});
            else if (op < 62) m.read (`REG_PEND);
            else if (op < 70) m.read (`REG_ISR);
            else if (op < 76) m.read (`REG_STATUS);
            else if (op < 82) m.read (`REG_ID);
            else if (op < 86) m.write(`REG_PEND, rv);
            else if (op < 90) m.read ({1'b1, rv[6:0]});
            else if (op < 93) m.write(`REG_CMD, `CMD_ENABLE_ALL);
            else if (op < 95) m.write(`REG_CMD, `CMD_DISABLE_ALL);
            else if (op < 97) m.write(`REG_CMD, `CMD_DRAIN);
            else if (op < 99) m.write_b2b(`REG_MASK, {24'd0, rv[7:0]},
                                          `REG_MASK, {24'd0, rv[15:8]});
            else              m.idle(1 + (op % 5));
          end
        endcase
      end
    end
  endtask

endmodule
