PROJ := p7_apb_ip_verif
RTL := ../p6_apb_ip/rtl/apb_intc.v \
       ../p6_apb_ip/rtl/apb_slave.v \
       ../p6_apb_ip/rtl/cmd_ctrl.v \
       ../p5_encoder_tb_arch/rtl/intc_top.v \
       ../p4_encoder/rtl/intr_arbiter.v \
       ../p4_encoder/rtl/prio_enc_param.v.
TBLIB := $(wildcard tb/agent/*.v) \
         ../p6_apb_ip/tb/agent/apb_master_bfm.v \
         ../p5_encoder_tb_arch/tb/agent/irq_driver.v
EXTRA_INCDIRS := ../p6_apb_ip/rtl ../p5_encoder_tb_arch/rtl
TESTS := tb_reg_access tb_err_response tb_cmd_ctrl tb_irq_flow tb_apb_random
include ../scripts/common.mk
