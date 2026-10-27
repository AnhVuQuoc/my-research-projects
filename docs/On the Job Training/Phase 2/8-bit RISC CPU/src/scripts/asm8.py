#!/usr/bin/env python3
# =============================================================================
# File    : scripts/asm8.py
# Project : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
# Author  : Vu Quoc Anh (SE203519)
# Job     : 2-pass assembler for the 16-instruction ISA. Writes a 256-word
#           .mem file (4 hex digits per line, unused words = 0000 = NOP) and a
#           listing (.lst) with address, hex word and source line.
# Syntax  : one instruction per line; ";" starts a comment; "label:" defines a
#           label; ".org N" moves the location counter. Numbers: 12, 0x0C, label.
#             ADD/SUB/AND/OR/XOR rd, rs1, rs2     SHL/SHR rd, rs1
#             LDI/ADDI rd, imm8                   LD/ST rd, [rs1]
#             JMP/BZ/BNZ addr8                    NOP   HLT
# Usage   : python3 scripts/asm8.py asm/demo.asm rtl/program.mem
# =============================================================================
import re, sys

OPS = {'NOP': 0x0, 'ADD': 0x1, 'SUB': 0x2, 'AND': 0x3, 'OR': 0x4, 'XOR': 0x5, 'SHL': 0x6, 'SHR': 0x7,
       'LDI': 0x8, 'ADDI': 0x9, 'LD': 0xA, 'ST': 0xB, 'JMP': 0xC, 'BZ': 0xD, 'BNZ': 0xE, 'HLT': 0xF}

def reg(t, line):
    m = re.fullmatch(r'[Rr]([0-7])', t.strip())
    if not m: raise SystemExit(f'line {line}: bad register {t!r}')
    return int(m.group(1))

def num(t, labels, line, bits=8):
    t = t.strip()
    if t in labels: v = labels[t]
    else:
        try: v = int(t, 0)
        except ValueError: raise SystemExit(f'line {line}: bad number or unknown label {t!r}')
    if not 0 <= v < (1 << bits): raise SystemExit(f'line {line}: value {v} does not fit in {bits} bits')
    return v

def parse(path):
    items, labels, pc = [], {}, 0
    for n, raw in enumerate(open(path), 1):
        s = raw.split(';')[0].strip()
        if not s: continue
        while ':' in s:
            lab, s = s.split(':', 1)
            labels[lab.strip()] = pc; s = s.strip()
        if not s: continue
        if s.lower().startswith('.org'):
            pc = int(s.split()[1], 0); continue
        items.append((pc, n, s, raw.rstrip())); pc += 1
        if pc > 256: raise SystemExit(f'line {n}: program longer than 256 words')
    return items, labels

def encode(s, labels, line):
    parts = s.split(None, 1)
    mn = parts[0].upper(); args = [a.strip() for a in parts[1].split(',')] if len(parts) > 1 else []
    if mn not in OPS: raise SystemExit(f'line {line}: unknown instruction {mn}')
    op = OPS[mn] << 12
    if mn in ('NOP', 'HLT'):
        return op
    if mn in ('ADD', 'SUB', 'AND', 'OR', 'XOR'):
        rd, rs1, rs2 = (reg(a, line) for a in args); return op | rd << 9 | rs1 << 6 | rs2 << 3
    if mn in ('SHL', 'SHR'):
        rd, rs1 = (reg(a, line) for a in args); return op | rd << 9 | rs1 << 6
    if mn in ('LDI', 'ADDI'):
        return op | reg(args[0], line) << 9 | num(args[1], labels, line)
    if mn in ('LD', 'ST'):
        m = re.fullmatch(r'\[\s*([Rr][0-7])\s*\]', args[1])
        if not m: raise SystemExit(f'line {line}: expected [Rn] in {s!r}')
        return op | reg(args[0], line) << 9 | reg(m.group(1), line) << 6
    return op | num(args[0], labels, line)              # JMP, BZ, BNZ

def main(src, dst):
    items, labels = parse(src)
    mem, lst = [0] * 256, []
    for pc, line, s, raw in items:
        w = encode(s, labels, line); mem[pc] = w
        lst.append(f'{pc:3d}  {w:04X}  {raw}')
    open(dst, 'w').write('\n'.join(f'{w:04X}' for w in mem) + '\n')
    open(dst.rsplit('.', 1)[0] + '.lst', 'w').write('\n'.join(lst) + '\n')
    print(f'{src}: {len(items)} instructions -> {dst} (256 words)')

if __name__ == '__main__':
    if len(sys.argv) != 3: raise SystemExit('usage: asm8.py input.asm output.mem')
    main(sys.argv[1], sys.argv[2])
