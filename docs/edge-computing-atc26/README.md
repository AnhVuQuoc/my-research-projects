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
The system integrates an ESP32, an INMP441 I2S microphone, a PAJ7620U2 optical gesture sensor, a relay stage for a 12 V, 10 W LED load, and a WebSocket monitoring interface that resides in the firmware. The keyword spotting model is an Int8 quantized 1D-CNN over MFCC features (49 frames by 13 coefficients), compiled by the Edge Impulse EON Compiler into C++ that is tuned to the hardware. Acoustic inference runs on one core, while the gesture path, driven by interrupts, and the WebSocket server run on the other. Rather than claiming algorithmic novelty, the paper contributes the analysis needed to interpret the measurements, namely a cost model that attributes the latency and memory of the deployed network, and an arbitration policy for concurrent commands.

## Contributions
- An integrated multimodal edge node that fuses I2S acoustic sampling with I2C gesture sensing driven by interrupts on one ESP32 and serves a WebSocket interface, with all inference performed locally.
- A **command arbitration policy** that resolves concurrent and conflicting commands. It uses a queue with a single writer, idempotent commands, a priority order within a time window (web, then gesture, then voice), and a lockout for each actuator.
- A **cost model in closed form** for the parameters, the multiply and accumulate count, and the tensor liveness, checked against measurements on the device and applied to a reference topology.

## Key Results
- **88.2%** overall accuracy on a six-class Vietnamese command set (95% Wilson interval 81.9% to 92.5%).
- **7 ms** inference latency at 240 MHz, a **4.0x** reduction of the inference stage compared with a contemporary TinyML implementation (28 ms).
- **3.8 KB** peak RAM arena and **31.2 KB** flash, with a network of only **1878** parameters and 25,656 MAC per inference.
- The MFCC front end costs **12.6x** the network arithmetic, so by Amdahl's law the fourfold speedup limits the end to end cycle reduction to **7.9%**, against a measured **3.4%**.
- 70% of the arena and 75% of the flash cannot be attributed to the model, which shows that the headline memory figure is largely a property of the toolchain.
- In a discrete event simulation, the arbitrated scheme shows **0%** lost events and **100%** agreement between the browser and the device, while the direct scheme diverges in half of the trials that involve the browser and loses one gesture in three during a burst.

## My Contribution
- First author. Led the design of the edge keyword spotting pipeline (MFCC feature extraction, Int8 quantized 1D-CNN, and EON Compiler deployment), the system integration, and the cost and arbitration analysis.

## Files
- [Full paper](report.pdf)
