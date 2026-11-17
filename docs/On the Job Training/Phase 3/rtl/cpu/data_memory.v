// =============================================================================
// File        : data_memory.v
// Module      : data_memory
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : MEM
// Job         : 256 x 8-bit data RAM; combinational read (LD), write on the
//               rising edge when mem_we = 1 (ST). All words start at 0.
// Ports       : clk, address [7:0], write_data [7:0], mem_we in; read_data [7:0] out
// Connections : instance DMEM in cpu_top; tb_cpu reads CPU.DMEM.mem
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module data_memory (
    input  wire       clk,
    input  wire [7:0] address,
    input  wire [7:0] write_data,
    input  wire       mem_we,
    output wire [7:0] read_data
);

    reg [7:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 8'h00;
    end

    always @(posedge clk) begin
        if (mem_we)
            mem[address] <= write_data;
    end

    assign read_data = mem[address];

endmodule

`default_nettype wire
