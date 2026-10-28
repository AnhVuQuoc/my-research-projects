# Research and Coursework Portfolio

A curated portfolio of research papers, university coursework, and On the Job Training Capstone
projects by Vu Quoc Anh, a third year student at FPT University. The work spans edge AI, digital
signal processing, digital front end design (RTL and verification), and analog circuit design.

Each project lives in its own folder under [`docs/`](docs/) with a short summary and the full
report as a PDF. Click a project title to read its summary, or click the PDF link to open the
report.

---

## Research Papers

| Project | Summary | Report |
|---|---|---|
| [Edge Voice and Gesture Controlled Lighting](docs/edge-computing-atc26/) | Contactless smart lighting on an ESP32, with TinyML keyword spotting and gesture sensing running on the device (ATC2026 submission) | [PDF](docs/edge-computing-atc26/report.pdf) |
| [FFT Spectrum Analyzer IP Core](docs/audio-spectrum-analyzer/) | 256-point R2SDF FFT audio analyzer in Verilog on the PYNQ-Z2, verified bit-exact against a Python golden model | [PDF](docs/audio-spectrum-analyzer/report.pdf) |
| [Approximate Systolic Array PE](docs/carry-save-pe-systolic-array/) | Fused carry-save processing element with bias balanced approximation for efficient DNN matrix multiplication | [PDF](docs/carry-save-pe-systolic-array/report.pdf) |

## Signal Processing (DGT302)

| Project | Summary | Report |
|---|---|---|
| [Sampling and the Fourier Transform](docs/dsp-sampling-fourier/) | Nyquist-Shannon sampling, aliasing, the DFT, Parseval's theorem, and audio decimation (Lab 1) | [PDF](docs/dsp-sampling-fourier/report.pdf) |
| [LTI Modeling of Audio and Room Acoustics](docs/dsp-lti-audio-acoustics/) | FIR and IIR equalizer design, reverberation by convolution, and dereverberation by inverse filtering | [PDF](docs/dsp-lti-audio-acoustics/report.pdf) |

## Communication System (COS201)

| Project | Summary | Report |
|---|---|---|
| [FFT Spectrum Analyzer IP Core](docs/audio-spectrum-analyzer/) | 256-point R2SDF FFT audio analyzer in Verilog on the PYNQ-Z2, verified bit-exact against a Python golden model | [PDF](docs/audio-spectrum-analyzer/report.pdf) |

## Analog CMOS

| Project | Summary | Report |
|---|---|---|
| [MOSFET Characteristics](docs/mosfet-characteristics/) | Simulation of PMOS and NMOS output and transfer characteristics and of W/L sizing effects (Lab 1) | [PDF](docs/mosfet-characteristics/report.pdf) |
| [CMOS Inverter from Circuit to Layout](docs/cmos-inverter-layout/) | CMOS inverter design, VTC and transient analysis, and transistor sizing in Cadence Virtuoso (Lab 2) | [PDF](docs/cmos-inverter-layout/report.pdf) |
| [Combinational MOS Logic Circuit](docs/combinational-mos-logic-circuit/) | Combinational logic designed at the transistor level and verified by transient simulation in Cadence (Lab 3) | [PDF](docs/combinational-mos-logic-circuit/report.pdf) |
| [Sequential MOS Logic Circuit](docs/sequential-mos-logic-circuit/) | Clocked storage element designed at the transistor level, with Q and Qbar verified in Cadence (Lab 4) | [PDF](docs/sequential-mos-logic-circuit/report.pdf) |

## Circuits and Embedded Systems

| Project | Summary | Report |
|---|---|---|
| [4-to-1 Multiplexer](docs/mux-4to1/) | Truth table, K-map, gate schematic, simulation, and PCB verification of a 4-to-1 MUX (DIC201) | [PDF](docs/mux-4to1/report.pdf) |
| [Non Inverting Amplifier](docs/non-inverting-amplifier/) | Operational amplifier circuit modeled in LTspice and realized on a PCB in Proteus (ELC201, Lab 3) | [PDF](docs/non-inverting-amplifier/report.pdf) |
| [Full Wave Voltage Doubler](docs/voltage-doubler/) | Delon voltage doubler simulated in LTspice, with a load sweep of the output level and ripple (ELC201) | [PDF](docs/voltage-doubler/report.pdf) |
| [VisiBike Smart Bicycle Lighting](docs/visibike-smart-lighting/) | STM32 Nucleo-F429ZI driving turn signals and a brake light through a TB6612FNG driver | [PDF](docs/visibike-smart-lighting/report.pdf) |

## Verilog RTL/Verification

| Project | Summary | Report |
|---|---|---|
| [9-IP RTL Design and Verification Suite](docs/9ips-rtl-verification/) | Nine Verilog IP blocks, from combinational logic to APB and UART peripherals, with layered verification | [Source](docs/9ips-rtl-verification/src/) |

## On the Job Training

### Phase 1

| Project | Summary | Report |
|---|---|---|
| [4-bit ALU](docs/On%20the%20Job%20Training/Phase%201/4-bit%20ALU/) | 4-bit ALU with eight single cycle operations and a sequential multiplier and divider, based on shifting, that reuse the ALU adder | [Source](docs/On%20the%20Job%20Training/Phase%201/4-bit%20ALU/src/) |
| [4-bit 5-Stage Pipelined CPU](docs/On%20the%20Job%20Training/Phase%201/4-bit%205-Stage%20Pipelined%20CPU/) | 4-bit RISC CPU with a five-stage pipeline, operand forwarding, hazard detection, and branch resolution in ID | [Source](docs/On%20the%20Job%20Training/Phase%201/4-bit%205-Stage%20Pipelined%20CPU/src/) |

### Phase 2

| Project | Summary | Report |
|---|---|---|
| [8-bit RISC CPU](docs/On%20the%20Job%20Training/Phase%202/8-bit%20RISC%20CPU/) | 8-bit RISC CPU with a five-stage pipeline, a 16-instruction 3-address ISA, register indirect memory access, and all hazards resolved in hardware | [Source](docs/On%20the%20Job%20Training/Phase%202/8-bit%20RISC%20CPU/src/) |

---

## Repository layout

```
docs/
  <project>/
    README.md     # high-level summary of the project
    report.pdf    # the full, viewable report
    src/          # source code (only for projects that have it)
```

The full report PDFs live inside each project's folder, so they render directly on GitHub.
