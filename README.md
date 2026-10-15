# Research and Coursework Portfolio

A curated portfolio of research papers and university coursework by Vu Quoc Anh
(SE203519), FPT University, Ho Chi Minh City. The work spans edge AI and embedded
systems, digital and analog circuit design, IC and semiconductor design, and digital
signal processing.

Each project lives in its own folder under [`docs/`](docs/) with a short write-up and the
full report as a PDF. Click a project title for its summary, or the PDF link to open the
report.

---

## Research Papers

| Project | Summary | Report |
|---|---|---|
| [Edge Voice and Gesture-Controlled Lighting](docs/edge-computing-atc26/) | Contactless smart lighting on an ESP32 using on-device TinyML keyword spotting and gesture sensing (ATC2026 submission) | [PDF](docs/edge-computing-atc26/report.pdf) |
| [FFT Spectrum Analyzer IP Core](docs/audio-spectrum-analyzer/) | 256-point R2SDF FFT audio analyzer in Verilog on PYNQ-Z2, verified bit-exact against a Python golden model | [PDF](docs/audio-spectrum-analyzer/report.pdf) |
| [Approximate Systolic Array PE](docs/carry-save-pe-systolic-array/) | Fused carry-save processing element with bias-balanced approximation for efficient DNN matrix multiplication | [PDF](docs/carry-save-pe-systolic-array/report.pdf) |

## Signal Processing (DGT302)

| Project | Summary | Report |
|---|---|---|
| [Sampling and the Fourier Transform](docs/dsp-sampling-fourier/) | Nyquist-Shannon sampling, aliasing, the DFT, Parseval's theorem, and audio decimation (Lab 1) | [PDF](docs/dsp-sampling-fourier/report.pdf) |
| [LTI Modeling of Audio and Room Acoustics](docs/dsp-lti-audio-acoustics/) | FIR/IIR equalizer design, reverberation by convolution, and inverse-filter dereverberation | [PDF](docs/dsp-lti-audio-acoustics/report.pdf) |

## Communication System (COS201)

| Project | Summary | Report |
|---|---|---|
| [FFT Spectrum Analyzer IP Core](docs/audio-spectrum-analyzer/) | 256-point R2SDF FFT audio analyzer in Verilog on PYNQ-Z2, verified bit-exact against a Python golden model | [PDF](docs/audio-spectrum-analyzer/report.pdf) |

## Analog CMOS

| Project | Summary | Report |
|---|---|---|
| [MOSFET Characteristics](docs/mosfet-characteristics/) | Simulation-based PMOS and NMOS output and transfer characteristics and W/L sizing effects (Lab 1) | [PDF](docs/mosfet-characteristics/report.pdf) |
| [CMOS Inverter: Circuit to Layout](docs/cmos-inverter-layout/) | CMOS inverter design, VTC and transient analysis, and transistor sizing in Cadence Virtuoso (Lab 2) | [PDF](docs/cmos-inverter-layout/report.pdf) |
| [Combinational MOS Logic Circuit](docs/combinational-mos-logic-circuit/) | Transistor-level combinational logic design and transient verification in Cadence (Lab 3) | [PDF](docs/combinational-mos-logic-circuit/report.pdf) |
| [Sequential MOS Logic Circuit](docs/sequential-mos-logic-circuit/) | Transistor-level clocked storage element with Q and Qbar verification in Cadence (Lab 4) | [PDF](docs/sequential-mos-logic-circuit/report.pdf) |

## Circuits and Embedded Systems

| Project | Summary | Report |
|---|---|---|
| [4-to-1 Multiplexer](docs/mux-4to1/) | Truth table, K-map, gate schematic, simulation, and PCB verification of a 4-to-1 MUX (DIC201) | [PDF](docs/mux-4to1/report.pdf) |
| [Non-Inverting Amplifier](docs/non-inverting-amplifier/) | Op-amp amplifier modeled in LTspice and realized on PCB in Proteus (ELC201, Lab 3) | [PDF](docs/non-inverting-amplifier/report.pdf) |
| [Full-Wave Voltage Doubler](docs/voltage-doubler/) | Delon voltage doubler in LTspice with a load sweep on output level and ripple (ELC201) | [PDF](docs/voltage-doubler/report.pdf) |
| [VisiBike Smart Bicycle Lighting](docs/visibike-smart-lighting/) | STM32 Nucleo-F429ZI driving turn signals and a brake light through a TB6612FNG driver | [PDF](docs/visibike-smart-lighting/report.pdf) |

## Verilog RTL/Verification

| Project | Summary | Report |
|---|---|---|
| [9-IP RTL Design and Verification Suite](docs/9ips-rtl-verification/) | Nine Verilog IP blocks from combinational logic to APB and UART peripherals with layered verification | [Source](docs/9ips-rtl-verification/src/) |

## On the Job Training

### Phase 1

| Project | Summary | Report |
|---|---|---|
| [4-bit ALU](docs/On%20the%20Job%20Training/Phase%201/4-bit%20ALU/) | 4-bit ALU with eight single-cycle operations and a sequential shift-based multiplier/divider that reuses the ALU adder | [Source](docs/On%20the%20Job%20Training/Phase%201/4-bit%20ALU/src/) |
| [4-bit 5-Stage Pipelined CPU](docs/On%20the%20Job%20Training/Phase%201/4-bit%205-Stage%20Pipelined%20CPU/) | 4-bit RISC CPU with a five-stage pipeline, operand forwarding, hazard detection, and branch resolution in ID | [Source](docs/On%20the%20Job%20Training/Phase%201/4-bit%205-Stage%20Pipelined%20CPU/src/) |

---

## Repository layout

```
docs/
  <project>/
    README.md     # high-level summary of the project
    report.pdf    # the full, viewable report
    src/          # source code (only for projects that have it)
```

Full-report PDFs live inside each project's folder so they render directly on GitHub.
