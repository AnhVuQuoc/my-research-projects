`timescale 1ns/1ps
`include "apb_defs.vh"

module apb_master_bfm #(
  parameter AW = `APB_AW,
  parameter DW = `APB_DW
)(
  input  wire           pclk,
  input  wire           presetn,
  output reg            psel_o,
  output reg            penable_o,
  output reg            pwrite_o,
  output reg  [AW-1:0]  paddr_o,
  output reg  [DW-1:0]  pwdata_o,
  input  wire [DW-1:0]  prdata_i,
  input  wire           pready_i,
  input  wire           pslverr_i
);

  reg  [DW-1:0] last_rdata;
  reg           last_err;
  integer       n_writes, n_reads, n_wait_cycles;

  initial begin
    psel_o        = 1'b0;
    penable_o     = 1'b0;
    pwrite_o      = 1'b0;
    paddr_o       = {AW{1'b0}};
    pwdata_o      = {DW{1'b0}};
    last_rdata    = {DW{1'b0}};
    last_err      = 1'b0;
    n_writes      = 0;
    n_reads       = 0;
    n_wait_cycles = 0;
  end

  task wait_completion;
    reg done;
    begin
      done = 1'b0;
      while (!done) begin
        @(posedge pclk);
        if (pready_i) begin
          last_rdata = prdata_i;
          last_err   = pslverr_i;
          done       = 1'b1;
        end else begin
          n_wait_cycles = n_wait_cycles + 1;
        end
      end
    end
  endtask

  task write;
    input [AW-1:0] a;
    input [DW-1:0] d;
    begin
      @(negedge pclk);
      psel_o    = 1'b1;
      penable_o = 1'b0;
      pwrite_o  = 1'b1;
      paddr_o   = a;
      pwdata_o  = d;
      @(negedge pclk);
      penable_o = 1'b1;
      wait_completion;
      @(negedge pclk);
      psel_o    = 1'b0;
      penable_o = 1'b0;
      n_writes  = n_writes + 1;
    end
  endtask

  task read;
    input [AW-1:0] a;
    begin
      @(negedge pclk);
      psel_o    = 1'b1;
      penable_o = 1'b0;
      pwrite_o  = 1'b0;
      paddr_o   = a;
      @(negedge pclk);
      penable_o = 1'b1;
      wait_completion;
      @(negedge pclk);
      psel_o    = 1'b0;
      penable_o = 1'b0;
      n_reads   = n_reads + 1;
    end
  endtask

  task write_b2b;
    input [AW-1:0] a1;
    input [DW-1:0] d1;
    input [AW-1:0] a2;
    input [DW-1:0] d2;
    begin
      @(negedge pclk);
      psel_o = 1'b1; penable_o = 1'b0; pwrite_o = 1'b1;
      paddr_o = a1; pwdata_o = d1;
      @(negedge pclk);
      penable_o = 1'b1;
      wait_completion;
      @(negedge pclk);
      penable_o = 1'b0;
      paddr_o = a2; pwdata_o = d2;
      @(negedge pclk);
      penable_o = 1'b1;
      wait_completion;
      @(negedge pclk);
      psel_o = 1'b0; penable_o = 1'b0;
      n_writes = n_writes + 2;
    end
  endtask

  task idle;
    input integer cycles;
    integer c;
    begin
      for (c = 0; c < cycles; c = c + 1) @(posedge pclk);
    end
  endtask

  wire _unused = &{1'b0, presetn, 1'b0};

endmodule
