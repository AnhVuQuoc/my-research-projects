// =============================================================================
// File        : irq_unit.v
// Module      : irq_unit
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Stage       : ID (front-end control, like the branch decision)
// Job         : NEW. Interrupts for the 5-stage pipeline.
//   take_run   irq & IE & a valid, unstalled, non-branching instruction in ID:
//              EPC <- id_pc (that instruction is squashed and runs again after
//              RETI), PC <- VECTOR, IF/ID flushed, bubble into ID/EX, IE <- 0.
//   WFI        sleeps (front end frozen like HLT) until irq. With IE = 1 the
//              interrupt is taken with EPC = the word after WFI; with IE = 0 the
//              CPU only wakes up and continues.
//   RETI       PC <- EPC, IE <- 1, Z and C restored from the shadow copy.
//   EI, DI     set or clear IE. No nesting: IE is cleared on entry.
//   Flags      the shadow takes the value the flags have AFTER this edge, so a
//              flag write of the older instruction in EX is not lost.
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module irq_unit #(
    parameter [7:0] VECTOR = 8'h10
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       irq,             // level, from the peripheral
    input  wire       id_valid,
    input  wire [7:0] id_pc,
    input  wire [7:0] if_pc,           // frozen at WFI + 1 while sleeping
    input  wire       stall,
    input  wire       branch,          // pc_sel: taken branch in ID
    input  wire       halted,          // HLT: interrupts no longer accepted
    input  wire       id_is_reti,
    input  wire       id_is_ei,
    input  wire       id_is_di,
    input  wire       id_is_wfi,
    input  wire       flag_next_z,     // flags after this edge
    input  wire       flag_next_c,
    output reg        ie,
    output reg  [7:0] epc,
    output wire       take,            // interrupt accepted this clock
    output wire       reti_go,         // RETI executes this clock
    output wire       redirect,        // take | reti_go
    output wire [7:0] redirect_pc,
    output wire       sleep,           // hold the front end (WFI)
    output wire       restore,         // load the flags from the shadow
    output reg        sz,
    output reg        sc
);

    reg  sleeping;
    wire take_sleep = sleeping & irq & ie;
    wire take_run   = ~sleeping & ~halted & irq & ie & id_valid & ~stall & ~branch & ~id_is_reti;
    wire wfi_now    = id_is_wfi & id_valid & ~stall & ~take_run & ~irq;   // pending irq: WFI = NOP

    assign take        = take_run | take_sleep;
    assign reti_go     = id_is_reti & id_valid & ~stall;
    assign redirect    = take | reti_go;
    assign redirect_pc = take ? VECTOR : epc;
    assign sleep       = wfi_now | (sleeping & ~irq);
    assign restore     = reti_go;

    always @(posedge clk) begin
        if (rst) begin
            ie <= 1'b0; epc <= 8'd0; sz <= 1'b0; sc <= 1'b0; sleeping <= 1'b0;
        end
        else begin
            if (take) begin
                ie <= 1'b0; epc <= take_sleep ? if_pc : id_pc; sz <= flag_next_z; sc <= flag_next_c;
            end
            else if (reti_go)                 ie <= 1'b1;
            else if (id_is_ei && id_valid && !stall) ie <= 1'b1;
            else if (id_is_di && id_valid && !stall) ie <= 1'b0;
            if (take || (sleeping && irq)) sleeping <= 1'b0;
            else if (wfi_now)              sleeping <= 1'b1;
        end
    end

endmodule

`default_nettype wire
