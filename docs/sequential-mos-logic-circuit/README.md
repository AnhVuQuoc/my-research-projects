# Sequential MOS Logic Circuit

> Transistor-level design and simulation of a clocked sequential logic element in Cadence Virtuoso.

|  |  |
|---|---|
| Course / Venue | ICI211 IC Design Introduction, FPT University |
| Type | Lab report (Lab 4) |
| Role | Author, individual |
| Date | 2026 |
| Tools | Cadence Virtuoso, Spectre |

## Overview
This lab extends transistor-level design from combinational to sequential logic by building a clocked storage element in Cadence Virtuoso. The circuit holds state between clock events and updates its outputs Q and Qbar in response to the clock, demonstrating the transition from memoryless gates to state-holding elements. Spectre transient analysis verifies the clocked behavior and the complementary output relationship.

## Highlights
- Designs a clocked sequential element at the MOS transistor level, introducing state storage on top of combinational CMOS gates.
- Schematic capture and simulation in Cadence Virtuoso and Spectre.
- Transient response driven by a clock stimulus to observe state capture and hold.
- Verifies the complementary Q and Qbar output relationship across clock cycles.

## Key Results
- Transient simulation confirms the element captures and holds state in response to the clock, with Q and Qbar remaining complementary.
- The output updates only at the intended clock events, demonstrating correct sequential timing behavior.

## Files
- [Full report](report.pdf)
