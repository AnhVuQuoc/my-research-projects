`timescale 1ns/1ps
`include "tb_utils.vh"
`include "tb_defs.vh"

module apb_protocol_checker #(
  parameter AW      = `APB_AW,
  parameter DW      = `APB_DW,
  parameter TIMEOUT = 64
)(
  input  wire          pclk,
  input  wire          presetn,
  input  wire          psel_i,
  input  wire          penable_i,
  input  wire          pwrite_i,
  input  wire [AW-1:0] paddr_i,
  input  wire [DW-1:0] pwdata_i,
  input  wire          pready_i,
  input  wire          pslverr_i,
  output reg  [31:0]   n_prot_errors_o,
  output reg  [31:0]   n_prot_checks_o
);

  reg          psel_d, penable_d, pwrite_d;
  reg [AW-1:0] paddr_d;
  reg [DW-1:0] pwdata_d;
  reg [15:0]   xfer_cnt;

  task prot_fail;
    input [255:0] rule;
    begin
      n_prot_errors_o = n_prot_errors_o + 32'd1;
      $display("[%0t] ERROR APB protocol %0s", $time, rule);
    end
  endtask

  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      psel_d          <= 1'b0;
      penable_d       <= 1'b0;
      pwrite_d        <= 1'b0;
      paddr_d         <= {AW{1'b0}};
      pwdata_d        <= {DW{1'b0}};
      xfer_cnt        <= 16'd0;
      n_prot_errors_o  = 32'd0;
      n_prot_checks_o  = 32'd0;
    end else begin
      n_prot_checks_o = n_prot_checks_o + 32'd1;
      if (penable_i && !psel_i) prot_fail("R1 PENABLE without PSEL");
      if (psel_i && !psel_d && penable_i)
        prot_fail("R2 no SETUP phase - PENABLE asserted with PSEL");
      if (psel_d && psel_i && !(penable_d && pready_i)) begin
        if (paddr_i  !== paddr_d)  prot_fail("R3 PADDR changed mid-transfer");
        if (pwrite_i !== pwrite_d) prot_fail("R3 PWRITE changed mid-transfer");
        if (pwdata_i !== pwdata_d) prot_fail("R3 PWDATA changed mid-transfer");
      end
      if (penable_d && !pready_i && !psel_i)
        prot_fail("R4 PSEL dropped during ACCESS");
      if (pslverr_i && !(psel_i && penable_i && pready_i))
        prot_fail("R5 PSLVERR outside a completing ACCESS");
      if (pready_i && !(psel_i && penable_i))
        prot_fail("R6 PREADY outside ACCESS");
      if (psel_i && !(penable_i && pready_i)) begin
        xfer_cnt <= xfer_cnt + 16'd1;
        if (xfer_cnt > TIMEOUT) begin
          prot_fail("R7 transfer did not complete - slave hung");
          xfer_cnt <= 16'd0;
        end
      end else begin
        xfer_cnt <= 16'd0;
      end

      psel_d    <= psel_i;
      penable_d <= penable_i;
      pwrite_d  <= pwrite_i;
      paddr_d   <= paddr_i;
      pwdata_d  <= pwdata_i;
    end
  end

  task report;
    begin
      $display("APB protocol : %0d cycles checked, %0d violations",
               n_prot_checks_o, n_prot_errors_o);
    end
  endtask

endmodule
