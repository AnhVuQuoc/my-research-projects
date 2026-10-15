// =============================================================================
// File        : instruction_memory.v
// Module      : instruction_memory
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Stage       : IF
// Job         : 16 x 12-bit program ROM, read combinationally (asynchronous).
//               The ROM is initialized ONLY by $readmemh, so simulation and
//               synthesis build exactly the same contents. Rule: every
//               program file has exactly 16 words; unused words are C00
//               (reserved opcode = NOP). A short file leaves X in simulation,
//               which tb_instruction_memory and tb_cpu report as a failure.
// Parameter   : PROGRAM_FILE  hex file, one 3-digit word per line (16 lines)
// Ports       :
//   address     [3:0]  in   fetch address (from the PC)
//   instruction [11:0] out  instruction word at that address
// Connections : instance IMEM in cpu_top; tested by tb_instruction_memory;
//               tb_cpu writes CPU.IMEM.mem to load programs (simulation only)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module instruction_memory #(
    parameter PROGRAM_FILE = "program.mem"
)(
    input  wire [3:0]  address,
    output wire [11:0] instruction
);

    reg [11:0] mem [0:15];              // 16 words x 12 bits

    initial begin
        $readmemh(PROGRAM_FILE, mem, 0, 15);  // all 16 words come from the file
    end

    assign instruction = mem[address];  // asynchronous read

endmodule

`default_nettype wire
