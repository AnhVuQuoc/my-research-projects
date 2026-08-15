PROJ  := p5_encoder_tb_arch
RTL   := $(wildcard rtl/*.v) \
         ../p4_encoder/rtl/intr_arbiter.v \
         ../p4_encoder/rtl/prio_enc_param.v
TESTS := tb_intc_smoke tb_intc_nesting tb_intc_race tb_intc_random

include ../scripts/common.mk
