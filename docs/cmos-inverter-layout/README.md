# CMOS Inverter Design: Circuit to Layout

> Designing, sizing, and simulating a CMOS inverter from schematic through layout in Cadence.

|  |  |
|---|---|
| **Course / Venue** | ICI211 – IC Design Introduction |
| **Type** | Lab report |
| **Role** | Author · Individual |
| **Date** | June 2026 |
| **Tools** | Cadence Virtuoso, Spectre, VLSI layout |

## Overview
This report takes the CMOS inverter from theory to a working design, covering its structure, switching behavior, and transistor sizing. The core design challenge is compensating for the mobility difference between electrons and holes so that the inverter switches symmetrically. The schematic is built and characterized in Cadence Virtuoso/Spectre using DC (VTC) and transient analyses.

## Highlights
- Explains CMOS inverter operation and the complementary pull-up / pull-down structure.
- Derives design principles for transistor sizing, centered on the electron-vs-hole carrier mobility discrepancy.
- Builds the schematic in Cadence Virtuoso and simulates with Spectre (Part A schematic, Part B DC/VTC, Part C transient).
- Links the voltage transfer characteristic (VTC) directly to switching-threshold symmetry.
- Extends from circuit design toward physical VLSI layout.

## Key Results
- Equally-sized transistors produce a left-skewed VTC with a switching threshold of ~0.41 V, confirming the NMOS strength advantage.
- Predicts a ~2.5× PMOS-to-NMOS width ratio to recenter the switching threshold and achieve symmetric switching.
- Transient analysis verifies the inverter's dynamic response and confirms rail-to-rail output swing.

📄 **[Read the full report](report.pdf)**
