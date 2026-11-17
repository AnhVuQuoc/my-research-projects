#!/bin/sh
# Runs the 16 unit testbenches of the CPU blocks (Icarus Verilog 12)
# Author: Vu Quoc Anh (SE203519)
set -e
cd "$(dirname "$0")/.."
mkdir -p build/units
cp rtl/cpu/*.mem build/units/ 2>/dev/null || true
for t in tb_alu tb_control_unit tb_data_memory tb_ex_mem_register tb_flag_register tb_forwarding_unit \
         tb_halt_unit tb_hazard_unit tb_id_ex_register tb_instruction_memory tb_instruction_register \
         tb_mem_wb_register tb_mux2 tb_mux3 tb_program_counter tb_register_file; do
    iverilog -g2005 -I rtl/cpu -s $t -o build/units/$t.vvp -c scripts/files_cpu_rtl.f tb/cpu/$t.v
    (cd build/units && vvp -n $t.vvp > $t.log)
    grep -E "^(PASS|FAILED)" build/units/$t.log
done
