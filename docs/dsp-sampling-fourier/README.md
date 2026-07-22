# Signal Analysis, Sampling and the Fourier Transform

> Investigating information loss when a continuous signal is sampled, and how the DFT exposes it — Nyquist–Shannon sampling, aliasing, spectral folding, linearity, Parseval, and audio decimation.

|  |  |
|---|---|
| **Course / Venue** | DGT302 – Digital Signal Processing (Class IC2007-DGT302), FPT University · Lecturer: Le Phu Nguyen |
| **Type** | Lab report (Lab 1) |
| **Role** | Author · Individual |
| **Date** | July 2026 |
| **Tools** | Python (NumPy, Matplotlib), DSP |

## Overview
This lab studies what happens to information when a continuous-time signal is discretized, and how the Discrete Fourier Transform makes that loss visible. A two-tone reference signal (a 1 kHz sine plus a 3 kHz cosine, giving a 6 kHz Nyquist rate) is sampled at three regimes — 10 kHz (oversampled), 6 kHz (critically sampled), and 4 kHz (undersampled) — and the resulting spectra are compared. The work then verifies core DFT properties and quantifies the damage caused by decimating audio without an anti-aliasing filter.

## Highlights
- Sampled one two-tone reference at three rates spanning the Nyquist boundary to isolate oversampling, critical sampling, and undersampling side by side.
- Demonstrated spectral folding: at 4 kHz the 3 kHz tone folds onto 1 kHz, collapsing two tones into a single indistinguishable component.
- Captured the critically-sampled "knife-edge," where phase alignment at exactly the Nyquist rate becomes ambiguous and fragile.
- Verified DFT linearity and Parseval's theorem numerically, confirming energy conservation between the time and frequency domains.
- Modeled 8× audio decimation with no anti-aliasing stage to expose the origin of the characteristic "metallic" artefact.

## Key Results
- Under-sampling at 4 kHz folded the 3 kHz tone onto the 1 kHz tone, producing a single component of amplitude √2 (superposition of the two folded tones).
- Parseval's theorem held to numerical precision, confirming the DFT preserves total signal energy.
- Unfiltered 8× decimation folded 61.5% of the signal's energy back into the baseband, the measurable source of the metallic artefact.

📄 **[Read the full report](report.pdf)**
