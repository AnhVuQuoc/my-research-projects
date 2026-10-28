# CMOS Inverter Design from Circuit to Layout

> Designing, sizing, and simulating a CMOS inverter from the schematic through to the layout in Cadence.

|  |  |
|---|---|
| Course / Venue | ICI211 IC Design Introduction, FPT University |
| Type | Lab report (Lab 2) |
| Role | Author, individual |
| Date | June 2026 |
| Tools | Cadence Virtuoso, Spectre, VLSI layout |

## Overview
This report takes the CMOS inverter from theory to a working design, covering its structure, its switching behavior, and transistor sizing. The core design challenge is to compensate for the mobility difference between electrons and holes, so that the inverter switches symmetrically. The schematic is built and characterized in Cadence Virtuoso and Spectre using DC (VTC) and transient analyses, and the work is then extended toward the physical layout.

## Highlights
- Explains how a CMOS inverter operates and how its complementary pull up and pull down structure works.
- Derives sizing principles that center on the difference in carrier mobility between electrons and holes.
- Builds the schematic in Cadence Virtuoso and simulates it with Spectre (Part A schematic, Part B DC/VTC, Part C transient).
- Links the voltage transfer characteristic directly to the symmetry of the switching threshold.
- Extends the work from circuit design toward the physical VLSI layout.

## Key Results
- Transistors of equal size produce a VTC skewed to the left, with a switching threshold of about **0.41 V**, which confirms the strength advantage of the NMOS.
- The analysis predicts a **2.5x** PMOS to NMOS width ratio to recenter the switching threshold and achieve symmetric switching.
- Transient analysis verifies the dynamic response and confirms a rail to rail output swing.

## Files
- [Full report](report.pdf)
