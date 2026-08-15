`timescale 1ns/1ps
`include "tb_defs.vh"

module cpu_driver #(
  parameter N = `INTC_N
)(
  input  wire         clk,
  input  wire         rst_n,
  output reg          cfg_we_o,
  output reg          cfg_re_o,
  output reg  [1:0]   cfg_addr_o,
  output reg  [N-1:0] cfg_wdata_o,
  output reg          iack_o,
  input  wire [N-1:0] cfg_rdata_i,
  input  wire         irq_i,
  input  wire [2:0]   irq_id_i
);

  reg [N-1:0] last_rdata;
  integer     n_writes, n_reads, n_acks, n_eois;

  initial begin
    cfg_we_o    = 1'b0;
    cfg_re_o    = 1'b0;
    cfg_addr_o  = 2'd0;
    cfg_wdata_o = {N{1'b0}};
    iack_o      = 1'b0;
    last_rdata  = {N{1'b0}};
    n_writes = 0; n_reads = 0; n_acks = 0; n_eois = 0;
  end

  task write_reg;
    input [1:0]   a;
    input [N-1:0] d;
    begin
      @(negedge clk);
      cfg_we_o    = 1'b1;
      cfg_addr_o  = a;
      cfg_wdata_o = d;
      @(negedge clk);
      cfg_we_o    = 1'b0;
      n_writes    = n_writes + 1;
    end
  endtask

  task read_reg;
    input [1:0] a;
    begin
      @(negedge clk);
      cfg_re_o   = 1'b1;
      cfg_addr_o = a;
      @(negedge clk);
      cfg_re_o   = 1'b0;
      last_rdata = cfg_rdata_i;
      n_reads    = n_reads + 1;
    end
  endtask

  task ack;
    begin
      @(negedge clk);
      iack_o = 1'b1;
      @(negedge clk);
      iack_o = 1'b0;
      n_acks = n_acks + 1;
    end
  endtask

  task eoi;
    begin
      write_reg(`ADDR_EOI, {N{1'b0}});
      n_eois = n_eois + 1;
    end
  endtask

  task ack_and_eoi;
    begin
      @(negedge clk);
      iack_o      = 1'b1;
      cfg_we_o    = 1'b1;
      cfg_addr_o  = `ADDR_EOI;
      cfg_wdata_o = {N{1'b0}};
      @(negedge clk);
      iack_o      = 1'b0;
      cfg_we_o    = 1'b0;
      n_acks = n_acks + 1;
      n_eois = n_eois + 1;
    end
  endtask

  task ack_and_write;
    input [1:0]   a;
    input [N-1:0] d;
    begin
      @(negedge clk);
      iack_o      = 1'b1;
      cfg_we_o    = 1'b1;
      cfg_addr_o  = a;
      cfg_wdata_o = d;
      @(negedge clk);
      iack_o      = 1'b0;
      cfg_we_o    = 1'b0;
      n_acks   = n_acks + 1;
      n_writes = n_writes + 1;
    end
  endtask

  task idle;
    input integer cycles;
    integer c;
    begin
      for (c = 0; c < cycles; c = c + 1) @(posedge clk);
    end
  endtask

  reg wait_ok;
  task wait_irq;
    input integer max_cycles;
    integer c;
    begin
      wait_ok = 1'b0;
      for (c = 0; c < max_cycles; c = c + 1) begin
        @(posedge clk);
        if (irq_i) begin
          wait_ok = 1'b1;
          c = max_cycles;
        end
      end
    end
  endtask

  wire _unused = &{1'b0, irq_id_i, rst_n, 1'b0};

endmodule
