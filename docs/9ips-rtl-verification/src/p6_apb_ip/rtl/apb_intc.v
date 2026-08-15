`timescale 1ns/1ps
`include "apb_defs.vh"

module apb_intc #(
  parameter N           = `APB_INTC_N,
  parameter W           = `APB_INTC_W,
  parameter AW          = `APB_AW,
  parameter DW          = `APB_DW,
  parameter WAIT_STATES = 0
)(
  input  wire           pclk,
  input  wire           presetn,
  input  wire           psel_i,
  input  wire           penable_i,
  input  wire           pwrite_i,
  input  wire [AW-1:0]  paddr_i,
  input  wire [DW-1:0]  pwdata_i,
  output wire [DW-1:0]  prdata_o,
  output wire           pready_o,
  output wire           pslverr_o,
  input  wire [N-1:0]   irq_i,
  input  wire           iack_i,
  output wire           irq_o,
  output wire [W-1:0]   irq_id_o
);
  wire          reg_we, reg_re;
  wire [AW-1:0] reg_addr;
  wire [DW-1:0] reg_wdata;
  reg  [DW-1:0] reg_rdata;
  wire          reg_err;

  apb_slave #(
    .AW          (AW),
    .DW          (DW),
    .WAIT_STATES (WAIT_STATES)
  ) u_apb (
    .pclk        (pclk),
    .presetn     (presetn),
    .psel_i      (psel_i),
    .penable_i   (penable_i),
    .pwrite_i    (pwrite_i),
    .paddr_i     (paddr_i),
    .pwdata_i    (pwdata_i),
    .prdata_o    (prdata_o),
    .pready_o    (pready_o),
    .pslverr_o   (pslverr_o),
    .reg_we_o    (reg_we),
    .reg_re_o    (reg_re),
    .reg_addr_o  (reg_addr),
    .reg_wdata_o (reg_wdata),
    .reg_rdata_i (reg_rdata),
    .reg_err_i   (reg_err)
  );
  wire hit_mask   = (reg_addr == `REG_MASK);
  wire hit_pend   = (reg_addr == `REG_PEND);
  wire hit_isr    = (reg_addr == `REG_ISR);
  wire hit_eoi    = (reg_addr == `REG_EOI);
  wire hit_status = (reg_addr == `REG_STATUS);
  wire hit_cmd    = (reg_addr == `REG_CMD);
  wire hit_id     = (reg_addr == `REG_ID);
  wire mapped     = hit_mask | hit_pend | hit_isr | hit_eoi | hit_status | hit_cmd | hit_id;
  wire read_only  = hit_pend | hit_isr | hit_status | hit_id;
  wire         cmd_busy;
  wire         cmd_we;
  wire [1:0]   cmd_addr;
  wire [N-1:0] cmd_wdata;
  wire cmd_code_ok = (reg_wdata == `CMD_DRAIN) || (reg_wdata == `CMD_DISABLE_ALL) || (reg_wdata == `CMD_ENABLE_ALL);
  wire cmd_start = reg_we && hit_cmd && cmd_code_ok && !cmd_busy;

  cmd_ctrl #(.N(N)) u_cmd (
    .clk       (pclk),
    .rst_n     (presetn),
    .start_i   (cmd_start),
    .code_i    (reg_wdata),
    .busy_o    (cmd_busy),
    .c_we_o    (cmd_we),
    .c_addr_o  (cmd_addr),
    .c_wdata_o (cmd_wdata)
  );
  assign reg_err = (!mapped)|| (pwrite_i && read_only)|| (pwrite_i && hit_cmd && !cmd_code_ok)|| cmd_busy;

  wire         apb_core_wr = reg_we && !cmd_busy && (hit_mask | hit_eoi);
  wire         apb_core_rd = reg_re && !cmd_busy && (hit_mask | hit_pend | hit_isr);

  wire [1:0]   apb_core_addr = hit_mask ? `ADDR_MASK : hit_pend ? `ADDR_PEND : hit_isr  ? `ADDR_ISR  : `ADDR_EOI;
  wire         core_we    = cmd_busy ? cmd_we    : apb_core_wr;
  wire         core_re    = cmd_busy ? 1'b0      : apb_core_rd;
  wire [1:0]   core_addr  = cmd_busy ? cmd_addr  : apb_core_addr;
  wire [N-1:0] core_wdata = cmd_busy ? cmd_wdata : reg_wdata[N-1:0];

  wire [N-1:0] core_rdata;
  intc_top #(.N(N)) u_core (
    .clk         (pclk),
    .rst_n       (presetn),
    .irq_i       (irq_i),
    .cfg_we_i    (core_we),
    .cfg_re_i    (core_re),
    .cfg_addr_i  (core_addr),
    .cfg_wdata_i (core_wdata),
    .cfg_rdata_o (core_rdata),
    .iack_i      (iack_i),
    .irq_o       (irq_o),
    .irq_id_o    (irq_id_o)
  );
  wire [DW-1:0] status_word = { {(DW-5){1'b0}},cmd_busyirq_id_o,irq_o };

  always @* begin
    if (hit_mask || hit_pend || hit_isr)
      reg_rdata = { {(DW-N){1'b0}}, core_rdata };
    else if (hit_status)
      reg_rdata = status_word;
    else if (hit_id)
      reg_rdata = `INTC_ID;
    else
      reg_rdata = {DW{1'b0}};
  end

endmodule
