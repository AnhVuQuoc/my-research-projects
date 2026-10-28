# VisiBike, a Smart Lighting System for Bicycles

> A smart lighting system driven by an STM32, with turn signals and a brake light for safer night riding.

|  |  |
|---|---|
| Course / Venue | Microcontroller Programming course project, FPT University HCMC (IT Department) |
| Type | Group project / Course report |
| Role | Author, group of 4 |
| Date | November 2025 |
| Tools | STM32 (Nucleo-F429ZI), TB6612FNG driver, C / embedded, STM32CubeIDE |

## Overview
VisiBike is a smart electronic lighting system that improves a cyclist's visibility and signaling at night. An STM32 Nucleo-F429ZI board reads four pushbuttons and drives three high power 3W LEDs, which serve as the left and right turn signals and a brake light. The LEDs are driven through a SparkFun TB6612FNG motor driver that is repurposed as a high current power switch and buffer. The full report is written in Vietnamese.

## Highlights
- STM32 Nucleo-F429ZI firmware that reads four pushbuttons and drives three high power 3W LEDs.
- Reuse of a TB6612FNG motor driver as a high current power switch and buffer, which isolates the microcontroller from the LED load.
- Distinct signaling modes for the left turn, the right turn, and the brake light.
- An algorithm flowchart and an analysis of the source code, with the firmware developed in STM32CubeIDE.

## Key Results
- A working prototype drives all three 3W LEDs from the pushbutton inputs, demonstrating the turn signal and brake light behavior.
- High current LED switching through the TB6612FNG buffer was verified, which keeps the drive current off the microcontroller pins.

## My Contribution
- Contributed to the hardware wiring, the embedded firmware development in STM32CubeIDE, and the system testing as a member of the team of four.

## Files
- [Full report](report.pdf)
