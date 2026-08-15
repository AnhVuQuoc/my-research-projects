PROJ := p9_uart_ip_verif
RTL := $(wildcard ../p8_mcu_uart_ip/rtl/*.v) \
       ../p6_apb_ip/rtl/apb_slave.v
TBLIB := $(wildcard tb/agent/*.v) \
         ../p6_apb_ip/tb/agent/apb_master_bfm.v \
         ../p7_apb_ip_verif/tb/agent/apb_monitor.v \
         ../p7_apb_ip_verif/tb/agent/apb_protocol_checker.v \
         ../p8_mcu_uart_ip/tb/agent/serial_driver.v \
         ../p8_mcu_uart_ip/tb/agent/serial_monitor.v \
         ../p8_mcu_uart_ip/tb/agent/uart_model.v \
         ../p8_mcu_uart_ip/tb/agent/reg_model.v \
         ../p8_mcu_uart_ip/tb/agent/checker.v
EXTRA_INCDIRS := ../p8_mcu_uart_ip/rtl ../p6_apb_ip/rtl ../p5_encoder_tb_arch/rtl
TESTS := tb_uart_auto_smoke tb_uart_auto_tx tb_uart_auto_rx \
         tb_uart_cfg_sweep tb_uart_auto_random
include ../scripts/common.mk
