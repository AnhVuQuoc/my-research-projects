# Linear Time Invariant Modeling of Audio Equalization and Room Acoustics

> Applying LTI system theory to parametric equalization and room reverberation, through FIR and IIR filter design, reverberation by convolution, and dereverberation by inverse filtering.

|  |  |
|---|---|
| Course / Venue | DGT302 Digital Signal Processing (Class IC2007-DGT302), FPT University. Lecturer: Le Phu Nguyen |
| Type | Group project (Task 1) |
| Role | Author, group of 5 |
| Date | July 2026 |
| Tools | Python (NumPy, SciPy), DSP |

## Overview
This project uses linear time invariant (LTI) system theory to connect two audio problems, parametric equalization and room reverberation. A single 5.5 s, 16 kHz signal that resembles speech is passed through four stages. These are a 101-tap Hamming FIR low pass and high pass pair, a Butterworth IIR pair of matched order, convolution with two synthesized room impulse responses (RIRs), and dereverberation by inverse filtering. The pipeline compares the filter families directly and studies how well reverberation can be reversed under ideal and noisy conditions.

## Highlights
- Designed matched equalization pairs in two families, namely 101-tap FIR filters with a Hamming window and Butterworth IIR filters of matched order realized through the bilinear transform.
- Compared the tradeoffs between FIR and IIR filters (linear phase and stability versus efficiency and roll off) on the same input signal.
- Synthesized two room impulse responses at T60 of 0.30 s and 1.80 s and applied reverberation by convolution.
- Recovered the reverberation time T60 directly from the Schroeder energy decay curve.
- Implemented dereverberation by inverse filtering, contrasting exact inversion with inversion limited by noise and stabilized by Tikhonov/Wiener regularization.

## Key Results
- Both target reverberation times, T60 of **0.30 s** and **1.80 s**, were recovered from the Schroeder energy decay curve, which validates the acoustic model.
- Exact inverse filtering fully reversed the reverberation when there was no noise, but became ill conditioned once noise was present.
- Tikhonov/Wiener regularization restored a stable and usable dereverberation result under realistic noise, at the cost of exactness.

## My Contribution
- Contributed as one of five members of the group submission (Vu Quoc Anh, SE203519).

## Files
- [Full report](report.pdf)
