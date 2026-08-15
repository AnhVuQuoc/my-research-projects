PROJ := p6_apb_ip
RTL := $(wildcard rtl/*.v) \
       ../p5_encoder_tb_arch/rtl/intc_top.v \
       ../p4_encoder/rtl/intr_arbiter.v \
       ../p4_encoder/rtl/prio_enc_param.v
EXTRA_INCDIRS := ../p5_encoder_tb_arch/rtl
TESTS := tb_apb_slave tb_apb_intc

include ../scripts/common.mk
