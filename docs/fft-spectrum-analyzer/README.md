# Design, Bit-Exact Verification, and PPA Characterization of a 256-Point R2SDF FFT Audio Spectrum Analyzer IP Core on Zynq-7000

> A 256-point R2SDF FFT audio spectrum analyzer IP core in Verilog, verified bit-exact against a Python golden model.

|  |  |
|---|---|
| **Course / Venue** | Standalone IEEE-style research paper |
| **Type** | Research paper / Manuscript |
| **Role** | Lead author · Group (6 members) |
| **Date** | 2026 |
| **Tools** | Verilog, Vivado, Python (golden model), Zynq-7000 / PYNQ-Z2 |

## Overview
This paper presents a 256-point radix-2 single-path delay-feedback (R2SDF) FFT audio spectrum analyzer IP core implemented in Verilog on a Xilinx XC7Z020 (PYNQ-Z2). The design uses Q1.15 fixed-point arithmetic, a Hann window, an α-max-β-min magnitude estimator, and AXI4-Stream framing. A layered functional verification methodology checks every block bit-exact against a Python reference model, and the design is fully characterized for power, performance, and area (PPA).

## Highlights
- Radix-2 single-path delay-feedback (R2SDF) pipelined FFT architecture in Verilog.
- Q1.15 fixed-point datapath with Hann windowing and a low-cost α-max-β-min magnitude estimator.
- AXI4-Stream framing for streaming-audio integration on Zynq-7000.
- Layered functional verification: every block verified bit-exact against a Python golden model.
- R2SDF-vs-R2²SDF architectural trade-off analysis for area and throughput.

## Key Results
- Isolates a pipeline-framing error class (an 8-cycle latency error, 283 vs 291 valid samples) that value-level golden models cannot detect.
- Achieves timing closure at ~64 MHz Fmax on the XC7Z020.
- Reports full FPGA resource usage and PPA characterization.

## My Contribution
- Lead author: designed the R2SDF FFT datapath, defined the layered bit-exact verification methodology, and characterized the PPA results.

📄 **[Read the full report](report.pdf)**
