// =============================================================================
// File        : data_memory.v
// Module      : data_memory
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : MEM
// Job         : 16 x 4-bit data RAM (Harvard: separate from the program).
//               Read is combinational (LOAD), write is on the rising clock
//               edge when mem_we = 1 (STORE). All words start at 0.
// Ports       :
//   clk              in   clock, rising edge
//   address    [3:0] in   word address (ALU result = immediate)
//   write_data [3:0] in   data to store (forwarded Rd value)
//   mem_we           in   1 = write
//   read_data  [3:0] out  word at address
// Connections : instance DMEM in cpu_top; tested by tb_data_memory;
//               tb_cpu reads and clears CPU.DMEM.mem (simulation only)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module data_memory (
    input  wire       clk,
    input  wire [3:0] address,
    input  wire [3:0] write_data,
    input  wire       mem_we,
    output wire [3:0] read_data
);

    reg [3:0] mem [0:15];               // 16 words x 4 bits
    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1)
            mem[i] = 4'b0000;           // no X values at start
    end

    always @(posedge clk) begin
        if (mem_we)
            mem[address] <= write_data; // STORE
    end

    assign read_data = mem[address];    // LOAD (asynchronous read)

endmodule

`default_nettype wire
