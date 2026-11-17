// =============================================================================
// File        : sync_fifo.v
// Module      : sync_fifo
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Job         : Synchronous FIFO, first-word-fall-through: dout always shows the
//               oldest entry, so a read is combinational. push is accepted when
//               not full, or when full with a pop in the same clock (no loss).
//               A push into a full FIFO without a pop is dropped (overflow).
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module sync_fifo #(
    parameter W = 10,                                 // {channel[1:0], data[7:0]}
    parameter DEPTH = 8,
    parameter AW = 3
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          push,
    input  wire [W-1:0]  din,
    input  wire          pop,
    output wire [W-1:0]  dout,                        // oldest entry (FWFT)
    output reg  [AW:0]   level,                       // 0..DEPTH
    output wire          empty,
    output wire          full,
    output wire          overflow                     // 1 clock: push dropped
);

    reg [W-1:0]  mem [0:DEPTH-1];
    reg [AW-1:0] wptr, rptr;
    wire do_pop  = pop & ~empty;
    wire do_push = push & (~full | do_pop);

    assign empty    = (level == 0);
    assign full     = (level == DEPTH);
    assign overflow = push & full & ~do_pop;
    assign dout     = empty ? {W{1'b0}} : mem[rptr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= {AW{1'b0}}; rptr <= {AW{1'b0}}; level <= {(AW+1){1'b0}};
        end
        else begin
            if (do_push) begin mem[wptr] <= din; wptr <= wptr + 1'b1; end
            if (do_pop)  rptr <= rptr + 1'b1;
            case ({do_push, do_pop})
                2'b10:   level <= level + 1'b1;
                2'b01:   level <= level - 1'b1;
                default: level <= level;
            endcase
        end
    end

endmodule

`default_nettype wire
