`ifndef P9_TB_DEFS_VH
`define P9_TB_DEFS_VH

`include "uart_defs.vh"
`include "apb_defs.vh"

`define U_AW    `APB_AW
`define U_DW    `APB_DW
`define U_DIVW  16


`define CLK_PERIOD  10
`define WD_CYCLES   6000000

`define BAUD_DIV     32
`define BAUD_DIV_ALT 64

`define LINE_EXACT   0
`define LINE_FAST    1
`define LINE_SLOW    2

`define UPROF_REG    0
`define UPROF_TX     1
`define UPROF_RX     2
`define UPROF_MIXED  3

`define SETTLE_CYCLES 8

`define FRAME_CYCLES(div, nbits) ((div) * ((nbits) + 2))

`define PAR_NONE  0
`define PAR_EVEN  1
`define PAR_ODD   2

`define AUTO_MAX_ROUNDS  40
`define AUTO_COV_FLOOR   80

`endif
