# On the Job Training, Phase 2

Capstone RTL design and verification project completed during Phase 2 of On the Job
Training (FPT University x HCL GUVI).

**Author: Vu Quoc Anh (SE203519)**

| Project | Summary | Source |
|---|---|---|
| [8-bit RISC CPU](8-bit%20RISC%20CPU/) | 8-bit RISC CPU with a five-stage pipeline, a 16-instruction 3-address ISA, register indirect memory access, and all hazards resolved in hardware | [src/](8-bit%20RISC%20CPU/src/) |

---

## 8-bit RISC CPU

A synthesizable 8-bit RISC processor core in Verilog with a classic five-stage pipeline
(IF, ID, EX, MEM, WB), eight 8-bit registers, and Harvard memories made of a 256 x 16-bit
instruction ROM and a 256 x 8-bit data RAM. Every data and control hazard is resolved in
hardware, through forwarding from MEM and WB, a write-first register file, load-use and flag
stalls, branches decided in ID at a cost of one cycle, and a `HLT` instruction that drains the
pipeline safely. The decoder selects which register each read port reads and flags whether each
port is really used, so the hazard logic compares only real reads and the overlapping 8-bit
immediate never causes a false stall. A two-pass Python assembler turns assembly code into ROM
images.

Verification covers 6 levels, from exhaustive unit tests to lockstep comparison against an
independent ISA model over 300 random programs. All **17 of 17** testbenches pass, with **115**
directed, **52,079** lockstep, and **22,383** invariant checks at **0** errors, and mutation
testing detects **12 of 12** injected bugs. Yosys maps the design to **180** flip-flops and
**233** LUTs with no latches or combinational loops, targeting the Digilent Basys 3.

See [8-bit RISC CPU](8-bit%20RISC%20CPU/) for the full description and the [source](8-bit%20RISC%20CPU/src/).
