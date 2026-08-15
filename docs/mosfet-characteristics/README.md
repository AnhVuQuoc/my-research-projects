# Study of MOSFET Characteristics

> Simulation-based characterization of NMOS and PMOS transistors for analog IC design.

|  |  |
|---|---|
| Course / Venue | ICI211 IC Design Introduction, FPT University |
| Type | Lab report (Lab 1) |
| Role | Author, individual |
| Date | 2026 |
| Tools | SPICE-class circuit simulation, semiconductor device analysis |

## Overview
This lab characterizes the electrical behavior of PMOS and NMOS transistors through circuit simulation. It examines the output characteristics (I_D versus V_DS), the transfer characteristics (I_D versus V_GS), and the effect of the W/L ratio, then interprets each in the context of analog IC design. The goal is to connect device-level physics to the design parameters engineers actually tune.

## Highlights
- Full characterization of both device polarities: Section A covers PMOS (output, transfer, W/L effect) and Section B covers NMOS.
- Extracts and discusses threshold voltage (Vth) from the transfer characteristics.
- Analyzes transconductance (gm) and its role in setting small-signal gain.
- Explains channel-length modulation and its impact on finite output resistance.
- Demonstrates how the W/L ratio scales drain current and shifts device behavior.

## Key Results
- Output characteristics reveal the triode-to-saturation transition and the channel-length-modulation slope in saturation, quantifying output resistance.
- Transfer characteristics locate the threshold voltage and expose the square-law dependence of I_D on overdrive.
- Increasing the W/L ratio proportionally raises drain current and transconductance, confirming its use as a primary sizing knob.
- Comparison of PMOS and NMOS highlights the mobility-driven current asymmetry between the two polarities.

## Files
- [Full report](report.pdf)
