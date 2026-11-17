#!/usr/bin/env python3
"""Mutation testing for the peripheral and the CPU interrupt / I/O changes.
Each mutant changes one line in a copy of rtl/, then the listed testbenches run
(Icarus Verilog). A mutant is killed when at least one of them does not PASS."""
import os, re, shutil, subprocess, sys, tempfile
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TB = {  # name: (sources, top file)
 'tb_timer8': ('periph', 'tb/periph/tb_timer8.v'), 'tb_sar_adc_ctrl': ('periph', 'tb/periph/tb_sar_adc_ctrl.v'),
 'tb_sync_fifo': ('periph', 'tb/periph/tb_sync_fifo.v'), 'tb_apb_regs8': ('periph', 'tb/periph/tb_apb_regs8.v'),
 'tb_cpu_if': ('periph+afe', 'tb/periph/tb_cpu_if.v'), 'tb_irq_unit': ('irq', 'tb/cpu/tb_irq_unit.v'),
 'tb_cpu_irq': ('cpu', 'tb/cpu/tb_cpu_irq.v'), 'tb_soc': ('soc', 'tb/soc/tb_soc.v')}
MUT = [
 ('P1', 'timer counts one past LOAD', 'rtl/periph/timer8.v', 'assign ovf_pulse    = tick & (cnt >= load);', 'assign ovf_pulse    = tick & (cnt > load);', ['tb_timer8']),
 ('P2', 'ADC stops one bit early', 'rtl/periph/sar_adc_ctrl.v', "if (bitn == 3'd0) begin", "if (bitn == 3'd1) begin", ['tb_sar_adc_ctrl']),
 ('P3', 'FIFO accepts a push while full', 'rtl/periph/sync_fifo.v', 'wire do_push = push & (~full | do_pop);', 'wire do_push = push;', ['tb_sync_fifo']),
 ('P4', 'W1C clear beats a same-clock event', 'rtl/periph/apb_regs8.v', 'flags     <= (flags & ~clr) | set;', 'flags     <= (flags | set) & ~clr;', ['tb_apb_regs8']),
 ('P5', 'watermark off by one', 'rtl/periph/apb_regs8.v', "wire       wm_flag  = ({1'b0, fifo_level} >= {1'b0, wm_level});", "wire       wm_flag  = ({1'b0, fifo_level} > {1'b0, wm_level});", ['tb_apb_regs8']),
 ('P6', 'pop also on a write to ADC_DATA', 'rtl/periph/apb_regs8.v', 'assign fifo_pop = rd & (paddr == A_ADC_DATA);', 'assign fifo_pop = access & (paddr == A_ADC_DATA);', ['tb_apb_regs8']),
 ('P7', 'START not delayed by 1 clock', 'rtl/periph/timer_adc8_top.v', 'wire adc_trig = adc_start |', 'wire adc_trig = (psel & penable & pwrite & (paddr == 4\'h5) & pwdata[1]) |', ['tb_cpu_if', 'tb_soc']),
 ('P8', 'channel not latched on the pop', 'rtl/periph/apb_regs8.v', 'if (fifo_pop && !fifo_empty) begin lch <= fifo_dout[9:8]; lvalid <= 1\'b1; end', '', ['tb_apb_regs8']),
 ('C1', 'shadow flags take the current flags', 'rtl/cpu/irq_unit.v', 'sz <= flag_next_z; sc <= flag_next_c;', 'sz <= flag_next_z; sc <= sc;', ['tb_irq_unit', 'tb_cpu_irq']),
 ('C2', 'interrupted instruction not squashed', 'rtl/cpu/cpu_top.v', '.bubble         (id_ex_bubble | irq_take),', '.bubble         (id_ex_bubble),', ['tb_cpu_irq']),
 ('C3', 'interrupt taken while stalled', 'rtl/cpu/irq_unit.v', 'irq & ie & id_valid & ~stall & ~branch', 'irq & ie & id_valid & ~branch', ['tb_irq_unit', 'tb_cpu_irq']),
 ('C4', 'RETI does not restore the flags', 'rtl/cpu/cpu_top.v', '.restore    (irq_restore),', ".restore    (1'b0),", ['tb_cpu_irq']),
 ('C5', 'WFI wake always takes the interrupt', 'rtl/cpu/irq_unit.v', 'wire take_sleep = sleeping & irq & ie;', 'wire take_sleep = sleeping & irq;', ['tb_irq_unit', 'tb_cpu_irq']),
 ('C6', 'io_cs not gated with LD / ST', 'rtl/cpu/cpu_top.v', 'assign io_cs    = io_hit & (mem_mem_we | (mem_wb_sel & mem_reg_we)) & ~rst;', 'assign io_cs    = io_hit & ~rst;', ['tb_soc']),
 ('C7', 'RAM also written for the I/O page', 'rtl/cpu/cpu_top.v', '.mem_we     (mem_we_safe & ~io_hit),', '.mem_we     (mem_we_safe),', ['tb_soc']),
 ('C8', 'peripheral reset not inverted', 'rtl/soc_top.v', '.rst_n(~rst)', '.rst_n(rst)', ['tb_soc']),
]
def sources(kind, d):
    per = [f'{d}/rtl/periph/{f}' for f in sorted(os.listdir(f'{d}/rtl/periph'))]
    cpu = [f'{d}/rtl/cpu/{f}' for f in sorted(os.listdir(f'{d}/rtl/cpu')) if f.endswith('.v')]
    return {'periph': per, 'periph+afe': per + [f'{d}/tb/model/afe_model.v'], 'irq': [f'{d}/rtl/cpu/irq_unit.v'],
            'cpu': cpu + [f'{d}/tb/cpu/isa_reference_model.v'], 'soc': cpu + per + [f'{d}/rtl/soc_top.v', f'{d}/tb/model/afe_model.v']}[kind]
def run(tb, d):
    kind, top = TB[tb]; b = f'{d}/build'; os.makedirs(b, exist_ok=True)
    for f in os.listdir(f'{ROOT}/build'):
        if f.endswith('.mem'): shutil.copy(f'{ROOT}/build/{f}', b)
    r = subprocess.run(['iverilog', '-g2005', '-I', f'{d}/rtl/cpu', '-s', tb, '-o', f'{b}/{tb}.vvp'] + sources(kind, d) + [f'{d}/{top}'], capture_output=True, text=True)
    if r.returncode: return 'compile error'
    try: o = subprocess.run(['vvp', '-n', f'{tb}.vvp'], cwd=b, capture_output=True, text=True, timeout=240).stdout
    except subprocess.TimeoutExpired: return 'timeout'
    return 'PASS' if re.search(r'^PASS:', o, re.M) else 'FAIL'
sel = sys.argv[1:]; killed = 0; rows = []
for mid, what, f, old, new, tbs in MUT:
    if sel and mid not in sel: continue
    d = tempfile.mkdtemp(); shutil.copytree(f'{ROOT}/rtl', f'{d}/rtl'); shutil.copytree(f'{ROOT}/tb', f'{d}/tb')
    s = open(f'{d}/{f}').read(); assert old in s, (mid, old); open(f'{d}/{f}', 'w').write(s.replace(old, new, 1))
    res = {t: run(t, d) for t in tbs}; k = any(v != 'PASS' for v in res.values()); killed += k
    print(f'{mid:3s} {what:40s} ' + ', '.join(f'{t}: {"KILLED" if v != "PASS" else "survived"} ({v})' for t, v in res.items()), flush=True)
    shutil.rmtree(d)
print(f'RESULT: {killed} of {len(sel) if sel else len(MUT)} mutants killed')
