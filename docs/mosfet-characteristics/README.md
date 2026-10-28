# Study of MOSFET Characteristics

> Characterization of NMOS and PMOS transistors by simulation, for analog IC design.

|  |  |
|---|---|
| Course / Venue | ICI211 IC Design Introduction, FPT University |
| Type | Lab report (Lab 1) |
| Role | Author, individual |
| Date | 2026 |
| Tools | SPICE class circuit simulation, semiconductor device analysis |

## Overview
This lab characterizes the electrical behavior of PMOS and NMOS transistors through circuit simulation. It examines the output characteristics (I_D versus V_DS), the transfer characteristics (I_D versus V_GS), and the effect of the W/L ratio, and then interprets each result in the context of analog IC design. The goal is to connect the physics of the device to the design parameters that engineers actually tune.

## Highlights
- Characterizes both device polarities in full. Section A covers PMOS (output, transfer, W/L effect) and Section B covers NMOS.
- Extracts and discusses the threshold voltage (Vth) from the transfer characteristics.
- Analyzes the transconductance (gm) and its role in setting the small signal gain.
- Explains channel length modulation and its impact on the finite output resistance.
- Demonstrates how the W/L ratio scales the drain current and shifts the device behavior.

## Key Results
- The output characteristics reveal the transition from the triode region to saturation and the slope in saturation caused by channel length modulation, which quantifies the output resistance.
- The transfer characteristics locate the threshold voltage and expose the square law dependence of I_D on the overdrive voltage.
- Increasing the W/L ratio raises the drain current and transconductance proportionally, which confirms its use as a primary sizing parameter.
- Comparing PMOS and NMOS highlights the current asymmetry between the two polarities, which is caused by their different mobilities.

## Files
- [Full report](report.pdf)
