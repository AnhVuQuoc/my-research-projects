# Combinational MOS Logic Circuit

> Transistor-level design and simulation of a combinational logic circuit in Cadence Virtuoso.

|  |  |
|---|---|
| Course / Venue | ICI211 IC Design Introduction, FPT University |
| Type | Lab report (Lab 3) |
| Role | Author, individual |
| Date | 2026 |
| Tools | Cadence Virtuoso, Spectre |

## Overview
This lab designs a combinational logic function at the MOS transistor level and verifies it in Cadence Virtuoso. The circuit is constructed from complementary pull-up and pull-down networks, then simulated with Spectre to confirm that the transistor-level implementation reproduces the intended Boolean behavior. Transient analysis relates the input stimulus to the output response and exposes the propagation behavior of the CMOS gate network.

## Highlights
- Builds a combinational logic function directly from complementary pull-up and pull-down transistor networks.
- Schematic capture and simulation in Cadence Virtuoso and Spectre.
- Transient response used to validate the logic function against its truth table.
- Connects the switching behavior of the gate network to CMOS design principles from the earlier labs.

## Key Results
- Transient simulation confirms the output tracks the intended combinational logic function across the applied input sequence.
- The complementary network drives full rail-to-rail output levels with no static conducting path in steady state.

## Files
- [Full report](report.pdf)
