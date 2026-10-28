# Full Wave Voltage Doubler

> Analysis and LTspice simulation of a full wave (Delon) voltage doubler that steps up a DC voltage without a transformer.

|  |  |
|---|---|
| Course / Venue | ELC201 Electronic Circuits (Class IC2004), FPT University |
| Type | Group project / Lab report |
| Role | Author, Team 6 |
| Date | 2025 |
| Tools | LTspice XVII, 1N4001 diodes, transient analysis |

## Overview
A full wave voltage doubler (Delon circuit) uses two diodes and two capacitors to produce a DC output close to twice the peak of an AC input, without a transformer. This report analyzes how the capacitors charge in each half cycle, simulates the circuit in LTspice XVII with two 1N4001 diodes and two 100uF capacitors, and studies how the output voltage and ripple respond to the load. The output ripple appears at twice the input frequency, because each capacitor is refreshed once per half cycle.

## Highlights
- A cycle by cycle analysis of diode conduction and capacitor charging over the positive and negative half cycles.
- An LTspice XVII transient simulation from 0 to 500 ms with realistic diode models.
- A load sweep that shows the voltage regulation tradeoff between output level and ripple.
- A derivation of the ripple relation V_ripple = I_load / (2 f C) for the full wave topology.

## Key Results
- From a **5 V** peak AC input, the circuit produces about **9.16 V** DC under no load, close to the ideal doubling.
- The output falls to **7.21 V** at a 1 kOhm load and recovers to **8.96 V** at 1 MOhm, which confirms a strong sensitivity to the load.
- The ripple grows with the load current and falls with the load resistance, and it appears at **2x** the input frequency.
- The circuit is best suited to high voltage applications with a light load, such as biasing.

## Files
- [Full report](report.pdf)
