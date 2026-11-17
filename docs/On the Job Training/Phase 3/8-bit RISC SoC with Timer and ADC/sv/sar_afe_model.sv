// =============================================================================
// File        : sv/sar_afe_model.sv   (SIMULATION ONLY)
// Module      : sar_afe_model: MUX, sample-and-hold, 8-bit DAC, comparator with
//               optional offset and random noise (uniform, +/- noise volts)
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
`timescale 1ns / 1ps
module sar_afe_model #(parameter real VREF = 3.3) (adc_if aif);
    initial begin aif.vhold = 0.0; aif.offset = 0.0; aif.noise = 0.0; foreach (aif.vin[i]) aif.vin[i] = 0.0; end
    always @(posedge aif.clk) if (aif.sample) aif.vhold <= aif.vin[aif.ch];
    real n;
    always @(*) begin
        n = (aif.noise > 0.0) ? aif.noise * (($urandom_range(2000) / 1000.0) - 1.0) : 0.0;
        aif.cmp = ((aif.vhold + aif.offset + n) >= (aif.dac * VREF / 256.0));
    end
endmodule
