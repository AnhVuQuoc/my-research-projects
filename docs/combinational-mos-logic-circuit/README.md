# Combinational MOS Logic Circuit

> Design and simulation of a combinational logic circuit at the transistor level in Cadence Virtuoso.

|  |  |
|---|---|
| Course / Venue | ICI211 IC Design Introduction, FPT University |
| Type | Lab report (Lab 3) |
| Role | Author, individual |
| Date | 2026 |
| Tools | Cadence Virtuoso, Spectre |

## Overview
This lab designs a combinational logic function at the MOS transistor level and verifies it in Cadence Virtuoso. The circuit is built from complementary pull up and pull down networks and then simulated with Spectre, to confirm that the transistor level implementation reproduces the intended Boolean behavior. Transient analysis relates the input stimulus to the output response and shows how signals propagate through the CMOS gate network.

## Highlights
- Builds a combinational logic function directly from complementary pull up and pull down transistor networks.
- Schematic capture and simulation in Cadence Virtuoso and Spectre.
- Uses the transient response to validate the logic function against its truth table.
- Connects the switching behavior of the gate network to the CMOS design principles from the earlier labs.

## Key Results
- Transient simulation confirms that the output follows the intended combinational logic function across the applied input sequence.
- The complementary network drives full rail to rail output levels, with no static conducting path in the steady state.

## Files
- [Full report](report.pdf)
