`timescale 1ns/1ps
`include "tb_defs.vh"

module coverage_auto #(
  parameter AW = `U_AW,
  parameter DW = `U_DW
)(
  input  wire          pclk,
  input  wire          presetn,
  input  wire          tr_vld_i,
  input  wire          tr_write_i,
  input  wire [AW-1:0] tr_addr_i,
  input  wire [DW-1:0] tr_wdata_i,
  input  wire [DW-1:0] tr_rdata_i,
  input  wire          tr_err_i,
  input  wire          tx_busy_i,
  input  wire          irq_i,
  input  wire          pred_frame_i,
  input  wire          pred_parity_i
);

  localparam NBINS = 30;
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
  localparam B_STOP1     = 20;
  localparam B_STOP2     = 21;
  localparam B_BAUD_A    = 22;
  localparam B_BAUD_B    = 23;
  localparam B_ERR_FRAME = 24;
  localparam B_ERR_PAR   = 25;
  localparam B_ERR_OVR   = 26;
  localparam B_ACC_TXBUSY= 27;
  localparam B_IRQ       = 28;
  localparam B_RXFULL    = 29;

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
      if (tr_err_i && (idx < 0))                     cov[B_ERR_UNMAP] = cov[B_ERR_UNMAP] + 1;
      if (tr_err_i && tr_write_i && (idx==2||idx==4||idx==6))
                                                     cov[B_ERR_WRRO]  = cov[B_ERR_WRRO]  + 1;
      if (tr_err_i && tr_write_i && (idx==1))        cov[B_ERR_BAUD]  = cov[B_ERR_BAUD]  + 1;
      if (tx_busy_i)                                 cov[B_ACC_TXBUSY]= cov[B_ACC_TXBUSY]+ 1;

      if (tr_write_i && !tr_err_i && (idx == 0)) begin
        if (!tr_wdata_i[`CTRL_PAR_EN])                   cov[B_PAR_NONE] = cov[B_PAR_NONE] + 1;
        else if (!tr_wdata_i[`CTRL_PAR_ODD])             cov[B_PAR_EVEN] = cov[B_PAR_EVEN] + 1;
        else                                             cov[B_PAR_ODD]  = cov[B_PAR_ODD]  + 1;
        if (tr_wdata_i[`CTRL_STOP2])                     cov[B_STOP2]    = cov[B_STOP2]    + 1;
        else                                             cov[B_STOP1]    = cov[B_STOP1]    + 1;
      end
      if (tr_write_i && !tr_err_i && (idx == 1)) begin
        if (tr_wdata_i[15:0] == `BAUD_DIV)               cov[B_BAUD_A] = cov[B_BAUD_A] + 1;
        if (tr_wdata_i[15:0] == `BAUD_DIV_ALT)           cov[B_BAUD_B] = cov[B_BAUD_B] + 1;
      end

      if (!tr_write_i && (idx == 2)) begin
        if (tr_rdata_i[`ST_ERR_OVERRUN]) cov[B_ERR_OVR] = cov[B_ERR_OVR] + 1;
        if (tr_rdata_i[`ST_RX_FULL])     cov[B_RXFULL]  = cov[B_RXFULL]  + 1;
      end
    end

    if (presetn && pred_frame_i)  cov[B_ERR_FRAME] = cov[B_ERR_FRAME] + 1;
    if (presetn && pred_parity_i) cov[B_ERR_PAR]   = cov[B_ERR_PAR]   + 1;
    if (presetn && irq_i)         cov[B_IRQ]       = cov[B_IRQ]       + 1;
  end

  function integer hits;
    input integer d;
    integer k;
    begin
      hits = 0;
      for (k = 0; k < NBINS; k = k + 1) if (cov[k] > 0) hits = hits + 1;
    end
  endfunction

  function integer coverage_pct;
    input integer d;
    begin coverage_pct = (hits(0) * 100) / NBINS; end
  endfunction

  task show; input [255:0] nm; input integer b;
    begin
      if (cov[b] > 0) $display("[HIT ] %-20s %0d", nm, cov[b]);
      else $display("[MISS] %-20s", nm);
    end
  endtask

  task report;
    input [255:0] name;
    integer k;
    begin
      $display("FUNCTIONAL COVERAGE (auto-sampled) : %0s", name);
      for (k = 0; k < 7; k = k + 1)
        if (cov[B_RD0+k] > 0) $display("[HIT ] read  reg %0d        %0d", k, cov[B_RD0+k]);
        else $display("[MISS] read  reg %0d", k);
      for (k = 0; k < 7; k = k + 1)
        if (cov[B_WR0+k] > 0) $display("[HIT ] write reg %0d        %0d", k, cov[B_WR0+k]);
        else $display("[MISS] write reg %0d", k);
      show("err_unmapped",  B_ERR_UNMAP);
      show("err_write_ro",  B_ERR_WRRO);
      show("err_baud_low",  B_ERR_BAUD);
      show("cfg_parity_none",B_PAR_NONE);
      show("cfg_parity_even",B_PAR_EVEN);
      show("cfg_parity_odd", B_PAR_ODD);
      show("cfg_stop_1",    B_STOP1);
      show("cfg_stop_2",    B_STOP2);
      show("cfg_baud_A",    B_BAUD_A);
      show("cfg_baud_B",    B_BAUD_B);
      show("evt_frame_err", B_ERR_FRAME);
      show("evt_parity_err",B_ERR_PAR);
      show("evt_overrun",   B_ERR_OVR);
      show("evt_rx_full",   B_RXFULL);
      show("cross_acc_txbusy",B_ACC_TXBUSY);
      show("evt_irq",       B_IRQ);
      $display("----------------");
      $display("bins hit : %0d / %0d  =  %0d %%", hits(0), NBINS, coverage_pct(0));
    end
  endtask

endmodule
