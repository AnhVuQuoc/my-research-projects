#!/bin/sh
# UVM regression with Verilator >= 5.04x and the Accellera uvm-core library.
# Usage: UVM_HOME=/path/to/uvm-core/src sh scripts/run_uvm.sh [test]   (default: all 12 tests)
# Translation and C++ compilation are separate steps: on a small machine the translator
# would otherwise stay in memory while g++ compiles the large UVM code.
cd "$(dirname "$0")/.." || exit 1
: "${UVM_HOME:?set UVM_HOME to uvm-core/src}"
mkdir -p build/uvm
if [ ! -x build/uvm/obj_dir/Vtb_top ]; then
  verilator --cc --exe --main --timing --assert -Wno-fatal -Wno-lint -Wno-style --timescale 1ns/1ps +define+UVM_NO_DPI --output-groups 2 --Mdir build/uvm/obj_dir \
    +incdir+$UVM_HOME +incdir+tb/uvm $UVM_HOME/uvm_pkg.sv sv/apb_if.sv sv/adc_if.sv sv/sar_afe_model.sv rtl/periph/*.v sv/timer_adc_sva.sv sv/timer_adc_bind.sv \
    tb/uvm/timer_adc_pkg.sv tb/uvm/tb_top.sv --top-module tb_top -o Vtb_top || exit 1
  make -C build/uvm/obj_dir -f Vtb_top.mk -j 1 VM_PARALLEL_BUILDS=1 OPT_FAST=-O0 OPT_SLOW=-O0 OPT_GLOBAL=-O0 Vtb_top > build/uvm/make.log 2>&1 || exit 1
fi
TESTS=${1:-"tadc_reg_test tadc_timer_test tadc_adc_sw_test tadc_adc_timer_test tadc_adc_cont_test tadc_window_test tadc_noise_test tadc_trig_miss_test tadc_wm_test tadc_latch_test tadc_random_test tadc_all_test"}
for t in $TESTS; do
  ./build/uvm/obj_dir/Vtb_top +UVM_TESTNAME=$t +UVM_NO_RELNOTES > build/uvm/$t.log 2>&1
  printf "%-22s %s\n" $t "$(grep -o 'PASSED\|FAILED' build/uvm/$t.log | tail -1)"
done
