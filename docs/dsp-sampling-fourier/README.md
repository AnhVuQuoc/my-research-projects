# Signal Analysis, Sampling and the Fourier Transform

> Investigating the information lost when a continuous signal is sampled, and how the DFT reveals that loss, covering Nyquist-Shannon sampling, aliasing, spectral folding, linearity, Parseval's theorem, and audio decimation.

|  |  |
|---|---|
| Course / Venue | DGT302 Digital Signal Processing (Class IC2007-DGT302), FPT University. Lecturer: Le Phu Nguyen |
| Type | Lab report (Lab 1) |
| Role | Author, individual |
| Date | July 2026 |
| Tools | Python (NumPy, Matplotlib), DSP |

## Overview
This lab studies what happens to information when a continuous time signal is discretized, and how the Discrete Fourier Transform makes that loss visible. A reference signal with two tones (a 1 kHz sine plus a 3 kHz cosine, giving a 6 kHz Nyquist rate) is sampled in three regimes, 10 kHz (oversampled), 6 kHz (critically sampled), and 4 kHz (undersampled), and the resulting spectra are compared. The work then verifies the core properties of the DFT and quantifies the damage caused by decimating audio without an anti aliasing filter.

## Highlights
- Sampled one reference signal with two tones at three rates around the Nyquist boundary, to compare oversampling, critical sampling, and undersampling side by side.
- Demonstrated spectral folding. At 4 kHz the 3 kHz tone folds onto 1 kHz, so two tones collapse into a single component that cannot be told apart.
- Captured the fragile case of critical sampling, where phase alignment at exactly the Nyquist rate becomes ambiguous.
- Verified DFT linearity and Parseval's theorem numerically, confirming that energy is conserved between the time and frequency domains.
- Modeled 8x audio decimation with no anti aliasing stage, to expose the origin of the characteristic metallic artefact.

## Key Results
- Undersampling at 4 kHz folded the 3 kHz tone onto the 1 kHz tone, producing a single component of amplitude **sqrt(2)** from the superposition of the two folded tones.
- Parseval's theorem held to numerical precision, confirming that the DFT preserves the total signal energy.
- Unfiltered 8x decimation folded **61.5%** of the signal's energy back into the baseband, which is the measurable source of the metallic artefact.

## Files
- [Full report](report.pdf)
