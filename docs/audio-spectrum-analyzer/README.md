# Design and Bit-Exact Verification of a 256-Point R2SDF FFT Audio Spectrum Analyzer IP Core on PYNQ-Z2

> A real time audio spectrum analyzer IP core built around a 256-point R2SDF FFT in Q1.15 fixed point with AXI4-Stream interfaces, verified bit-exact against a Python golden model and closed on timing on the PYNQ-Z2.

|  |  |
|---|---|
| Course / Venue | COS201 Communication Systems, FPT University |
| Type | Course project (hardware IP core) |
| Role | Group project |
| Date | 2026 |
| Tools | Verilog 2001, Vivado 2020.2+, Python (NumPy), PYNQ-Z2 (Zynq XC7Z020) |

## Overview
This IP core computes a 256-point FFT of a streaming audio signal and reduces each transform to a 128-bin single sided magnitude spectrum plus a per-frame spectral peak. The architecture uses Cooley-Tukey decimation in frequency in the R2SDF (Radix-2 Single-path Delay Feedback) form, Q1.15 fixed point arithmetic with per-stage scaling, a three-multiply Karatsuba complex product, a Hann window, and an alpha-max-beta-min magnitude estimator. The design is synthesized, implemented, timing closed, and delivered as a programmable bitstream.

## Highlights
- Fully open RTL paired with a bit-accurate Python model that both generates the coefficient memories and serves as the verification oracle, making coefficient mismatch structurally impossible.
- Bottom-up bit-exact verification at every level of the hierarchy, from twiddle ROM and butterfly up to the full system.
- Eight R2SDF stages using the theoretical minimum delay-line memory of N minus 1 equal to 255 complex words.
- End-to-end valid gating, so the pipeline advances in the sample domain and runs from an arbitrarily sparse source with no FIFO or rate matcher.
- Post place and route PPA characterization that separates measured numbers from analytically derived ones.

## Key Results
- Bit-exact against the Python oracle at all **7** verification levels.
- Fixed point accuracy of **58 to 61.6 dB** SQNR (Q1.15 versus float64), with a 6.02 dB/bit slope and no overflow.
- **24** DSP48E1 blocks, matching the analytic count 3(log2 N minus 1) + 3 exactly.
- Timing met with **WNS +2.510 ns** at 49.98 MHz, a real time margin of about **1040x** over the 48 kS/s requirement.
- Constant core latency of **291** valid samples per frame, and a slice LUT utilization of **8.33%**.

## Contents
- [Full report](report.pdf)
- [Source code](src/) (RTL, Python golden model, simulation vectors, constraints, bitstream)
- [Detailed technical writeup](src/README.md) with full module reference, verification tables, and PPA analysis

## My Contribution
- Group project. Contributed to RTL design, the Python golden model and verification flow, and board bring-up.
