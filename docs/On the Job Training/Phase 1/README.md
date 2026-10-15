# On the Job Training: Phase 1

Capstone RTL design and verification projects completed during Phase 1 of On the Job
Training (FPT University x HCL GUVI).

**Author: Vu Quoc Anh (SE203519)**

| Project | Summary | Source |
|---|---|---|
| [4-bit ALU](4-bit%20ALU/) | 4-bit ALU with eight single-cycle operations and a sequential shift-based multiplier and divider that reuse the ALU adder | [src/](4-bit%20ALU/src/) |
| [4-bit 5-Stage Pipelined CPU](4-bit%205-Stage%20Pipelined%20CPU/) | 4-bit RISC CPU with a five-stage pipeline, operand forwarding, hazard detection, and branch resolution in ID | [src/](4-bit%205-Stage%20Pipelined%20CPU/src/) |

---

## 4-bit ALU

A 4-bit arithmetic logic unit with 10 operations: eight single-cycle operations (ADD, SUB,
AND, OR, XOR, NOT, SHL, SHR) and a sequential multiplier and divider (MUL, DIV), plus carry,
zero, overflow, negative and divide-by-zero flags. The novel idea is that MUL and DIV own no
adder: three multiplexers selected by `busy` lend the ALU's own adder to the multiplier and
divider for their step clocks, which removes a second adder. All state lives in one clocked
module, so the other seven sub-modules are combinational and tested exhaustively.

Verification uses 9 self-checking testbenches with more than **74,000** checked cases and
mutation testing that caught **6 of 6** injected bugs. On an Artix-7 xc7a35t the design uses
**62** LUTs and **18** flip-flops, less than 1 percent of the device.

See [4-bit ALU](4-bit%20ALU/) for the full write-up and [source](4-bit%20ALU/src/).

## 4-bit 5-Stage Pipelined CPU

A 4-bit RISC CPU written in Verilog-2001, upgraded from a three-stage pipeline to a classic
five-stage pipeline (IF, ID, EX, MEM, WB) with operand forwarding, a hazard detection unit, a
write-first register file, and branch resolution in ID so a taken branch costs one cycle
instead of two. Hazards are solved in hardware: forwarding from MEM and WB, a one-cycle
load-use stall, and a one-cycle flag stall for `JZ`.

Verification uses 16 self-checking testbenches, exhaustive unit tests, and lockstep comparison
against an independent ISA model over 300 random programs: **368,830** lockstep plus
**24,942** invariant checks with **0** errors, and mutation testing that caught **8 of 8**
injected bugs.

See [4-bit 5-Stage Pipelined CPU](4-bit%205-Stage%20Pipelined%20CPU/) for the full write-up
and [source](4-bit%205-Stage%20Pipelined%20CPU/src/).
