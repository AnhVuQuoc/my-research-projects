#!/bin/sh
# System test under Verilator with the 34 assertions of sv/timer_adc_sva.sv bound to timer_adc8_top.
cd "$(dirname "$0")/.." || exit 1
mkdir -p build/vl && python3 scripts/asm8.py asm/soc_demo.asm build/vl/soc_demo.mem > /dev/null
cd build/vl && verilator --binary --timing --assert -Wno-fatal -Wno-lint -Wno-style -I../../rtl/cpu --top-module tb_soc \
  $(cd ../.. && for f in $(grep "^rtl\|^tb" scripts/files_soc.f); do echo ../../$f; done) ../../sv/timer_adc_sva.sv ../../sv/timer_adc_bind.sv ../../tb/soc/tb_soc.v -o Vtb_soc > vl.log 2>&1 \
  && ./obj_dir/Vtb_soc +verilator+error+limit+100 | grep -E "halted|^PASS|^FAILED|Assertion"
