//==============================================================================
// File        : apb_defs.vh
// Project     : 6 - Basic IP: controller + ARM APB bus interface
// Description : AMBA 3 APB geometry, the IP's register map as BYTE offsets,
//               and the command codes.
//
// This header is owned by the DESIGN and included by the design and by every
// testbench component.  It also pulls in Project 5's intc_defs.vh, so the
// interrupt core's internal register indices still have exactly one definition
// in the repository even though a second, bus-level map now sits on top of
// them.  Two maps, one definition each, and the translation between them
// written once - in apb_intc.v and nowhere else.
//
// BYTE ADDRESS vs REGISTER INDEX ---------------------------------------------
//  APB carries a byte address.  A 32-bit register file consumes bits [4:2] of
//  it here and ignores [1:0].  Confusing the two is the most common APB
//  integration mistake and it is completely silent: every access lands on
//  register 0 and the testbench cheerfully verifies register 0 seven times.
//
// CONVENTIONS RECORDED HERE (not derivable from the RTL) ----------------------
//  * Unimplemented upper bits of a narrow register read as ZERO and ignore
//    writes.  Firmware depends on this for read-modify-write.
//  * A read of a write-only register returns ZERO and is NOT an error.  This is
//    a choice - the opposite convention is equally defensible - and it is
//    recorded here so the testbench can check the choice that was made rather
//    than the one a reader assumed.
//  * A write with an unrecognised command code IS an error, and has no effect.
//  * Any access while the command controller is busy is answered with an error
//    rather than being queued or silently dropped.
//==============================================================================
`ifndef APB_DEFS_VH
`define APB_DEFS_VH

`include "intc_defs.vh"      // Project 5: ADDR_MASK / ADDR_PEND / ADDR_ISR / ADDR_EOI

// ---- bus geometry -----------------------------------------------------------
`define APB_AW      8        // address bits carried to this slave
`define APB_DW      32       // APB data bus width

// ---- IP geometry ------------------------------------------------------------
`define APB_INTC_N  8        // interrupt sources
`define APB_INTC_W  3        // clog2(APB_INTC_N)

// ---- register map, BYTE offsets ---------------------------------------------
//  offset  name     access   description
//  0x00    MASK     RW       interrupt enable, one bit per source
//  0x04    PEND     RO       pending latch
//  0x08    ISR      RO       in-service register (one bit per nesting level)
//  0x0C    EOI      WO       write anything -> retire highest in-service
//  0x10    STATUS   RO       { busy, irq_id[2:0], irq }
//  0x14    CMD      WO       start a multi-cycle command (see below)
//  0x18    ID       RO       peripheral identification constant
`define REG_MASK    8'h00
`define REG_PEND    8'h04
`define REG_ISR     8'h08
`define REG_EOI     8'h0C
`define REG_STATUS  8'h10
`define REG_CMD     8'h14
`define REG_ID      8'h18   // reads back the INTC_ID constant

`define REG_LAST    8'h18    // highest implemented offset

// ---- STATUS register bit positions ------------------------------------------
`define ST_IRQ_BIT   0       // an interrupt is currently being offered
`define ST_ID_LSB    1       // bits 3:1 - the offered source id
`define ST_BUSY_BIT  4       // the command controller is running

// ---- identification ---------------------------------------------------------
// Read-only constant at a known address.  The cheapest useful check that
// exists: it proves clock, reset, decode and the whole read path before any
// behaviour is involved.  Every real peripheral has one.
`define INTC_ID     32'h1C00_0006      // interrupt controller, project 6

// ---- command codes ----------------------------------------------------------
// Written to REG_CMD.  Anything else is rejected with an error response.
// Code 0 is deliberately not a command, so that a stray zero write does
// nothing rather than something.
`define CMD_DRAIN        32'h0000_0001
`define CMD_DISABLE_ALL  32'h0000_0002
`define CMD_ENABLE_ALL   32'h0000_0003

`endif // APB_DEFS_VH
