# 8-Bit RISC CPU with a 5-Stage Pipeline

![HDL](https://img.shields.io/badge/HDL-VivadoVerilog-blue)
![Target](https://img.shields.io/badge/FPGA-Basys%203%20(xc7a35t)-orange)
![Tests](https://img.shields.io/badge/testbenches-17%2F17%20PASS-brightgreen)
![Mutants](https://img.shields.io/badge/mutation%20testing-12%2F12%20killed-brightgreen)

This project is a synthesizable 8-bit RISC processor core written in Verilog, built around a classic **IF, ID, EX, MEM, WB** pipeline.
The core implements a 16-instruction, 3-address ISA with register indirect memory access, and it resolves
every data and control hazard in hardware. It does so through forwarding from MEM and WB, a write-first register file,
load-use and flag stalls, branches that are decided in ID, and a halt instruction that drains the pipeline safely.

Every design decision was documented before the RTL was written, and the design is verified at 6 levels, ranging from
exhaustive unit tests to lockstep comparison against an independent ISA model and mutation testing.

> Vu Quoc Anh (SE203519) · Capstone 2, VLSI Design Program 

---

## Highlights

- **Instruction dependent register reads.** The decoder chooses which register each read port reads
  (`rd` for `ADDI` and for the data of `ST`), and it flags whether each port is actually used. Hazard detection
  and forwarding therefore compare only the registers that are really read.
- **No false stalls.** The 8-bit immediate overlaps the `rs1` and `rs2` fields, so the `uses_a` / `uses_b` flags
  prevent the bits of a constant from triggering stalls.
- **Register indirect load and store.** Addresses come from registers and are forwarded like any other operand.
  As a result, a `ST` can receive a forwarded address and forwarded data in the same cycle.
- **Branches decided in ID.** A taken `JMP`, `BZ` or `BNZ` costs exactly 1 cycle.
- **Safe halt.** `HLT` is decided in ID, freezes the fetch stage and lets older instructions retire. A `HLT` that is fetched on a
  wrong path is flushed before it can stop the CPU.
- **Predictable timing.** For 6 test programs, the cycle in which `HLT` retires was predicted by hand
  (`4 + k + bubbles`) before simulation, and all 6 predictions match the simulated results.
- **Toolchain included.** A 2-pass Python assembler converts readable assembly code into 256-word ROM images.

---

## Architecture

![5-stage datapath](docs/top_level_diagram.png)

*Black lines show data moving forward, blue lines show data moving backward (forwarding and write back), and orange dashed lines show control signals.*

| Stage | Function | Main blocks |
|---|---|---|
| **IF** | fetches the word at PC and chooses either PC + 1 or the branch target | `program_counter`, `instruction_memory`, `PC_MUX` |
| **ID** | decodes the instruction, selects and reads registers, detects hazards, and decides branches and halt | `control_unit`, `register_file`, `hazard_unit`, `halt_unit` |
| **EX** | selects the newest copies of the operands, computes the result, and updates the flags | `forwarding_unit`, `mux3` x2, `OPERAND_MUX`, `alu`, `flag_register` |
| **MEM** | reads or writes the data memory | `data_memory` |
| **WB** | chooses the ALU result or the memory data and writes it to the register file | `WB_MUX`, register file write port |

| Parameter | Value |
|---|---|
| Data width | 8 bits |
| Registers | R0 to R7, 8 bits each (R0 is an ordinary register) |
| Instruction | 16 bits, 1 word per instruction |
| Memories | 256 x 16-bit instruction ROM and 256 x 8-bit data RAM (Harvard) |
| Flags | Z, and C (carry for ADD/ADDI, borrow for SUB, and the shifted out bit for SHL/SHR) |
| Reset | synchronous and active high, with data memory writes blocked during reset |

---

## Instruction set

```
 15    12 11   9 8    6 5    3 2    0
+--------+------+------+------+------+
| opcode |  rd  | rs1  | rs2  | 000  |   R format
+--------+------+------+------+------+
| opcode |  rd  | -  |   imm8/addr8  |   I and J formats (imm8 overlaps rs1 and rs2)
+--------+------+----+---------------+
```

| Op | Instruction | Operation | Flags |
|---|---|---|---|
| 0 | `NOP` | no operation (also used as the pipeline bubble, word `0000`) | none |
| 1 | `ADD rd, rs1, rs2` | rd = rs1 + rs2 | Z, C |
| 2 | `SUB rd, rs1, rs2` | rd = rs1 − rs2 | Z, C (borrow) |
| 3, 4, 5 | `AND`, `OR`, `XOR rd, rs1, rs2` | bitwise operation | Z |
| 6, 7 | `SHL`, `SHR rd, rs1` | shift by 1 | Z, C = shifted out bit |
| 8 | `LDI rd, imm8` | rd = imm8 | none |
| 9 | `ADDI rd, imm8` | rd = rd + imm8 | Z, C |
| A | `LD rd, [rs1]` | rd = dmem[rs1] | none |
| B | `ST rd, [rs1]` | dmem[rs1] = rd | none |
| C | `JMP addr8` | PC = addr8 | none |
| D, E | `BZ`, `BNZ addr8` | branch if Z = 1 / Z = 0 | none |
| F | `HLT` | stops fetching while older instructions finish | none |

![Field to wire map](docs/field_map.png)

*Each field becomes a wire of `cpu_top`, and the decoder turns `rd`, `rs1` and `rs2` into the read addresses `ra` and `rb`.*

---

## Hazard handling

| Hazard | Mechanism | Cost |
|---|---|---|
| ALU result needed 1 or 2 instructions later | forwarding from MEM or WB (MEM has priority) | 0 |
| result needed 3 instructions later | write-first bypass in the register file | 0 |
| `LD` result needed by the next instruction (on any port, including store data and addresses) | 1-cycle load-use stall, followed by forwarding from WB | 1 cycle |
| `BZ` / `BNZ` immediately after an instruction that writes Z | 1-cycle flag stall | 1 cycle |
| taken branch | decided in ID, with 1 fetched word flushed | 1 cycle |
| `HLT` | PC is frozen, IF/ID is flushed, and the pipeline drains | none |

A stall holds PC and IF/ID and inserts a bubble into ID/EX. Because the bubble writes nothing, the stall
condition clears by itself after exactly 1 cycle.

![Pipeline chart of prog_mem](docs/pipeline_prog_mem.png)

*This pipeline chart was generated from simulation. It shows load-use stalls on port A (cycle 7) and on the store data port B
(cycle 12), and `HLT` retires in cycle 17 = 4 + 11 instructions + 2 bubbles.*

---

## Verification

| Level | Method | Scale |
|---|---|---|
| Unit, exhaustive | every input combination of `alu`, `mux2`, `control_unit`, `hazard_unit` and `forwarding_unit` | up to 655,360 cases |
| Unit, random | sequential modules and `mux3` checked against reference models | 2,000 to 100,000 cases |
| CPU, directed | 6 programs, in which every retirement, the `HLT` cycle and the drain are checked against hand calculations | 115 checks |
| CPU, lockstep | every retirement compared with an independent ISA model on 300 random programs | 52,079 comparisons |
| Invariants and coverage | pipeline protocol rules checked every cycle, plus 20 coverage goals (covering every hazard type) | all goals reached |
| Mutation testing | 12 typical design bugs inserted one at a time | 12 of 12 detected |

```
PASS: tb_cpu (Vu Quoc Anh, SE203519) 115 directed + 52079 lockstep + 22383 invariant checks, 0 errors
```

All 17 testbenches pass.

| Program | Focus | CPI after pipeline fill |
|---|---|---|
| `demo`, `prog_arith`, `prog_logic` | forwarding, arithmetic and shifts | 1.00 |
| `prog_mem` | register indirect memory access and load-use stalls | 1.18 |
| `prog_branch` | a loop with `BNZ`, flag stalls and flushes | 1.52 |

---

## Synthesis

Yosys (`synth_xilinx -family xc7`) maps the design to **180 flip-flops and 233 LUTs**, with the data memory implemented as
distributed RAM and with no latches or combinational loops. A Vivado project, together with timing and bitstream scripts, is
provided for the Digilent Basys 3 board.

---

## Repository structure

```
rtl/          17 modules, shared header cpu_defs.vh, program.mem
tb/           17 self-checking testbenches, independent ISA reference model, test programs
asm/          assembly sources of the test programs
scripts/      asm8.py (assembler), regression scripts, mutation_test.py, Vivado Tcl scripts
constraints/  basys3_cpu_top.xdc
docs/         figures used in this README
```
---

**Author:** Vu Quoc Anh (SE203519) · Capstone 2, VLSI Design Program
