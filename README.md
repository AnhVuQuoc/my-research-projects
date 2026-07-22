# Research & Coursework Portfolio

A curated portfolio of research papers and university coursework by **Vu Quoc Anh
(SE203519)** — FPT University, Ho Chi Minh City. The work spans edge AI and embedded
systems, digital & analog circuit design, IC/semiconductor design, and digital signal
processing.

Each project has a short, high-level write-up under [`docs/`](docs/) with the full report
linked as a PDF. Click a project title for its summary, or the 📄 link to open the report.

---

## 📄 Research Papers

| Project | Summary | Report |
|---|---|---|
| [Edge Voice & Gesture-Controlled Lighting](docs/edge-voice-gesture-lighting/) | Contactless smart-lighting on an ESP32 using on-device TinyML keyword spotting and gesture sensing (ATC2026 submission) | [📄 PDF](docs/edge-voice-gesture-lighting/report.pdf) |
| [FFT Spectrum Analyzer IP Core](docs/fft-spectrum-analyzer/) | 256-point R2SDF FFT audio analyzer in Verilog on Zynq-7000, verified bit-exact against a Python golden model | [📄 PDF](docs/fft-spectrum-analyzer/report.pdf) |
| [Approximate Systolic Array on FPGA](docs/approximate-systolic-array/) | Energy-efficient 4×4 systolic array with approximate signed PEs for DNN matrix multiplication | [📄 PDF](docs/approximate-systolic-array/report.pdf) |

## 📈 Signal Processing (DGT302)

| Project | Summary | Report |
|---|---|---|
| [Sampling & the Fourier Transform](docs/dsp-sampling-fourier/) | Nyquist–Shannon sampling, aliasing, the DFT, Parseval's theorem, and audio decimation (Lab 1) | [📄 PDF](docs/dsp-sampling-fourier/report.pdf) |
| [LTI Modeling of Audio & Room Acoustics](docs/dsp-lti-audio-acoustics/) | FIR/IIR equalizer design, reverberation by convolution, and inverse-filter dereverberation | [📄 PDF](docs/dsp-lti-audio-acoustics/report.pdf) |

## 🔬 IC & Semiconductor Design (ICI211)

| Project | Summary | Report |
|---|---|---|
| [MOSFET Characteristics](docs/mosfet-characteristics/) | Simulation-based PMOS/NMOS output & transfer characteristics and W/L sizing effects (Lab 1) | [📄 PDF](docs/mosfet-characteristics/report.pdf) |
| [CMOS Inverter: Circuit to Layout](docs/cmos-inverter-layout/) | CMOS inverter design, VTC/transient analysis, and transistor sizing in Cadence Virtuoso (Lab 2) | [📄 PDF](docs/cmos-inverter-layout/report.pdf) |

## ⚡ Circuits & Embedded Systems

| Project | Summary | Report |
|---|---|---|
| [4-to-1 Multiplexer](docs/mux-4to1/) | Truth table → K-map → gate schematic → simulation → PCB verification of a 4-to-1 MUX (DIC201) | [📄 PDF](docs/mux-4to1/report.pdf) |
| [Non-Inverting Amplifier](docs/non-inverting-amplifier/) | Op-amp amplifier modeled in LTspice and realized on PCB in Proteus (ELC201, Lab 3) | [📄 PDF](docs/non-inverting-amplifier/report.pdf) |
| [VisiBike – Smart Bicycle Lighting](docs/visibike-smart-lighting/) | STM32 Nucleo-F429ZI driving turn signals and a brake light via a TB6612FNG driver | [📄 PDF](docs/visibike-smart-lighting/report.pdf) |

---

## Repository layout

```
docs/
  <project>/
    README.md     # high-level summary of the report
    report.pdf    # the full, viewable report
```

> Full-report PDFs live inside each project's folder so they render directly on GitHub.
