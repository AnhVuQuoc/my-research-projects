# A Fused Carry-Save Processing Element with Bias Balanced Approximation for Efficient Systolic Matrix Multiplication

> A processing element that directly replaces the baseline element in a systolic array. It moves carry resolution out of the accumulation loop and cancels the approximation bias with a free constant added at drain time, which preserves int8 DNN accuracy over long dot products.

|  |  |
|---|---|
| Course / Venue | Research paper, FPT University Ho Chi Minh Campus |
| Type | Research paper / Manuscript |
| Role | First author (Anh Q. Vu, Dung T. Le) |
| Date | 2026 |
| Tools | Verilog, Yosys, synth_xilinx (XC7Z020 target), approximate computing |

## Overview
Deep neural network inference is dominated by multiply and accumulate operations mapped onto systolic arrays, where the cost of a single processing element (PE) sets the efficiency of the whole accelerator. This work builds on a fused PPC/NPPC baseline and removes two of its limitations that matter for the long dot products of convolutional layers. The first is an adder that propagates carries and is trapped inside the accumulation loop. The second is an approximation error that is biased rather than zero mean. The proposed PE keeps the running sum in redundant carry-save form and merges it only at drain, and it folds the Baugh-Wooley signed correction and the approximation compensation into a single constant added at drain time.

## Highlights
- A redundant carry-save accumulator that keeps carry resolution out of the loop that runs every cycle, so the critical path no longer depends on the accumulator width.
- A signed correction folded into a constant, proven from an integer Baugh-Wooley identity, which adds the sign and compensation offset once at drain.
- Approximate cells with balanced bias, whose systematic error is cancelled by the free constant added at drain time. This addresses the linear muK bias growth that dominates long accumulations.
- All functional claims are verified exhaustively.

## Key Results
- The depth that limits the cycle time is reduced from 47 to **26** gate levels, a **40 to 45%** reduction, at the cost of only a **4 to 7%** increase in cell count.
- The depth is **independent of width**, staying at 26 levels for both 17 and 28 bit accumulators, whereas the resolved baseline grows longer with width.
- The total RMS accumulation error is cut by **22x**.
- The bias per MAC is reduced from +4.33 LSB to **+0.02 LSB**, the share of activations shifted by more than 2 LSB falls from 54.7% to **0.0%**, and the share of flipped ReLU decisions falls from 8.5% to **0.8%**.
- The design eliminates the accumulator overflow that wrapped **72.4%** of dot products in the resolved 17-bit baseline on a layer of length 1152.

## Files
- [Full report](report.pdf)
