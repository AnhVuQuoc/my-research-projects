# Development of an Edge Computing-Based Voice and Gesture-Controlled Lighting System

> A contactless smart-lighting system driven by both on-device voice keyword spotting and hand gestures.

|  |  |
|---|---|
| **Course / Venue** | ATC2026 (IEEE-style conference manuscript, submitted) |
| **Type** | Research paper / Manuscript |
| **Role** | Co-author (first author) · Group (4 members) |
| **Date** | 2026 |
| **Tools** | ESP32, Edge Impulse, TinyML, C/C++, WebSocket |

## Overview
Conventional smart-lighting relies on touch controls or cloud-dependent voice assistants that add latency and privacy concerns. This work develops a fully contactless lighting system controlled by both voice commands and hand gestures, running entirely at the edge on an ESP32. The prototype combines an INMP441 microphone, a PAJ7620U2 gesture sensor, and a relay-driven 12V/10W LED, with a WebSocket-based web UI for monitoring and control.

## Highlights
- On-device Int8-quantized 1D-CNN keyword-spotting model using MFCC features, compiled via the Edge Impulse EON Compiler.
- Multimodal human-machine interface fusing acoustic (voice) and optical (gesture) input for redundant, contactless control.
- Fully local inference on the ESP32 — no cloud dependency, preserving privacy and minimizing latency.
- WebSocket web UI for real-time status and remote control.
- Tightly resource-constrained embedded design spanning TinyML, IoT, and acoustic signal processing.

## Key Results
- 88.2% keyword-spotting accuracy.
- 7 ms inference latency on-device.
- 3.8 KB peak RAM usage.
- 31.2 KB flash footprint.

## My Contribution
- First author: led the design of the edge keyword-spotting pipeline (MFCC feature extraction, Int8-quantized 1D-CNN, EON Compiler deployment) and system integration.

📄 **[Read the full report](report.pdf)**
