`timescale 1ns/1ps
`include "tb_utils.vh"
`include "apb_defs.vh"

module tb_apb_slave;

  `TB_DECLARE
  `TB_DUMP(tb_apb_slave, "tb_apb_slave.vcd")

  localparam AW = `APB_AW;
  localparam DW = `APB_DW;

  reg clk, rstn;
  initial begin clk = 1'b0; forever #5 clk = ~clk; end

  wire        a_psel, a_penable, a_pwrite, a_pready, a_pslverr;
  wire [AW-1:0] a_paddr;
  wire [DW-1:0] a_pwdata, a_prdata;
  wire          a_we, a_re;
  wire [AW-1:0] a_addr;
  wire [DW-1:0] a_wdata;
  reg  [DW-1:0] a_rdata;
  wire          a_err;

  apb_master_bfm #(.AW(AW), .DW(DW)) mA (
    .pclk(clk), .presetn(rstn),
    .psel_o(a_psel), .penable_o(a_penable), .pwrite_o(a_pwrite),
    .paddr_o(a_paddr), .pwdata_o(a_pwdata),
    .prdata_i(a_prdata), .pready_i(a_pready), .pslverr_i(a_pslverr));

  apb_slave #(.AW(AW), .DW(DW), .WAIT_STATES(0)) sA (
    .pclk(clk), .presetn(rstn),
    .psel_i(a_psel), .penable_i(a_penable), .pwrite_i(a_pwrite),
    .paddr_i(a_paddr), .pwdata_i(a_pwdata),
    .prdata_o(a_prdata), .pready_o(a_pready), .pslverr_o(a_pslverr),
    .reg_we_o(a_we), .reg_re_o(a_re), .reg_addr_o(a_addr),
    .reg_wdata_o(a_wdata), .reg_rdata_i(a_rdata), .reg_err_i(a_err));

  wire        b_psel, b_penable, b_pwrite, b_pready, b_pslverr;
  wire [AW-1:0] b_paddr;
  wire [DW-1:0] b_pwdata, b_prdata;
  wire          b_we, b_re;
  wire [AW-1:0] b_addr;
  wire [DW-1:0] b_wdata;
  reg  [DW-1:0] b_rdata;
  wire          b_err;

  apb_master_bfm #(.AW(AW), .DW(DW)) mB (
    .pclk(clk), .presetn(rstn),
    .psel_o(b_psel), .penable_o(b_penable), .pwrite_o(b_pwrite),
    .paddr_o(b_paddr), .pwdata_o(b_pwdata),
    .prdata_i(b_prdata), .pready_i(b_pready), .pslverr_i(b_pslverr));

  apb_slave #(.AW(AW), .DW(DW), .WAIT_STATES(3)) sB (
    .pclk(clk), .presetn(rstn),
    .psel_i(b_psel), .penable_i(b_penable), .pwrite_i(b_pwrite),
    .paddr_i(b_paddr), .pwdata_i(b_pwdata),
    .prdata_o(b_prdata), .pready_o(b_pready), .pslverr_o(b_pslverr),
    .reg_we_o(b_we), .reg_re_o(b_re), .reg_addr_o(b_addr),
    .reg_wdata_o(b_wdata), .reg_rdata_i(b_rdata), .reg_err_i(b_err));

  reg [DW-1:0] memA [0:3];
  reg [DW-1:0] memB [0:3];
  integer      wr_countA, wr_countB;

  assign a_err = (a_addr[AW-1:4] != 0) || (a_addr[1:0] != 2'b00);
  assign b_err = (b_addr[AW-1:4] != 0) || (b_addr[1:0] != 2'b00);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      a_rdata   <= {DW{1'b0}};
      wr_countA <= 0;
      memA[0] <= 0; memA[1] <= 0; memA[2] <= 0; memA[3] <= 0;
    end else begin
      if (a_re) a_rdata <= memA[a_addr[3:2]];
      if (a_we) begin
        memA[a_addr[3:2]] <= a_wdata;
        wr_countA <= wr_countA + 1;
      end
    end
  end

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      b_rdata   <= {DW{1'b0}};
      wr_countB <= 0;
      memB[0] <= 0; memB[1] <= 0; memB[2] <= 0; memB[3] <= 0;
    end else begin
      if (b_re) b_rdata <= memB[b_addr[3:2]];
      if (b_we) begin
        memB[b_addr[3:2]] <= b_wdata;
        wr_countB <= wr_countB + 1;
      end
    end
  end

  integer wr_snapA, wr_snapB;
  initial begin
    `TB_BANNER("tb_apb_slave")
    rstn = 1'b0;
    repeat (4) @(posedge clk);
    @(negedge clk);
    rstn = 1'b1;
    repeat (2) @(posedge clk);


    `INFO("T1: a write reaches the register file exactly once")
    mA.write(8'h04, 32'hDEAD_BEEF);
    `CHECK_EQ("T1.value",  memA[1],   32'hDEAD_BEEF)
    `CHECK_EQ("T1.once",   wr_countA, 1)

    `INFO("T2: a read returns it, through a REGISTERED read path")
    mA.read(8'h04);
    `CHECK_EQ("T2.rdata", mA.last_rdata, 32'hDEAD_BEEF)
    `CHECK_EQ("T2.noerr", mA.last_err,   1'b0)
    `CHECK_EQ("T2.registered_path_ok", mA.last_rdata, memA[1])

    `INFO("T3: zero-wait-state transfer costs no wait cycles")
    mA.n_wait_cycles = 0;
    mA.write(8'h08, 32'h1234_5678);
    `CHECK_EQ("T3.no_wait", mA.n_wait_cycles, 0)

    `INFO("T4: a three-wait-state slave stalls for exactly three cycles")
    mB.n_wait_cycles = 0;
    mB.write(8'h00, 32'hA5A5_A5A5);
    `CHECK_EQ("T4.wait_count", mB.n_wait_cycles, 3)
    `CHECK_EQ("T4.value", memB[0], 32'hA5A5_A5A5)
    `CHECK_EQ("T4.committed_once", wr_countB, 1)
    wr_snapB = wr_countB;

    mB.n_wait_cycles = 0;
    mB.read(8'h00);
    `CHECK_EQ("T4.read_value", mB.last_rdata,   32'hA5A5_A5A5)
    `CHECK_EQ("T4.read_wait",  mB.n_wait_cycles, 3)

    `INFO("T5: an unmapped address is reported with PSLVERR")
    wr_snapA = wr_countA;
    mA.write(8'h40, 32'hFFFF_FFFF);
    `CHECK_EQ("T5.write_err", mA.last_err, 1'b1)
    `CHECK_EQ("T5.no_side_effect", wr_countA, wr_snapA)
    mA.read(8'h44);
    `CHECK_EQ("T5.read_err", mA.last_err, 1'b1)
    mA.read(8'h05);
    `CHECK_EQ("T5.misaligned_err", mA.last_err, 1'b1)
    mA.read(8'h04);
    `CHECK_EQ("T5.recovers", mA.last_err,   1'b0)
    `CHECK_EQ("T5.recovers_value", mA.last_rdata, 32'hDEAD_BEEF)

    `INFO("T6: back-to-back transfers, PSEL never dropping")
    wr_snapA = wr_countA;
    mA.write_b2b(8'h00, 32'h1111_1111, 8'h0C, 32'h2222_2222);
    `CHECK_EQ("T6.first",  memA[0], 32'h1111_1111)
    `CHECK_EQ("T6.second", memA[3], 32'h2222_2222)
    `CHECK_EQ("T6.exactly_two", wr_countA - wr_snapA, 2)

    `INFO("T7: the bus is idle between transfers")
    wr_snapA = wr_countA;
    mA.idle(10);
    `CHECK_EQ("T7.no_writes_when_idle", wr_countA - wr_snapA, 0)

    `TB_SUMMARY("tb_apb_slave")
    $finish;
  end

  `TB_WATCHDOG(clk, 20000)

endmodule
