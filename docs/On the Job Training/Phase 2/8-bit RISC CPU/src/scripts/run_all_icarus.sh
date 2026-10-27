#!/usr/bin/env bash
# =============================================================================
# File    : scripts/run_all_icarus.sh
# Project : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
# Author  : Vu Quoc Anh (SE203519)
# Job     : One-command regression: assemble asm/*.asm, check that every .mem
#           has 256 words, lint with Verilator (if installed), run all 17
#           testbenches, print 1 summary line each, exit 1 on any FAIL.
# Usage   : ./scripts/run_all_icarus.sh [--vcd]
# =============================================================================
set -u
cd "$(dirname "$0")/.."
BUILD=build; mkdir -p "$BUILD"
VCD=""; [ "${1:-}" = "--vcd" ] && VCD="+vcd"
TBS="tb_alu tb_mux2 tb_mux3 tb_register_file tb_program_counter tb_instruction_memory
     tb_instruction_register tb_control_unit tb_hazard_unit tb_halt_unit tb_forwarding_unit
     tb_id_ex_register tb_flag_register tb_ex_mem_register tb_data_memory tb_mem_wb_register tb_cpu"
bad=0
echo "== 1. assemble =="
python3 scripts/asm8.py asm/demo.asm rtl/program.mem || bad=1
for p in prog_arith prog_logic prog_mem prog_branch prog_wrap; do python3 scripts/asm8.py asm/$p.asm tb/$p.mem || bad=1; done
echo "== 2. program files =="
for f in rtl/*.mem tb/*.mem; do
    n=$(grep -cE '^[0-9A-Fa-f]{4}$' "$f")
    if [ "$n" -ne 256 ]; then echo "   FAIL $f has $n words (needs 256)"; bad=1; else echo "   ok   $f (256 words)"; fi
    cp "$f" "$BUILD/"
done
echo "== 3. lint =="
if command -v verilator > /dev/null 2>&1; then
    if verilator --lint-only -Wall -Irtl rtl/*.v --top-module cpu_top; then echo "   ok   verilator -Wall: no warnings"
    else echo "   FAIL lint"; bad=1; fi
else echo "   skip (verilator not installed)"; fi
echo "== 4. simulation =="
for tb in $TBS; do
    if ! iverilog -g2001 -Wall -s "$tb" -c scripts/files.f -o "$BUILD/$tb.vvp" "tb/$tb.v" 2> "$BUILD/$tb.compile.log"; then
        echo "   FAIL $tb did not compile"; bad=1; continue; fi
    (cd "$BUILD" && vvp -n "$tb.vvp" $VCD > "$tb.log" 2>&1)
    line=$(grep -E '^(PASS|FAILED):' "$BUILD/$tb.log" | tail -1)
    [ -z "$line" ] && line="FAILED: $tb produced no summary line"
    echo "   $line"
    case "$line" in PASS:*) ;; *) bad=1 ;; esac
done
echo "== summary =="
if [ $bad -eq 0 ]; then echo "ALL PASS (Vu Quoc Anh, SE203519)"; exit 0; else echo "SOME CHECKS FAILED"; exit 1; fi
