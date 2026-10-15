`timescale 1ns / 1ps
// ============================================================================
// muldiv_unit.v                                        [Build step 8 / Level 1]
// Author  : Vu Quoc Anh    Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// ----------------------------------------------------------------------------
// Sequential multiplier / divider: SHIFTING + the ALU's ONE shared adder.
// This module contains NO adder. It drives the shared adder through
// add_a / add_b / add_sub and reads back add_sum / add_c4 while busy = 1.
//
// Registers
//   acc : MUL -> high half of product     DIV -> partial remainder
//   q   : MUL -> multiplier, fills with   DIV -> dividend, fills with
//                the low half of product           the quotient
//   m   : MUL -> multiplicand             DIV -> divisor
//   count (2b), running, mode_div, done, div_by_zero    -> 18 flip-flops
//
// MUL (shift-and-add), 4 steps:
//   if q[0]: {C,acc} = acc + m   else C = 0
//   {C,acc,q} >>= 1                      -> product = {acc, q}
// DIV (restoring shift-and-subtract), 4 steps:
//   {acc,q} <<= 1 ; try acc - m
//   fits (r_top | c4): acc = acc - m, q[0] = 1   else keep acc, q[0] = 0
//                                        -> quotient = q, remainder = acc
//
// Protocol: a, b stable, pulse start for one clock -> load edge (1 clock),
//           then 4 RUN clocks; done rises on the 4th, result held until
//           the next start. start is ignored while running.
// Divide by zero: div_by_zero = 1, quotient = 1111, remainder = a.
// ============================================================================
module muldiv_unit (
    input  wire       clk,
    input  wire       rst,        // active-high, asynchronous
    input  wire       start,      // 1-clock pulse (already gated by is_muldiv)
    input  wire       is_div,     // 0 = MUL, 1 = DIV (sampled at start)
    input  wire [3:0] a,
    input  wire [3:0] b,
    // ---- connection to the shared adder/subtractor ----
    output wire [3:0] add_a,
    output wire [3:0] add_b,
    output wire       add_sub,
    input  wire [3:0] add_sum,
    input  wire       add_c4,     // SUB: 1 = no borrow
    // ---- results / status ----
    output wire [3:0] hi,         // MUL: product[7:4]   DIV: remainder
    output wire [3:0] lo,         // MUL: product[3:0]   DIV: quotient
    output wire       busy,
    output reg        done,
    output reg        div_by_zero
);
    // ------------------------------------------------------------ state
    reg [3:0] acc, q, m;
    reg [1:0] count;      // step 0..3
    reg       running;    // FSM: 0 = IDLE, 1 = RUN
    reg       mode_div;   // operation latched at start

    // ------------------------------------------------------------ datapath
    wire [3:0] r_shift = {acc[2:0], q[3]};  // DIV: {acc,q} << 1, top 4 bits
    wire       r_top   = acc[3];            // bit shifted out of acc (>= 16)
    wire       fits    = r_top | add_c4;    // partial remainder >= divisor ?

    assign add_a   = mode_div ? r_shift : acc;
    assign add_b   = m;
    assign add_sub = mode_div;              // subtract when dividing

    assign busy = running;
    assign hi   = acc;
    assign lo   = q;

    // ------------------------------------------------------------ control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc <= 4'd0;  q <= 4'd0;  m <= 4'd0;
            count <= 2'd0; running <= 1'b0; mode_div <= 1'b0;
            done  <= 1'b0; div_by_zero <= 1'b0;
        end
        else if (start && !running) begin               // IDLE -> RUN : load
            running     <= 1'b1;
            done        <= 1'b0;
            mode_div    <= is_div;
            count       <= 2'd0;
            acc         <= 4'd0;
            q           <= is_div ? a : b;              // dividend / multiplier
            m           <= is_div ? b : a;              // divisor  / multiplicand
            div_by_zero <= is_div && (b == 4'd0);
        end
        else if (running) begin                         // RUN : one step
            if (!mode_div) begin
                // MUL step: add (if q[0]) then shift {C,acc,q} right
                if (q[0]) {acc, q} <= {add_c4, add_sum, q[3:1]};
                else      {acc, q} <= {1'b0,   acc,     q[3:1]};
            end
            else begin
                // DIV step: shift left, subtract if it fits
                if (fits) begin
                    acc <= add_sum;                     // r_shift - m
                    q   <= {q[2:0], 1'b1};
                end
                else begin
                    acc <= r_shift;                     // "restore" = keep
                    q   <= {q[2:0], 1'b0};
                end
            end
            count <= count + 2'd1;
            if (count == 2'd3) begin                    // last step -> IDLE
                running <= 1'b0;
                done    <= 1'b1;
            end
        end
    end
endmodule
