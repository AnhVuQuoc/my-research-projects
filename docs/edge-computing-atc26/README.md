# Development of an Edge Computing Based Voice and Gesture Controlled Lighting System

> A contactless smart lighting system driven by on-device voice keyword spotting and hand gestures, running entirely at the edge on an ESP32.

|  |  |
|---|---|
| Course / Venue | ATC2026 (IEEE style conference manuscript, submitted) |
| Type | Research paper / Manuscript |
| Role | Co-author (first author), group of 4 |
| Date | 2026 |
| Tools | ESP32, Edge Impulse, TinyML, C/C++, WebSocket |

## Overview
Conventional smart lighting relies on touch controls or cloud dependent voice assistants that add latency and privacy concerns. This work develops a fully contactless lighting system controlled by both voice commands and hand gestures, running entirely at the edge on an ESP32. The prototype combines an INMP441 microphone, a PAJ7620U2 gesture sensor, and a relay driven 12V/10W LED, with a WebSocket based web interface for monitoring and control.

## Highlights
- On-device Int8 quantized 1D-CNN keyword spotting model using MFCC features, compiled through the Edge Impulse EON Compiler.
- Multimodal human machine interface fusing acoustic (voice) and optical (gesture) input for redundant, contactless control.
- Fully local inference on the ESP32 with no cloud dependency, preserving privacy and minimizing latency.
- WebSocket web interface for real time status and remote control.

## Key Results
- **88.2%** keyword spotting accuracy.
- **7 ms** on-device inference latency.
- **3.8 KB** peak RAM usage.
- **31.2 KB** flash footprint.

## My Contribution
- First author. Led the design of the edge keyword spotting pipeline (MFCC feature extraction, Int8 quantized 1D-CNN, EON Compiler deployment) and system integration.

## Files
- [Full report](report.pdf)
