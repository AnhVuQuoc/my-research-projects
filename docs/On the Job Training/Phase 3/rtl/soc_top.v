// =============================================================================
// File        : soc_top.v
// Module      : soc_top
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Job         : The system: cpu_top with the I/O page at 0xF0..0xFF and the
//               interrupt input, connected to timer_adc8_cpu_if. Shared clock;
//               the CPU's synchronous active-high rst drives the peripheral's
//               active-low rst_n (already synchronous to clk here).
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module soc_top #(
    parameter PROGRAM_FILE = "soc_demo.mem"
)(
    input  wire        clk,
    input  wire        rst,
    output wire        halted,
    output wire [7:0]  pc_out,
    output wire        irq,
    output wire        pwm_out,
    output wire        adc_sample,
    output wire [1:0]  adc_ch,
    output wire [7:0]  adc_dac,
    input  wire        adc_cmp
);

    wire       io_cs, io_we;
    wire [3:0] io_addr;
    wire [7:0] io_wdata, io_rdata;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [15:0] instr_out;
    wire [7:0]  alu_out, wb_data_out;
    wire        zero_out, carry_out;
    /* verilator lint_on UNUSEDSIGNAL */

    cpu_top #(.PROGRAM_FILE(PROGRAM_FILE), .IO_ENABLE(1), .IO_PAGE(4'hF), .IRQ_VECTOR(8'h10)) CPU (
        .clk(clk), .rst(rst), .pc_out(pc_out), .instr_out(instr_out), .alu_out(alu_out), .wb_data_out(wb_data_out),
        .zero_out(zero_out), .carry_out(carry_out), .halted(halted),
        .irq(irq), .io_cs(io_cs), .io_we(io_we), .io_addr(io_addr), .io_wdata(io_wdata), .io_rdata(io_rdata));

    timer_adc8_cpu_if TADC (
        .clk(clk), .rst_n(~rst), .cs(io_cs), .we(io_we), .addr(io_addr), .wdata(io_wdata), .rdata(io_rdata),
        .irq(irq), .pwm_out(pwm_out), .adc_sample(adc_sample), .adc_ch(adc_ch), .adc_dac(adc_dac), .adc_cmp(adc_cmp));

endmodule

`default_nettype wire
