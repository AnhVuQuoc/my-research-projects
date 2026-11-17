// =============================================================================
// File        : sv/apb_if.sv   (SIMULATION ONLY)
// Interface   : apb_if: the 8-bit APB bus of timer_adc8_top, plus a cycle counter
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
`timescale 1ns / 1ps
interface apb_if (input logic clk, input logic rst_n);
    logic       psel, penable, pwrite, pready, pslverr;
    logic [3:0] paddr;
    logic [7:0] pwdata, prdata;
    longint     cycle;                                  // shared time stamp for the monitors
    always @(posedge clk or negedge rst_n) if (!rst_n) cycle <= 0; else cycle <= cycle + 1;
    // bus rules (checked on every clock)
    a_penable_after_psel: assert property (@(posedge clk) disable iff (!rst_n) $rose(penable) |-> psel);
    a_stable_in_access  : assert property (@(posedge clk) disable iff (!rst_n) (psel && !penable) |=> (psel && $stable(paddr) && $stable(pwrite)));
endinterface
