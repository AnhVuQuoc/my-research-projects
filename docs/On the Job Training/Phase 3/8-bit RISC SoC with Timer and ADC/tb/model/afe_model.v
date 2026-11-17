// =============================================================================
// File        : tb/model/afe_model.v   (SIMULATION ONLY, Verilog-2001 with real)
// Module      : afe_model
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Job         : Behavioral analog front end: 4-input MUX, sample-and-hold, ideal
//               8-bit DAC and comparator. While sample = 1 the hold voltage
//               tracks vin[ch]; when sample falls it is frozen. cmp = 1 when the
//               held voltage is >= the DAC voltage (dac * VREF / 256).
//               Optional offset (volts) models a comparator offset.
// =============================================================================
`timescale 1ns / 1ps
module afe_model #(parameter real VREF = 3.3)(
    input  wire       clk,
    input  wire       sample,
    input  wire [1:0] ch,
    input  wire [7:0] dac,
    output wire       cmp
);
    real vin0, vin1, vin2, vin3, offset, vhold;
    initial begin vin0 = 0.0; vin1 = 0.0; vin2 = 0.0; vin3 = 0.0; offset = 0.0; vhold = 0.0; end
    function real vsel; input [1:0] c;
        vsel = (c == 0) ? vin0 : (c == 1) ? vin1 : (c == 2) ? vin2 : vin3;
    endfunction
    always @(posedge clk) if (sample) vhold <= vsel(ch);          // track on every clock
    wire real_unused = 1'b0;
    assign cmp = ((vhold + offset) >= (dac * VREF / 256.0));
    // ideal reference code for a given voltage (used by testbenches)
    function [7:0] ideal_code; input real v;
        real c; begin c = v * 256.0 / VREF; ideal_code = (c >= 255.0) ? 8'd255 : (c <= 0.0) ? 8'd0 : $rtoi(c); end
    endfunction
endmodule
