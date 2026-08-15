//==============================================================================
// File        : tb_defs.vh   (Project 5)
// Description : Testbench-side constants.  The DESIGN's contract lives in
//               rtl/intc_defs.vh and is pulled in here, so that the register
//               map has exactly one definition in the repository.
//==============================================================================
`ifndef P5_TB_DEFS_VH
`define P5_TB_DEFS_VH

`include "intc_defs.vh"       // <-- the design's contract, not a copy of it

// ---- timing ------------------------------------------------------------------
`define CLK_PERIOD  10        // ns
`define WD_CYCLES   500000    // watchdog

// ---- stimulus pattern ids ----------------------------------------------------
`define PAT_SINGLE   0        // one source at a time
`define PAT_NESTED   1        // deliberately nested arrivals
`define PAT_STORM    2        // many sources at once
`define PAT_RANDOM   3        // uniform random
`define PAT_ISR_FLOW 4        // realistic: arrive -> ack -> work -> eoi

// ---- irq line drive styles ---------------------------------------------------
`define IRQ_ALIGNED  0        // change the line on the negedge (well behaved)
`define IRQ_SKEWED   1        // change it at a random point in the period
`define IRQ_HOSTILE  2        // change it inside the setup window of posedge

`endif // P5_TB_DEFS_VH
