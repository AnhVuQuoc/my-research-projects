`ifndef P7_TB_DEFS_VH
`define P7_TB_DEFS_VH

`include "apb_defs.vh"

`define CLK_PERIOD   10
`define WD_CYCLES    500000

`define IRQ_ALIGNED  0
`define IRQ_SKEWED   1
`define IRQ_HOSTILE  2

`define PROF_REG     0
`define PROF_IRQ     1
`define PROF_MIXED   2
`define PROF_ERROR   3

`define SETTLE_CYCLES 24

`endif // P7_TB_DEFS_VH
