#!/usr/bin/env python3
# =============================================================================
# File    : scripts/mutation_test.py
# Project : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
# Author  : Vu Quoc Anh (SE203519)
# Job     : Inserts 12 typical design bugs, 1 at a time, and checks that the
#           testbenches FAIL on every one ("the mutant is killed").
# Usage   : python3 scripts/mutation_test.py [M1 M2 ...]   (from the repository root)
# =============================================================================
import os, shutil, subprocess, sys, tempfile
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
MUTANTS = [
 ("M1",  "register_file.v",   "        if (we && (wa == ra))\n            qa = wd;", "        if (1'b0)\n            qa = wd;", "no write-first bypass on port A", "tb_register_file"),
 ("M2",  "forwarding_unit.v", "if (mem_reg_we && (mem_rd == ex_ra))      fwd_a_sel = `FWD_MEM;\n        else if (wb_reg_we && (wb_rd == ex_ra))   fwd_a_sel = `FWD_WB;",
                              "if (wb_reg_we && (wb_rd == ex_ra))        fwd_a_sel = `FWD_WB;\n        else if (mem_reg_we && (mem_rd == ex_ra)) fwd_a_sel = `FWD_MEM;", "forwarding priority WB before MEM", "tb_forwarding_unit"),
 ("M3",  "hazard_unit.v",     "assign load_use_stall = ex_is_load & (a_match | b_match);", "assign load_use_stall = ex_is_load & a_match;", "load-use ignores port B (ST data)", "tb_hazard_unit"),
 ("M4",  "hazard_unit.v",     "assign flag_stall     = (id_is_bz | id_is_bnz) & ex_zero_we;", "assign flag_stall     = 1'b0;", "no flag stall for BZ/BNZ", "tb_hazard_unit"),
 ("M5",  "control_unit.v",    "assign pc_sel = (is_jmp | (is_bz & zero_flag) | (is_bnz & ~zero_flag)) & ~stall;",
                              "assign pc_sel = (is_jmp | (is_bz & zero_flag) | (is_bnz & ~zero_flag));", "branch not gated by stall", "tb_control_unit"),
 ("M6",  "alu.v",             "carry = ~sum[8]; end  // borrow", "carry =  sum[8]; end  // borrow", "SUB carry = no-borrow (4-bit convention)", "tb_alu"),
 ("M7",  "control_unit.v",    "assign ra = ra_is_rd ? rd : rs1;", "assign ra = rs1;", "ADDI reads rs1 instead of rd", "tb_control_unit"),
 ("M8",  "control_unit.v",    "assign rb = rb_is_rd ? rd : rs2;", "assign rb = rs2;", "ST data read from rs2 instead of rd", "tb_control_unit"),
 ("M9",  "cpu_top.v",         ".store_data_in (ex_b_fwd),", ".store_data_in (ex_op_a),", "store data wired as in the 4-bit CPU", None),
 ("M10", "cpu_defs.vh",       "`define NOP_INSTR 16'h0000", "`define NOP_INSTR 16'hC000", "bubble word C000 (= JMP 0 in the new ISA)", "tb_instruction_register"),
 ("M11", "halt_unit.v",       "assign if_id_flush = branch_flush | halt;", "assign if_id_flush = branch_flush;", "HLT does not stop new instructions", "tb_halt_unit"),
 ("M12", "cpu_top.v",         "wire        mem_we_safe = mem_mem_we & ~rst;", "wire        mem_we_safe = mem_mem_we;", "no reset gate on the data-memory write", None),
]
def run(tb, rtl, work):
    for d in ('rtl', 'tb'):
        for f in os.listdir(os.path.join(ROOT, d)):
            if f.endswith('.mem'): shutil.copy(os.path.join(ROOT, d, f), work)
    files = [os.path.join(rtl, f) for f in sorted(os.listdir(rtl)) if f.endswith('.v')]
    files += [os.path.join(ROOT, 'tb', 'isa_reference_model.v'), os.path.join(ROOT, 'tb', tb + '.v')]
    vvp = os.path.join(work, tb + '.vvp')
    if subprocess.run(['iverilog', '-g2001', '-I', rtl, '-s', tb, '-o', vvp] + files, capture_output=True).returncode:
        return 'COMPILE ERROR'
    out = subprocess.run(['vvp', '-n', vvp], cwd=work, capture_output=True, text=True).stdout
    lines = [l for l in out.splitlines() if l.startswith(('PASS:', 'FAILED:'))]
    return lines[-1] if lines else 'no summary line'
def main():
    killed = 0
    print('Mutation test (Vu Quoc Anh, SE203519)')
    only = set(sys.argv[1:])
    todo = [m for m in MUTANTS if not only or m[0] in only]
    for mid, fname, old, new, desc, unit in todo:
        work = tempfile.mkdtemp(); rtl = os.path.join(work, 'rtl')
        shutil.copytree(os.path.join(ROOT, 'rtl'), rtl)
        path = os.path.join(rtl, fname); src = open(path).read()
        if old not in src: print(f'{mid}: pattern not found in {fname}'); continue
        open(path, 'w').write(src.replace(old, new))
        u = run(unit, rtl, work) if unit else 'n/a'
        c = run('tb_cpu', rtl, work)
        dead = u.startswith('FAILED') or c.startswith('FAILED') or 'COMPILE' in c
        killed += dead
        tag = lambda r: 'KILLED' if r.startswith('FAILED') else r[:6]
        print(f'{mid:3s} {desc:44s} unit: {tag(u):7s} tb_cpu: {tag(c)}')
        shutil.rmtree(work, ignore_errors=True)
    print(f'RESULT: {killed} of {len(todo)} mutants killed')
    sys.exit(0 if killed == len(todo) else 1)
if __name__ == '__main__':
    main()
