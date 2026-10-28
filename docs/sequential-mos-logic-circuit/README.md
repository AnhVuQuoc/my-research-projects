# Sequential MOS Logic Circuit

> Design and simulation of a clocked sequential logic element at the transistor level in Cadence Virtuoso.

|  |  |
|---|---|
| Course / Venue | ICI211 IC Design Introduction, FPT University |
| Type | Lab report (Lab 4) |
| Role | Author, individual |
| Date | 2026 |
| Tools | Cadence Virtuoso, Spectre |

## Overview
This lab extends transistor level design from combinational to sequential logic by building a clocked storage element in Cadence Virtuoso. The circuit holds its state between clock events and updates its outputs Q and Qbar in response to the clock, which demonstrates the step from gates without memory to elements that hold state. A Spectre transient analysis verifies the clocked behavior and the complementary relationship between the outputs.

## Highlights
- Designs a clocked sequential element at the MOS transistor level, adding state storage on top of combinational CMOS gates.
- Schematic capture and simulation in Cadence Virtuoso and Spectre.
- A transient response driven by a clock stimulus, used to observe how the state is captured and held.
- Verifies that the Q and Qbar outputs stay complementary across clock cycles.

## Key Results
- Transient simulation confirms that the element captures and holds its state in response to the clock, with Q and Qbar remaining complementary.
- The output updates only at the intended clock events, which demonstrates correct sequential timing behavior.

## Files
- [Full report](report.pdf)
