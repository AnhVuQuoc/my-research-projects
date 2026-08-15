# VisiBike: Smart Lighting System for Bicycles

> An STM32-driven smart lighting system with turn signals and a brake light for safer night riding.

|  |  |
|---|---|
| Course / Venue | Microcontroller Programming course project, FPT University HCMC (IT Department) |
| Type | Group project / Course report |
| Role | Author, group of 4 |
| Date | November 2025 |
| Tools | STM32 (Nucleo-F429ZI), TB6612FNG driver, C / embedded, STM32CubeIDE |

## Overview
VisiBike is a smart electronic lighting system that improves a cyclist's nighttime visibility and signaling. An STM32 Nucleo-F429ZI board reads four pushbuttons and drives three high-power 3W LEDs, left and right turn signals plus a brake light, through a SparkFun TB6612FNG motor driver repurposed as a high-current power switch and buffer. The full report is written in Vietnamese.

## Highlights
- STM32 Nucleo-F429ZI firmware reading four pushbuttons and driving three high-power 3W LEDs.
- Reuse of a TB6612FNG motor driver as a high-current power switch and buffer, isolating the microcontroller from the LED load.
- Distinct signaling modes: left turn, right turn, and brake light.
- Algorithm flowchart and source-code analysis, with firmware developed in STM32CubeIDE.

## Key Results
- Working prototype driving all three 3W LEDs from pushbutton inputs, demonstrating turn-signal and brake-light behavior.
- Verified high-current LED switching through the TB6612FNG buffer, keeping drive current off the microcontroller pins.

## My Contribution
- Contributed to hardware wiring, embedded firmware development in STM32CubeIDE, and system testing as a member of the four-person team.

## Files
- [Full report](report.pdf)
