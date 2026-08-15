//==============================================================================
// File        : intc_defs.vh
// Description : The interrupt controller's SOFTWARE-VISIBLE CONTRACT.
//
// This header is owned by the DESIGN and included by the design, the reference
// model, the drivers, the monitor and the tests.  There is exactly one
// definition of the register map in the repository.
//
// Why that matters more than it looks: the single most common integration bug
// in register-based IP is a testbench and an RTL that disagree about an
// address, an offset or a bit position.  It is not caught by simulation,
// because both sides are self-consistent - the testbench faithfully verifies
// the wrong register.  It is caught by the driver writing to a register that
// the software team also cannot find.
//
// The rule: if a number appears in both the design and the testbench, it must
// appear in a file that both include.  Copying it "just this once" is how the
// second definition is born.
//==============================================================================
`ifndef INTC_DEFS_VH
`define INTC_DEFS_VH

// ---- register map -----------------------------------------------------------
`define ADDR_MASK 2'd0     // RW  1 = source enabled
`define ADDR_PEND 2'd1     // RO  pending latch
`define ADDR_ISR  2'd2     // RO  in-service register
`define ADDR_EOI  2'd3     // WO  write anything -> retire highest in-service

// ---- geometry ---------------------------------------------------------------
`define INTC_N    8        // number of interrupt sources
`define INTC_W    3        // clog2(INTC_N) - index width

`endif // INTC_DEFS_VH
