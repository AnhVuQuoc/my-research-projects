`timescale 1ns/1ps
`include "tb_defs.vh"

module coverage #(
  parameter AW = `U_AW,
  parameter DW = `U_DW
)(
  input  wire          pclk,
  input  wire          presetn,

  input  wire          tr_vld_i,
  input  wire          tr_write_i,
  input  wire [AW-1:0] tr_addr_i,
  input  wire          tr_err_i,

  input  wire          tx_busy_i,
  input  wire          irq_i
);

  localparam NBINS = 28;

  integer cov [0:NBINS-1];
  integer i;

  localparam B_RD0       = 0;
  localparam B_WR0       = 7;
  localparam B_ERR_UNMAP = 14;
  localparam B_ERR_WRRO  = 15;
  localparam B_ERR_BAUD  = 16;
  localparam B_PAR_NONE  = 17;
  localparam B_PAR_EVEN  = 18;
  localparam B_PAR_ODD   = 19;
  localparam B_STOP2     = 20;
  localparam B_ERR_FRAME = 21;
  localparam B_ERR_PAR   = 22;
  localparam B_ERR_OVR   = 23;
  localparam B_TX_FULL   = 24;
  localparam B_RX_FULL   = 25;
  localparam B_ACC_WHILE_TX = 26;
  localparam B_IRQ_ASSERTED = 27;

  integer idx;

  function integer reg_index;
    input [AW-1:0] a;
    begin
      case (a)
        `UREG_CTRL:   reg_index = 0;
        `UREG_BAUD:   reg_index = 1;
        `UREG_STATUS: reg_index = 2;
        `UREG_TXDATA: reg_index = 3;
        `UREG_RXDATA: reg_index = 4;
        `UREG_ICLR:   reg_index = 5;
        `UREG_ID:     reg_index = 6;
        default:      reg_index = -1;
      endcase
    end
  endfunction

  initial for (i = 0; i < NBINS; i = i + 1) cov[i] = 0;

  always @(posedge pclk) begin
    if (presetn && tr_vld_i) begin
      idx = reg_index(tr_addr_i);
      if (idx >= 0) begin
        if (tr_write_i) cov[B_WR0 + idx] = cov[B_WR0 + idx] + 1;
        else            cov[B_RD0 + idx] = cov[B_RD0 + idx] + 1;
      end
      if (tr_err_i && (idx < 0)) cov[B_ERR_UNMAP] = cov[B_ERR_UNMAP] + 1;
      if (tr_err_i && tr_write_i && (idx == 2 || idx == 4 || idx == 6)) cov[B_ERR_WRRO]  = cov[B_ERR_WRRO]  + 1;
      if (tr_err_i && tr_write_i && (idx == 1)) cov[B_ERR_BAUD]  = cov[B_ERR_BAUD]  + 1;
      if (tx_busy_i) cov[B_ACC_WHILE_TX] = cov[B_ACC_WHILE_TX] + 1;
    end

    if (presetn && irq_i) cov[B_IRQ_ASSERTED] = cov[B_IRQ_ASSERTED] + 1;
  end
  
  task hit_parity_none; begin cov[B_PAR_NONE] = cov[B_PAR_NONE] + 1; end endtask
  task hit_parity_even; begin cov[B_PAR_EVEN] = cov[B_PAR_EVEN] + 1; end endtask
  task hit_parity_odd;  begin cov[B_PAR_ODD]  = cov[B_PAR_ODD]  + 1; end endtask
  task hit_stop2;       begin cov[B_STOP2]    = cov[B_STOP2]    + 1; end endtask
  task hit_err_frame;   begin cov[B_ERR_FRAME]= cov[B_ERR_FRAME]+ 1; end endtask
  task hit_err_parity;  begin cov[B_ERR_PAR]  = cov[B_ERR_PAR]  + 1; end endtask
  task hit_err_overrun; begin cov[B_ERR_OVR]  = cov[B_ERR_OVR]  + 1; end endtask
  task hit_tx_full;     begin cov[B_TX_FULL]  = cov[B_TX_FULL]  + 1; end endtask
  task hit_rx_full;     begin cov[B_RX_FULL]  = cov[B_RX_FULL]  + 1; end endtask

  function integer hits;
    input integer dummy;
    integer k;
    begin
      hits = 0;
      for (k = 0; k < NBINS; k = k + 1) if (cov[k] > 0) hits = hits + 1;
    end
  endfunction

  function integer coverage_pct;
    input integer dummy;
    begin coverage_pct = (hits(0) * 100) / NBINS; end
  endfunction

  task show;
    input [255:0] nm;
    input integer b;
    begin
      if (cov[b] > 0) $display("[HIT ] %-22s %0d", nm, cov[b]);
      else $display("[MISS] %-22s", nm);
    end
  endtask

  task report;
    input [255:0] name;
    integer k;
    begin
      $display("FUNCTIONAL COVERAGE : %0s", name);
      $display("- bus axis -");
      for (k = 0; k < 7; k = k + 1)
        if (cov[B_RD0+k] > 0) $display("[HIT ] read  reg %0d         %0d", k, cov[B_RD0+k]);
        else $display("[MISS] read  reg %0d", k);
      for (k = 0; k < 7; k = k + 1)
        if (cov[B_WR0+k] > 0) $display("[HIT ] write reg %0d         %0d", k, cov[B_WR0+k]);
        else $display("[MISS] write reg %0d", k);
      show("err_unmapped",     B_ERR_UNMAP);
      show("err_write_ro",     B_ERR_WRRO);
      show("err_baud_too_low", B_ERR_BAUD);
      $display("- frame axis -");
      show("parity_none",      B_PAR_NONE);
      show("parity_even",      B_PAR_EVEN);
      show("parity_odd",       B_PAR_ODD);
      show("two_stop_bits",    B_STOP2);
      show("framing_error",    B_ERR_FRAME);
      show("parity_error",     B_ERR_PAR);
      show("overrun_error",    B_ERR_OVR);
      $display("- fifo axis -");
      show("tx_fifo_full",     B_TX_FULL);
      show("rx_fifo_full",     B_RX_FULL);
      $display("- crossings -");
      show("access_while_tx",  B_ACC_WHILE_TX);
      show("irq_asserted",     B_IRQ_ASSERTED);
      $display("----------------");
      $display("   bins hit : %0d / %0d  =  %0d %%", hits(0), NBINS, coverage_pct(0));
    end
  endtask

endmodule
