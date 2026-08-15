`timescale 1ns/1ps
`include "tb_defs.vh"

module cpu_model #(
  parameter N = `INTC_N,
  parameter W = `INTC_W
)(
  input  wire         clk,
  input  wire         rst_n,
  output wire [N-1:0] irq_o,
  output wire         cfg_we_o,
  output wire         cfg_re_o,
  output wire [1:0]   cfg_addr_o,
  output wire [N-1:0] cfg_wdata_o,
  output wire         iack_o,
  input  wire [N-1:0] cfg_rdata_i,
  input  wire         irq_i,
  input  wire [W-1:0] irq_id_i
);

  integer seed;
  integer n_scenarios;

  initial begin
    seed        = 32'hC0FF_EE01;
    n_scenarios = 0;
  end

  task set_seed;
    input integer s;
    begin
      seed = s;
      u_irqdrv.set_seed(s ^ 32'h9E37_79B9);
    end
  endtask

  task set_irq_style;
    input integer st;
    begin u_irqdrv.set_style(st); end
  endtask

  irq_driver #(.N(N)) u_irqdrv (
    .clk   (clk),
    .rst_n (rst_n),
    .irq_o (irq_o)
  );

  cpu_driver #(.N(N)) u_cpudrv (
    .clk         (clk),
    .rst_n       (rst_n),
    .cfg_we_o    (cfg_we_o),
    .cfg_re_o    (cfg_re_o),
    .cfg_addr_o  (cfg_addr_o),
    .cfg_wdata_o (cfg_wdata_o),
    .iack_o      (iack_o),
    .cfg_rdata_i (cfg_rdata_i),
    .irq_i       (irq_i),
    .irq_id_i    (irq_id_i)
  );

  task set_mask;
    input [N-1:0] m;
    begin u_cpudrv.write_reg(`ADDR_MASK, m); end
  endtask

  task enable_all;
    begin set_mask({N{1'b1}}); end
  endtask

  task read_mask; begin u_cpudrv.read_reg(`ADDR_MASK); end endtask
  task read_pend; begin u_cpudrv.read_reg(`ADDR_PEND); end endtask
  task read_isr;  begin u_cpudrv.read_reg(`ADDR_ISR);  end endtask

  task arrive;
    input integer id;
    begin u_irqdrv.line_pulse(id, 2); end
  endtask

  task arrive_hold;
    input integer id;
    begin u_irqdrv.line_set(id); end
  endtask

  task depart;
    input integer id;
    begin u_irqdrv.line_clr(id); end
  endtask

  task idle;
    input integer cycles;
    begin u_cpudrv.idle(cycles); end
  endtask

  task ack; begin u_cpudrv.ack; end endtask
  task eoi; begin u_cpudrv.eoi; end endtask

  task service_one;
    input integer max_wait;
    input integer work_cycles;
    begin
      u_cpudrv.wait_irq(max_wait);
      if (u_cpudrv.wait_ok) begin
        u_cpudrv.ack;
        u_cpudrv.idle(work_cycles);
        u_cpudrv.eoi;
      end
      n_scenarios = n_scenarios + 1;
    end
  endtask

  task isr_flow;
    input integer id;
    input integer work_cycles;
    begin
      arrive(id);
      service_one(50, work_cycles);
    end
  endtask

  task nested_pair;
    input integer id_lo;
    input integer id_hi;
    input integer work_cycles;
    begin
      arrive(id_lo);
      u_cpudrv.wait_irq(50);
      u_cpudrv.ack;
      u_cpudrv.idle(2);
      arrive(id_hi);
      u_cpudrv.wait_irq(50);
      u_cpudrv.ack;
      u_cpudrv.idle(work_cycles);
      u_cpudrv.eoi;
      u_cpudrv.idle(work_cycles);
      u_cpudrv.eoi;
      n_scenarios = n_scenarios + 1;
    end
  endtask

  task nested_deep;
    input integer depth;
    input integer work_cycles;
    integer d;
    begin
      for (d = 0; d < depth; d = d + 1) begin
        arrive(d);
        u_cpudrv.wait_irq(50);
        u_cpudrv.ack;
        u_cpudrv.idle(work_cycles);
      end
      for (d = 0; d < depth; d = d + 1) begin
        u_cpudrv.eoi;
        u_cpudrv.idle(work_cycles);
      end
      n_scenarios = n_scenarios + 1;
    end
  endtask

  task storm;
    input [N-1:0] vec;
    input integer work_cycles;
    integer guard;
    begin
      u_irqdrv.lines_pulse(vec, 2);
      guard = 0;
      u_cpudrv.wait_irq(30);
      while (u_cpudrv.wait_ok && (guard < 2*N)) begin
        u_cpudrv.ack;
        u_cpudrv.idle(work_cycles);
        u_cpudrv.eoi;
        guard = guard + 1;
        u_cpudrv.wait_irq(20);
      end
      n_scenarios = n_scenarios + 1;
    end
  endtask

  task drain;
    input integer max_iter;
    integer g;
    begin
      for (g = 0; g < max_iter; g = g + 1) begin
        u_cpudrv.wait_irq(10);
        if (u_cpudrv.wait_ok) begin
          u_cpudrv.ack;
          u_cpudrv.eoi;
        end
      end
      u_cpudrv.idle(10);
    end
  endtask

  task arrive_colliding_with_ack;
    input integer id;
    begin
      u_irqdrv.line_clr(id); 
      @(posedge clk);
      u_irqdrv.line_set(id);
      @(posedge clk);
      @(posedge clk); 
      u_cpudrv.ack;
      n_scenarios = n_scenarios + 1;
    end
  endtask

  task narrow_pulse;
    input integer id;
    begin
      u_irqdrv.line_set(id);
      @(posedge clk);
      u_irqdrv.line_clr(id);
      n_scenarios = n_scenarios + 1;
    end
  endtask

  task random_traffic;
    input integer n;
    integer t, op, id, r;
    reg [31:0]  rv;
    reg [N-1:0] vec;
    begin
      for (t = 0; t < n; t = t + 1) begin
        r  = $random(seed);
        if (r < 0) r = -r;
        rv = r;
        op = r % 100;
        id = (r / 100) % N;

        if (op < 30) begin
          arrive(id); 
        end else if (op < 45) begin
          u_cpudrv.wait_irq(4);
          if (u_cpudrv.wait_ok) u_cpudrv.ack;
        end else if (op < 60) begin
          u_cpudrv.eoi;
        end else if (op < 70) begin
          u_cpudrv.idle(1 + (r % 5));
        end else if (op < 78) begin
          vec = rv[N-1:0];
          u_irqdrv.lines_pulse(vec, 2);
        end else if (op < 86) begin
          set_mask(rv[N-1:0]);
        end else if (op < 92) begin
          u_cpudrv.read_reg(rv[1:0]);
        end else if (op < 96) begin
          u_cpudrv.ack_and_eoi;
        end else begin
          u_cpudrv.ack_and_write(`ADDR_MASK, rv[N-1:0]);
        end
      end
      n_scenarios = n_scenarios + 1;
    end
  endtask

  task run_pattern;
    input integer pat;
    input integer n;
    integer t;
    begin
      case (pat)
        `PAT_SINGLE:   for (t = 0; t < n; t = t + 1) isr_flow(t % N, 3);
        `PAT_NESTED:   for (t = 0; t < n; t = t + 1) nested_pair(t % 4, 4 + (t % 4), 3);
        `PAT_STORM:    for (t = 0; t < n; t = t + 1) storm({N{1'b1}}, 2);
        `PAT_ISR_FLOW: for (t = 0; t < n; t = t + 1) isr_flow((t*3) % N, 1 + (t % 6));
        default:       random_traffic(n);
      endcase
    end
  endtask

endmodule
