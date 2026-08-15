# A Fused Carry-Save Processing Element with Bias-Balanced Approximation for Efficient Systolic Matrix Multiplication

> A drop-in systolic-array processing element that moves carry resolution out of the accumulation loop and cancels approximation bias with a free drain-time constant, preserving int8 DNN accuracy over long dot products.

|  |  |
|---|---|
| Course / Venue | Research paper, FPT University Ho Chi Minh Campus |
| Type | Research paper / Manuscript |
| Role | First author (Anh Q. Vu, Dung T. Le) |
| Date | 2026 |
| Tools | Verilog, Yosys, synth_xilinx (XC7Z020 target), approximate computing |

## Overview
Deep neural network inference is dominated by multiply-accumulate operations mapped onto systolic arrays, where the cost of a single processing element (PE) sets the efficiency of the whole accelerator. This work builds on a fused PPC/NPPC baseline and removes two of its limitations that matter for the long dot products of convolutional layers: a carry-propagating adder trapped inside the accumulation loop, and an approximation error that is biased rather than zero mean. The proposed PE keeps the running sum in redundant carry-save form and merges it only at drain, and it folds the Baugh-Wooley signed correction and the approximation compensation into a single constant added at drain time.

## Highlights
- Redundant carry-save accumulator that keeps carry resolution out of the per-cycle loop, so the critical path is decoupled from accumulator width.
- Constant-folded signed correction proven from an integer Baugh-Wooley identity, adding the sign and compensation offset once at drain.
- Bias-balanced approximate cells whose systematic error is cancelled by the free drain-time constant, addressing the linear muK bias growth that dominates long accumulations.
- All functional claims exhaustively verified.

## Key Results
- Cycle-limiting depth reduced from 47 to **26** gate levels, a **40 to 45%** reduction, at only a **4 to 7%** cell-count increase.
- Depth is **width-invariant** at 26 levels for both 17 and 28 bit accumulators, whereas the resolved baseline lengthens with width.
- Total RMS accumulation error cut by **22x**.
- Per-MAC bias reduced from +4.33 LSB to **+0.02 LSB**, activations shifted by more than 2 LSB from 54.7% to **0.0%**, and flipped ReLU decisions from 8.5% to **0.8%**.
- Eliminates the accumulator overflow that wrapped **72.4%** of dot products in the resolved 17-bit baseline on a length-1152 layer.

## Files
- [Full report](report.pdf)
