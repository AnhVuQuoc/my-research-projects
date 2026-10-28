# 9-IP RTL Design and Verification Suite

> A progressive set of Verilog IP blocks and testbenches that grows from single combinational gates to bus IP at the protocol level, with layered and reusable verification environments.

|  |  |
|---|---|
| Course / Venue | Independent RTL design and verification project |
| Type | Verilog IP + verification suite (source only) |
| Role | Author, individual |
| Tools | Verilog / simulation, Makefile flow |

## Overview
This suite contains nine incremental subprojects (p1 to p9) that trace a complete path from basic digital design to functional verification in the industry style. The early stages build and check combinational, encoder, and decoder IP directly. The middle stages introduce a layered testbench architecture built from agents (driver, monitor, checker, scoreboard, coverage, and reference model). The later stages apply that architecture to IP attached to a bus, delivering an APB peripheral and a UART controller, each with a verification environment that checks its own results and is driven by coverage. Every subproject builds through a common Makefile flow.

## The nine subprojects
- **p1 combinational**: full adder, ripple-carry and carry-lookahead adders, magnitude comparator, parametric mux, and an ALU, each with directed testbenches.
- **p2 decoder**: structural 3-to-8, parametric n-to-2n, hexadecimal to seven segment, and address decoders, with testbenches.
- **p3 decoder tb arch**: a decoder top wrapped in a reusable testbench built from agents (env, driver, monitor, checker, coverage, reference and CPU models).
- **p4 encoder**: simple and priority encoders, a parametric priority encoder, a one hot to binary converter, and an interrupt arbiter.
- **p5 encoder tb arch**: an interrupt controller verified with a layered environment and with smoke, random, nesting, and race tests.
- **p6 apb ip**: an APB slave, an APB interrupt controller, and a command control block, exercised by an APB master bus functional model.
- **p7 apb ip verif**: a complete APB verification environment with a protocol checker, register and interrupt controller models, a scoreboard, coverage, and sequences, plus register access, IRQ flow, error response, and random tests.
- **p8 mcu uart ip**: a UART IP (core, transmitter, receiver, baud generator, synchronous FIFO, and APB wrapper) with loopback, baud, FIFO, error, register, and random tests.
- **p9 uart ip verif**: an automated UART environment with a byte scoreboard, a receive path predictor, automatically generated coverage, and configuration sweep tests.

## Highlights
- Covers **9** IP blocks in one coherent progression, from a single full adder to APB and UART peripherals that comply with their protocols.
- A reusable layered verification architecture (driver, monitor, checker, scoreboard, coverage, and reference model) applied again across several IP blocks.
- Design and checking at the protocol level for both the **APB** bus and the **UART** serial interface.
- Testbenches that are driven by coverage and check their own results, rather than relying on waveform inspection.

## Files
- [Source code](src/) for all nine subprojects (RTL, testbenches, and Makefiles)

This project is source only. No report PDF accompanies it.
