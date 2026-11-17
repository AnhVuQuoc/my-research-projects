// =============================================================================
// File        : sv/adc_if.sv   (SIMULATION ONLY)
// Interface   : adc_if: the analog wires plus event taps used by the monitors
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
`timescale 1ns / 1ps
interface adc_if (input logic clk, input logic rst_n);
    real        vin [4];                                // input voltages, driven by the ADC agent
    real        offset, noise;                          // comparator offset and noise (volts)
    real        vhold;                                  // held voltage (from the model)
    logic       sample, cmp;
    logic [1:0] ch;
    logic [7:0] dac;
    // event taps (connected to DUT nets in tb_top)
    logic       eoc, busy, tmr_ovf, tmr_cmp, trig_miss, wd, fifo_ovr, irq, pwm;
    logic [7:0] result;
    logic [1:0] result_ch;
endinterface
