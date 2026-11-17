// =============================================================================
// File        : instruction_memory.v
// Module      : instruction_memory
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : IF
// Job         : 256 x 16-bit program ROM, asynchronous read. Initialized ONLY by
//               $readmemh, so simulation and synthesis build the same ROM. Every
//               program file has exactly 256 words (scripts/asm8.py writes them;
//               unused words are 0000 = NOP).
// Parameter   : PROGRAM_FILE  hex file, one 4-digit word per line (256 lines)
// Ports       :
//   address     [7:0]  in   fetch address (PC)
//   instruction [15:0] out  word at that address
// Connections : instance IMEM in cpu_top; tb_cpu writes CPU.IMEM.mem
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module instruction_memory #(
    parameter PROGRAM_FILE = "program.mem"
)(
    input  wire [7:0]  address,
    output wire [15:0] instruction
);

    reg [15:0] mem [0:255];

    initial begin
        $readmemh(PROGRAM_FILE, mem, 0, 255);
    end

    assign instruction = mem[address];

endmodule

`default_nettype wire
