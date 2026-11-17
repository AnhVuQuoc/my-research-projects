#!/bin/sh
# Directed regression (Icarus Verilog 12): assemble, lint, 9 self-checking testbenches.
cd "$(dirname "$0")/.." || exit 1
mkdir -p build && cp rtl/cpu/program.mem tb/cpu/*.mem build/ 2>/dev/null
python3 scripts/asm8.py asm/soc_demo.asm build/soc_demo.mem > /dev/null || exit 1
command -v verilator > /dev/null && verilator --lint-only -Wall -Irtl/cpu $(grep "^rtl" scripts/files_soc.f) --top-module soc_top && echo "lint: clean"
PER="rtl/periph/timer8.v rtl/periph/sar_adc_ctrl.v rtl/periph/sync_fifo.v rtl/periph/apb_regs8.v rtl/periph/timer_adc8_top.v rtl/periph/timer_adc8_cpu_if.v"
run() { tb=$1; shift; iverilog -g2005 -Irtl/cpu -s $tb -o build/$tb.vvp "$@" || return; (cd build && vvp -n $tb.vvp > $tb.log 2>&1); grep -E "^(PASS|FAILED):" build/$tb.log | tail -1; }
run tb_timer8        $PER tb/periph/tb_timer8.v
run tb_sar_adc_ctrl  $PER tb/periph/tb_sar_adc_ctrl.v
run tb_sync_fifo     $PER tb/periph/tb_sync_fifo.v
run tb_apb_regs8     $PER tb/periph/tb_apb_regs8.v
run tb_cpu_if        $PER tb/model/afe_model.v tb/periph/tb_cpu_if.v
run tb_irq_unit      rtl/cpu/irq_unit.v tb/cpu/tb_irq_unit.v
run tb_cpu           -c scripts/files_cpu.f tb/cpu/tb_cpu.v
run tb_cpu_irq       -c scripts/files_cpu.f tb/cpu/tb_cpu_irq.v
run tb_soc           -c scripts/files_soc.f tb/soc/tb_soc.v
