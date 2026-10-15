# Development of an Edge Computing Based Voice and Gesture Controlled Lighting System

> A contactless smart lighting system controlled by voice and hand gestures, with keyword spotting, gesture recognition, and web synchronization running locally on a single ESP32.

|  |  |
|---|---|
| Course / Venue | ATC2026 |
| Type | Research paper |
| Authors | Anh Q. Vu (first author), Hung D. Truong, Hoang H.N. Le, Le The Dung (Corresponding Author) |
| Affiliation | FPT University |
| Date | 2026 |
| Tools | ESP32 (ESP-IDF, FreeRTOS), Edge Impulse EON Compiler, ESP-NN, INMP441, PAJ7620U2, WebSocket |

## Overview
The system integrates an ESP32, an INMP441 I2S microphone, a PAJ7620U2 optical gesture sensor, a relay stage for a 12 V, 10 W LED load, and a firmware-resident WebSocket monitoring interface. The keyword spotting model is an Int8 quantized 1D-CNN over MFCC features (49 frames by 13 coefficients), compiled by the Edge Impulse EON Compiler into hardware-aware C++. Acoustic inference runs on one core while the interrupt-driven gesture path and the WebSocket server run on the other. Rather than claiming algorithmic novelty, the paper contributes the analysis needed to interpret the measurements: a cost model that attributes the deployed network's latency and memory, and an arbitration policy for concurrent commands.

## Contributions
- Integrated multimodal edge node that fuses I2S acoustic sampling with interrupt-driven I2C gesture sensing on one ESP32 and serves a WebSocket interface, with all inference performed locally.
- A **command arbitration policy** (single-writer queue, idempotent commands, windowed priority web over gesture over voice, per-actuator lockout) that resolves concurrent conflicting commands.
- A **closed-form cost model** for parameters, multiply-accumulate count, and tensor liveness, cross-checked against on-device measurement and applied to a reference topology.

## Key Results
- **88.2%** overall accuracy on a six-class Vietnamese command set (95% Wilson interval 81.9% to 92.5%).
- **7 ms** inference latency at 240 MHz, a **4.0x** reduction of the inference stage versus a contemporary TinyML implementation (28 ms).
- **3.8 KB** peak RAM arena and **31.2 KB** flash, with a network of only **1878** parameters and 25,656 MAC per inference.
- The MFCC front end costs **12.6x** the network arithmetic, so by Amdahl's law the fourfold speedup bounds the end-to-end cycle reduction at **7.9%**, against a measured **3.4%**.
- 70% of the arena and 75% of the flash are not model-attributable, showing headline memory is largely a toolchain property.
- In discrete-event simulation the arbitrated scheme shows **0%** lost events and **100%** browser-device agreement, while the direct scheme diverges in half of browser-involving trials and loses one gesture in three during a burst.

## My Contribution
- First author. Led the design of the edge keyword spotting pipeline (MFCC feature extraction, Int8 quantized 1D-CNN, EON Compiler deployment), system integration, and the cost and arbitration analysis.

## Files
- [Full paper](report.pdf)
