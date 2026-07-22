# Systolic Array for Matrix Multiplication on FPGA

> An energy-efficient 4×4 approximate systolic array for DNN matrix multiplication on FPGA.

|  |  |
|---|---|
| **Course / Venue** | Journal / IEEE-style paper |
| **Type** | Research paper / Manuscript |
| **Role** | Co-author · Group (6 members) |
| **Date** | 2026 |
| **Tools** | Verilog/VHDL, FPGA, Vivado |

## Overview
Matrix multiplication dominates the compute cost of deep neural networks, making the efficiency of its hardware accelerators critical. This paper proposes an energy-efficient 4×4 systolic array architecture on FPGA that replaces exact processing elements with approximate signed PEs. By trading arithmetic precision for reduced hardware complexity, the design lowers energy, critical-path delay, and logic utilization while keeping errors within acceptable limits for image processing and ML workloads.

## Highlights
- Energy-efficient 4×4 systolic array architecture targeting DNN matrix multiplication on FPGA.
- Approximate signed processing elements (PEs) in place of exact PEs.
- PEs built from optimized Partial Product Cells (PPC) and NAND-based Partial Product Cells (NPPC).
- Precision-for-efficiency trade-off tuned to stay within acceptable error bounds for image processing and ML.
- Spans FPGA hardware design, approximate computing, systolic arrays, and AI acceleration.

## Key Results
- Reduced hardware complexity, energy consumption, critical-path delay, and logic utilization versus exact PE baselines.
- Output errors kept within acceptable limits for image processing and machine-learning workloads.

## My Contribution
- Co-author: contributed to the design and evaluation of the approximate processing-element architecture and its FPGA implementation.

📄 **[Read the full report](report.pdf)**
