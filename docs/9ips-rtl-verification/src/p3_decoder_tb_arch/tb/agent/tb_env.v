`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module tb_env #(
  parameter MAX_GAP   = 3,        
  parameter WD_CYCLES = 2000000   
);

  reg clk;
  reg rst_n;

  initial begin
    clk = 1'b0;
    forever #(`CLK_PERIOD/2) clk = ~clk;
  end

  initial rst_n = 1'b0;           
  
  wire           cpu_vld,  drv_rdy;
  wire [`AW-1:0] cpu_addr;
  wire           req;
  wire [`AW-1:0] addr;
  wire [`NS-1:0] sel;
  wire           err, ack;
  wire           mon_vld, mon_err, mon_ack;
  wire [`AW-1:0] mon_addr;
  wire [`NS-1:0] mon_sel;
  wire [31:0]    mon_count;
  wire [`NS-1:0] ref_sel;
  wire           ref_err;

  decoder_top #(.AW(`AW), .NS(`NS)) u_dut (
    .clk (clk), .rst_n(rst_n),
    .req_i(req), .addr_i(addr),
    .sel_o(sel), .err_o(err), .ack_o(ack)
  );

  cpu_model u_cpu (
    .clk(clk), .rst_n(rst_n),
    .drv_rdy_i (drv_rdy),
    .cpu_vld_o (cpu_vld),
    .cpu_addr_o(cpu_addr)
  );

  vip_driver #(.MAX_GAP(MAX_GAP)) u_drv (
    .clk(clk), .rst_n(rst_n),
    .cpu_vld_i (cpu_vld),
    .cpu_addr_i(cpu_addr),
    .drv_rdy_o (drv_rdy),
    .req_o     (req),
    .addr_o    (addr)
  );

  vip_monitor u_mon (
    .clk(clk), .rst_n(rst_n),
    .req_i(req), .addr_i(addr),
    .sel_i(sel), .err_i(err), .ack_i(ack),
    .mon_vld_o  (mon_vld),
    .mon_addr_o (mon_addr),
    .mon_sel_o  (mon_sel),
    .mon_err_o  (mon_err),
    .mon_ack_o  (mon_ack),
    .mon_count_o(mon_count)
  );

  ref_model u_ref (
    .addr_i (mon_addr),
    .valid_i(mon_vld),
    .sel_o  (ref_sel),
    .err_o  (ref_err)
  );

  checker u_chk (
    .clk(clk), .rst_n(rst_n),
    .req_i(req), .addr_i(addr), .sel_i(sel), .err_i(err), .ack_i(ack),
    .mon_vld_i (mon_vld),
    .mon_addr_i(mon_addr),
    .mon_sel_i (mon_sel),
    .mon_err_i (mon_err),
    .mon_ack_i (mon_ack),
    .ref_sel_i (ref_sel),
    .ref_err_i (ref_err)
  );

  coverage u_cov (
    .clk(clk), .rst_n(rst_n),
    .req_i(req),
    .mon_vld_i (mon_vld),
    .mon_addr_i(mon_addr),
    .mon_sel_i (mon_sel),
    .mon_err_i (mon_err)
  );

  integer wd;
  initial wd = 0;
  always @(posedge clk) begin
    wd = wd + 1;
    if (wd > WD_CYCLES) begin
      $display("[%0t] ERROR watchdog expired (%0d cycles)", $time, WD_CYCLES);
      $display(" RESULT     :  FAILED ");
      $finish;
    end
  end


  task banner;
    input [8*32-1:0] name;
    begin
      $display("===========================");
      $display(" TEST START : %0s", name);
      $display(" env config : MAX_GAP=%0d  clk=%0d ns", MAX_GAP, `CLK_PERIOD);
      $display("===========================");
    end
  endtask

  task reset_dut;
    begin
      rst_n = 1'b0;
      repeat (5) @(negedge clk);
      rst_n = 1'b1;
      repeat (2) @(negedge clk);
    end
  endtask

  task drain;                     
    begin
      repeat (10) @(negedge clk);
    end
  endtask

  task finish_test;
    input [8*32-1:0] name;
    begin
      drain;
      u_cov.report;
      u_chk.report(name);
      $finish;
    end
  endtask

  task require_coverage;
    input integer pct;
    begin
      if (u_cov.coverage_pct() < pct) begin
        $display("[%0t] ERROR coverage %0d%% below required %0d%%",
                 $time, u_cov.coverage_pct(), pct);
        u_chk.tb_errors = u_chk.tb_errors + 1;
      end
      u_chk.tb_checks = u_chk.tb_checks + 1;
    end
  endtask

endmodule
