//==============================================================================
// File : alu_defs.vh  -- ALU opcode encoding (shared by RTL and testbench)
//==============================================================================
`ifndef ALU_DEFS_VH
`define ALU_DEFS_VH

`define ALU_OP_W   4

`define ALU_ADD    4'h0
`define ALU_SUB    4'h1
`define ALU_AND    4'h2
`define ALU_OR     4'h3
`define ALU_XOR    4'h4
`define ALU_NOT    4'h5   // ~a
`define ALU_SLL    4'h6   // a << b[2:0]
`define ALU_SRL    4'h7   // a >> b[2:0]   (logical)
`define ALU_SRA    4'h8   // a >>> b[2:0]  (arithmetic)
`define ALU_SLT    4'h9   // signed   set-less-than
`define ALU_SLTU   4'hA   // unsigned set-less-than
`define ALU_PASSB  4'hB   // y = b

`endif
