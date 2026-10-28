# On the Job Training, Phase 1

Capstone RTL design and verification projects completed during Phase 1 of On the Job
Training (FPT University x HCL GUVI).

**Author: Vu Quoc Anh (SE203519)**

| Project | Summary | Source |
|---|---|---|
| [4-bit ALU](4-bit%20ALU/) | 4-bit ALU with eight single cycle operations and a sequential multiplier and divider, based on shifting, that reuse the ALU adder | [src/](4-bit%20ALU/src/) |
| [4-bit 5-Stage Pipelined CPU](4-bit%205-Stage%20Pipelined%20CPU/) | 4-bit RISC CPU with a five-stage pipeline, operand forwarding, hazard detection, and branch resolution in ID | [src/](4-bit%205-Stage%20Pipelined%20CPU/src/) |

---

## 4-bit ALU

A 4-bit arithmetic logic unit with 10 operations, namely eight single cycle operations (ADD,
SUB, AND, OR, XOR, NOT, SHL, SHR) and a sequential multiplier and divider (MUL, DIV), together
with carry, zero, overflow, negative, and divide by zero flags. The novel idea is that MUL and
DIV have no adder of their own. Three multiplexers selected by `busy` lend the ALU's own adder
to the multiplier and divider during their step clocks, which removes the need for a second
adder. All state lives in one clocked module, so the other seven submodules are combinational
and are tested exhaustively.

Verification uses 9 testbenches that check their own results, with more than **74,000** checked
cases, and mutation testing that caught **6 of 6** injected bugs. On an Artix-7 xc7a35t the
design uses **62** LUTs and **18** flip-flops, less than 1 percent of the device.

See [4-bit ALU](4-bit%20ALU/) for the full description and the [source](4-bit%20ALU/src/).

## 4-bit 5-Stage Pipelined CPU

A 4-bit RISC CPU upgraded from a three-stage pipeline to a classic five-stage pipeline (IF, ID,
EX, MEM, WB) with operand forwarding, a hazard detection unit, a write-first register file, and
branch resolution in ID, so a taken branch costs one cycle instead of two. Hazards are solved in
hardware through forwarding from MEM and WB, a one-cycle load-use stall, and a one-cycle flag
stall for `JZ`.

Verification uses 16 testbenches that check their own results, exhaustive unit tests, and
lockstep comparison against an independent ISA model over 300 random programs. The comparison
runs **368,830** lockstep checks and **24,942** invariant checks with **0** errors, and mutation
testing caught **8 of 8** injected bugs.

See [4-bit 5-Stage Pipelined CPU](4-bit%205-Stage%20Pipelined%20CPU/) for the full description
and the [source](4-bit%205-Stage%20Pipelined%20CPU/src/).
