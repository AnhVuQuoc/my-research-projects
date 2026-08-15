`ifndef UART_DEFS_VH
`define UART_DEFS_VH

`define UREG_CTRL    8'h00
`define UREG_BAUD    8'h04
`define UREG_STATUS  8'h08
`define UREG_TXDATA  8'h0C
`define UREG_RXDATA  8'h10
`define UREG_ICLR    8'h14
`define UREG_ID      8'h18
`define UREG_LAST    8'h18

`define CTRL_EN        0
`define CTRL_PAR_EN    1
`define CTRL_PAR_ODD   2
`define CTRL_STOP2     3 
`define CTRL_LOOPBACK  4
`define CTRL_IRQ_EN    5
`define CTRL_WIDTH     6

`define ST_TX_EMPTY    0 
`define ST_TX_FULL     1
`define ST_RX_EMPTY    2
`define ST_RX_FULL     3
`define ST_TX_BUSY     4
`define ST_ERR_FRAME   5 
`define ST_ERR_PARITY  6
`define ST_ERR_OVERRUN 7
`define ST_WIDTH       8

`define ICLR_FRAME     0
`define ICLR_PARITY    1
`define ICLR_OVERRUN   2

`define UART_FIFO_DEPTH  4
`define UART_OVERSAMPLE  16
`define UART_BAUD_MIN    16
`define UART_ID_VALUE    32'h0A27_0801

`endif
