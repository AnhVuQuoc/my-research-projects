`timescale 1ns/1ps
`include "tb_utils.vh"
`include "apb_defs.vh"

module tb_apb_intc;

  `TB_DECLARE
  `TB_DUMP(tb_apb_intc, "tb_apb_intc.vcd")

  localparam N  = `APB_INTC_N;
  localparam AW = `APB_AW;
  localparam DW = `APB_DW;

  reg clk, rstn;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end
  reg  [N-1:0] irq;
  reg          iack;
  wire         irq_out;
  wire [2:0]   irq_id;
  wire          psel, penable, pwrite, pready, pslverr;
  wire [AW-1:0] paddr;
  wire [DW-1:0] pwdata, prdata;

  apb_master_bfm #(.AW(AW), .DW(DW)) m (
    .pclk(clk), .presetn(rstn),
    .psel_o(psel), .penable_o(penable), .pwrite_o(pwrite),
    .paddr_o(paddr), .pwdata_o(pwdata),
    .prdata_i(prdata), .pready_i(pready), .pslverr_i(pslverr));

  apb_intc #(.N(N), .WAIT_STATES(0)) dut (
    .pclk(clk), .presetn(rstn),
    .psel_i(psel), .penable_i(penable), .pwrite_i(pwrite),
    .paddr_i(paddr), .pwdata_i(pwdata),
    .prdata_o(prdata), .pready_o(pready), .pslverr_o(pslverr),
    .irq_i(irq), .iack_i(iack), .irq_o(irq_out), .irq_id_o(irq_id));

  task pulse_irq;
    input integer id;
    reg [N-1:0] one;
    begin
      one = {{(N-1){1'b0}}, 1'b1};
      @(negedge clk); irq = irq |  (one << id);
      repeat (2) @(posedge clk);
      @(negedge clk); irq = irq & ~(one << id);
      repeat (3) @(posedge clk);
    end
  endtask

  task do_iack;
    begin
      @(negedge clk); iack = 1'b1;
      @(negedge clk); iack = 1'b0;
      @(posedge clk);
    end
  endtask

  integer k;

  initial begin
    `TB_BANNER("tb_apb_intc")
    rstn = 1'b0; irq = {N{1'b0}}; iack = 1'b0;
    repeat (4) @(posedge clk);
    @(negedge clk); rstn = 1'b1;
    repeat (2) @(posedge clk);

    `INFO("P1: peripheral identification register")
    m.read(`REG_ID);
    `CHECK_EQ("P1.id",    m.last_rdata, `INTC_ID)
    `CHECK_EQ("P1.noerr", m.last_err,   1'b0)

    `INFO("P2: MASK register through APB")
    m.read(`REG_MASK);
    `CHECK_EQ("P2.reset_value", m.last_rdata, 32'h0000_0000)

    m.write(`REG_MASK, 32'h0000_00A5);
    m.read (`REG_MASK);
    `CHECK_EQ("P2.readback", m.last_rdata, 32'h0000_00A5)
    m.write(`REG_MASK, 32'hFFFF_FFFF);
    m.read (`REG_MASK);
    `CHECK_EQ("P2.unimplemented_bits_read_zero", m.last_rdata, 32'h0000_00FF)

    `INFO("P3: error responses")
    m.read(8'h80);
    `CHECK_EQ("P3.unmapped_read",  m.last_err, 1'b1)
    m.write(8'h80, 32'h1);
    `CHECK_EQ("P3.unmapped_write", m.last_err, 1'b1)

    m.write(`REG_PEND, 32'hFF);
    `CHECK_EQ("P3.write_ro_pend", m.last_err, 1'b1)
    m.write(`REG_ID, 32'h0);
    `CHECK_EQ("P3.write_ro_id",   m.last_err, 1'b1)

    m.write(`REG_CMD, 32'd99);
    `CHECK_EQ("P3.bad_command",   m.last_err, 1'b1)
    m.read(`REG_MASK);
    `CHECK_EQ("P3.no_side_effects", m.last_rdata, 32'h0000_00FF)

    `INFO("P4: reads of write-only registers return zero, without an error")
    m.read(`REG_EOI);
    `CHECK_EQ("P4.eoi_reads_zero", m.last_rdata, 32'h0000_0000)
    `CHECK_EQ("P4.eoi_no_error",   m.last_err,   1'b0)

    `INFO("P5: end-to-end interrupt flow through the bus")
    m.write(`REG_MASK, 32'h0000_00FF);
    pulse_irq(3);
    m.read(`REG_PEND);
    `CHECK_EQ("P5.pending", m.last_rdata, 32'h0000_0008)
    `CHECK_EQ("P5.irq_asserted", irq_out, 1'b1)
    `CHECK_EQ("P5.irq_id",       irq_id,  3'd3)
    m.read(`REG_STATUS);
    `CHECK_EQ("P5.status_valid", m.last_rdata[0],   1'b1)
    `CHECK_EQ("P5.status_id",    m.last_rdata[3:1], 3'd3)
    `CHECK_EQ("P5.status_busy",  m.last_rdata[4],   1'b0)
    do_iack;
    m.read(`REG_ISR);
    `CHECK_EQ("P5.in_service", m.last_rdata, 32'h0000_0008)
    m.read(`REG_PEND);
    `CHECK_EQ("P5.pending_cleared", m.last_rdata, 32'h0000_0000)
    m.write(`REG_EOI, 32'h0);
    m.read (`REG_ISR);
    `CHECK_EQ("P5.retired", m.last_rdata, 32'h0000_0000)

    `INFO("P6: CMD DISABLE_ALL / ENABLE_ALL reach the core")
    m.write(`REG_CMD, `CMD_DISABLE_ALL);
    `CHECK_EQ("P6.cmd_accepted", m.last_err, 1'b0)
    m.idle(8);
    m.read(`REG_MASK);
    `CHECK_EQ("P6.mask_cleared", m.last_rdata, 32'h0000_0000)
    m.write(`REG_CMD, `CMD_ENABLE_ALL);
    m.idle(8);
    m.read(`REG_MASK);
    `CHECK_EQ("P6.mask_set", m.last_rdata, 32'h0000_00FF)

    `INFO("P7: CMD DRAIN unwinds a three-level nest in one register write")
    pulse_irq(1);  do_iack;
    pulse_irq(4);  do_iack;
    pulse_irq(6);  do_iack;
    m.read(`REG_ISR);
    `CHECK_EQ("P7.nest_built", m.last_rdata, 32'h0000_0052)
    m.write(`REG_CMD, `CMD_DRAIN);
    m.idle(16);
    m.read(`REG_ISR);
    `CHECK_EQ("P7.nest_unwound", m.last_rdata, 32'h0000_0000)
    pulse_irq(2);
    m.read(`REG_PEND);
    `CHECK_EQ("P7.still_functional", m.last_rdata, 32'h0000_0004)
    do_iack;
    m.write(`REG_EOI, 32'h0);
    m.idle(2);

    `INFO("P8: any access while the controller is busy returns PSLVERR")
    m.write(`REG_MASK, 32'h0000_00FF);
    m.write(`REG_CMD, `CMD_DRAIN);
    `CHECK_EQ("P8.cmd_itself_ok", m.last_err, 1'b0)
    m.write(`REG_MASK, 32'h0000_0000);
    `CHECK_EQ("P8.rejected_while_busy", m.last_err, 1'b1)
    m.read(`REG_MASK);
    `CHECK_EQ("P8.read_rejected_too", m.last_err, 1'b1)
    m.idle(16);
    m.read(`REG_MASK);
    `CHECK_EQ("P8.recovers", m.last_err,   1'b0)
    `CHECK_EQ("P8.no_side_effect", m.last_rdata, 32'h0000_00FF)

    `INFO("P9: back-to-back register writes")
    m.write_b2b(`REG_MASK, 32'h0000_000F, `REG_MASK, 32'h0000_0033);
    m.read(`REG_MASK);
    `CHECK_EQ("P9.last_write_wins", m.last_rdata, 32'h0000_0033)
	
    `INFO("P10: every source is reachable through the bus")
    m.write(`REG_MASK, 32'h0000_00FF);
    for (k = 0; k < N; k = k + 1) begin
      pulse_irq(k);
      `CHECK_EQ("P10.offered", irq_out, 1'b1)
      do_iack;
      m.write(`REG_EOI, 32'h0);
      m.idle(2);
    end
    `TB_SUMMARY("tb_apb_intc")
    $finish;
  end

  `TB_WATCHDOG(clk, 100000)

endmodule
