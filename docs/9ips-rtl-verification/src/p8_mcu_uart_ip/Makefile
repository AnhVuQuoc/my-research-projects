
PROJ := p8_mcu_uart_ip
RTL := $(wildcard rtl/*.v) \
       ../p6_apb_ip/rtl/apb_slave.v
TBLIB := $(wildcard tb/agent/*.v) \
         ../p6_apb_ip/tb/agent/apb_master_bfm.v \
         ../p7_apb_ip_verif/tb/agent/apb_monitor.v \
         ../p7_apb_ip_verif/tb/agent/apb_protocol_checker.v
EXTRA_INCDIRS := ../p6_apb_ip/rtl ../p5_encoder_tb_arch/rtl ../p7_apb_ip_verif/tb/agent
TESTS := tb_uart_reg tb_uart_loopback tb_uart_baud tb_uart_fifo \
         tb_uart_error tb_uart_random
include ../scripts/common.mk
