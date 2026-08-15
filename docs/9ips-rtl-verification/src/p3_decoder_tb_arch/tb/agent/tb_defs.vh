//==============================================================================
// File : tb_defs.vh - shared configuration for the Project 3 verification env
//==============================================================================
`ifndef P3_TB_DEFS_VH
`define P3_TB_DEFS_VH

`define AW 32
`define NS 4

// Clock
`define CLK_PERIOD  10        // ns

// Memory map under test (must mirror addr_decoder's parameters)
`define BASE0 32'h0000_0000
`define SIZE0 32'h0004_0000   // FLASH 256K
`define BASE1 32'h2000_0000
`define SIZE1 32'h0000_8000   // SRAM   32K
`define BASE2 32'h4000_0000
`define SIZE2 32'h0000_1000   // GPIO    4K
`define BASE3 32'h4000_1000
`define SIZE3 32'h0000_1000   // UART    4K

// CPU traffic pattern IDs
`define PAT_LINEAR    0
`define PAT_BOUNDARY  1
`define PAT_RANDOM    2
`define PAT_BIASED    3
`define PAT_REALISTIC 4

`endif
