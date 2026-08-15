`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module checker #(
  parameter AW = `U_AW,
  parameter DW = `U_DW
)(
  input  wire          pclk,
  input  wire          presetn,
  input  wire          psel_i,
  input  wire          penable_i,
  input  wire          pwrite_i,
  input  wire [AW-1:0] paddr_i,
  input  wire [DW-1:0] prdata_i,
  input  wire          pready_i,
  input  wire          pslverr_i,
  input  wire          exp_err_i,
  input  wire [DW-1:0] exp_rdata_i,
  input  wire          tx_i,
  input  wire          rx_i,
  input  wire          irq_i,
  input  wire [31:0]   n_prot_errors_i,
  input  wire [31:0]   n_prot_checks_i
);

  `TB_DECLARE

  integer n_sb_rd, n_sb_err, n_frame_cmp, n_timing_cmp, n_state_cmp, n_irq_chk;
  integer enable_sb;

  initial begin
    n_sb_rd = 0; n_sb_err = 0; n_frame_cmp = 0; n_timing_cmp = 0;
    n_state_cmp = 0; n_irq_chk = 0;
    enable_sb = 1;
  end

  wire complete = psel_i && penable_i && pready_i;
  
  always @(posedge pclk) begin
    if (presetn && enable_sb && complete) begin
      `CHECK_EQ("SB_pslverr", pslverr_i, exp_err_i)
      n_sb_err = n_sb_err + 1;

      if (!pwrite_i && !exp_err_i) begin
        `CHECK_EQ("SB_prdata", prdata_i, exp_rdata_i)
        n_sb_rd = n_sb_rd + 1;
      end
    end
  end

  reg tx_d;
  reg [31:0] idle_cnt;

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      tx_d     <= 1'b1;
      idle_cnt <= 32'd0;
    end else begin
      tx_d <= tx_i;
    end
  end

  always @(posedge pclk) begin
    if (presetn) begin
      `CHECK_TRUE("A1_tx_driven", (tx_i === 1'b0) || (tx_i === 1'b1))
    end
  end

  task check_frame;
    input [7:0] observed;
    input [7:0] expected;
    input       stop_ok;
    begin
      n_frame_cmp = n_frame_cmp + 1;
      `CHECK_EQ("Frame_data", {24'd0, observed}, {24'd0, expected})
      `CHECK_TRUE("Frame_stop_bit_high", stop_ok === 1'b1)
    end
  endtask

  task check_bit_period;
    input real measured;
    input real expected;
    input real tol_pct;
    real err_pct;
    begin
      n_timing_cmp = n_timing_cmp + 1;
      if (expected <= 0.0) begin
        $display("[%0t] ERROR timing check called with a zero expected period", $time);
        tb_errors = tb_errors + 1;
      end else begin
        err_pct = ((measured - expected) / expected) * 100.0;
        if (err_pct < 0.0) err_pct = -err_pct;
        tb_checks = tb_checks + 1;
        if (err_pct > tol_pct) begin
          tb_errors = tb_errors + 1;
          $display("[%0t] ERROR bit period %0.2f ns, expected %0.2f ns (%0.2f%% off, tolerance %0.2f%%)", $time, measured, expected, err_pct, tol_pct);
        end else if (tb_verbose > 1) begin
          $display("[%0t] DEBUG bit period %0.2f ns vs %0.2f ns (%0.2f%% off)", $time, measured, expected, err_pct);
        end
      end
    end
  endtask

  task compare_status;
    input [DW-1:0] observed;
    input [DW-1:0] expected;
    begin
      n_state_cmp = n_state_cmp + 1;
      `CHECK_EQ("STATE_status", observed, expected)
    end
  endtask

  task check_irq;
    input observed;
    input expected;
    begin
      n_irq_chk = n_irq_chk + 1;
      `CHECK_EQ("IRQ_level", {31'd0, observed}, {31'd0, expected})
    end
  endtask

  task expect_eq;
    input [255:0] nm; input [31:0] act; input [31:0] exp;
    begin `CHECK_EQ(nm, act, exp) end
  endtask

  task expect_true;
    input [255:0] nm; input cond;
    begin `CHECK_TRUE(nm, cond) end
  endtask

  task note;
    input [255:0] msg;
    begin $display("[%0t] INFO  %0s", $time, msg); end
  endtask

  task set_scoreboard; input integer e; begin enable_sb = e; end endtask
  task set_verbose;    input integer v; begin tb_verbose = v; end endtask

  task require_evaluations;
    input integer min_frames;
    input integer min_rd;
    begin
      `CHECK_TRUE("frames were compared", n_frame_cmp >= min_frames)
      `CHECK_TRUE("read scoreboard ran", n_sb_rd >= min_rd)
    end
  endtask

  task report;
    input [255:0] name;
    begin
      $display("CHECKER REPORT : %0s", name);
      $display("scoreboard PSLVERR    : %0d", n_sb_err);
      $display("scoreboard PRDATA     : %0d", n_sb_rd);
      $display("serial frames compared: %0d", n_frame_cmp);
      $display("bit-period checks     : %0d", n_timing_cmp);
      $display("status comparisons    : %0d", n_state_cmp);
      $display("interrupt checks      : %0d", n_irq_chk);
      $display("APB protocol          : %0d cycles, %0d violations",
               n_prot_checks_i, n_prot_errors_i);
      tb_checks = tb_checks + n_prot_checks_i;
      tb_errors = tb_errors + n_prot_errors_i;
	  
      `TB_SUMMARY(name)
    end
  endtask

endmodule
