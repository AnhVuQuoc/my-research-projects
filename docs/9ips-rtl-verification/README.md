# 9-IP RTL Design and Verification Suite

> A progressive set of Verilog IP blocks and testbenches that builds from single combinational gates up to protocol-level bus IP with layered, reusable verification environments.

|  |  |
|---|---|
| Course / Venue | Self-directed RTL design and verification project |
| Type | Verilog IP + verification suite (source only) |
| Role | Author, individual |
| Tools | Verilog / simulation, Makefile flow |

## Overview
This suite contains nine incremental sub-projects (p1 to p9) that trace a full path from basic digital design to industry-style functional verification. The early stages build and check combinational and encoder/decoder IP directly. The middle stages introduce a layered, agent-based testbench architecture (driver, monitor, checker, scoreboard, coverage, and reference model). The later stages apply that architecture to bus-attached IP, delivering an APB peripheral and a UART controller each with a self-checking, coverage-driven verification environment. Every sub-project builds through a common Makefile flow.

## The nine sub-projects
- **p1 combinational**: full adder, ripple-carry and carry-lookahead adders, magnitude comparator, parametric mux, and an ALU, each with directed testbenches.
- **p2 decoder**: 3-to-8 structural, parametric n-to-2n, hex-to-seven-segment, and address decoders with testbenches.
- **p3 decoder tb arch**: a decoder top wrapped in a reusable agent-based testbench (env, driver, monitor, checker, coverage, reference and CPU models).
- **p4 encoder**: simple and priority encoders, a parametric priority encoder, one-hot-to-binary, and an interrupt arbiter.
- **p5 encoder tb arch**: an interrupt controller verified with a layered environment and smoke, random, nesting, and race tests.
- **p6 apb ip**: an APB slave, APB interrupt controller, and command-control block, exercised by an APB master bus functional model.
- **p7 apb ip verif**: a full APB verification environment with a protocol checker, register and interrupt-controller models, scoreboard, coverage, and sequences, plus register-access, IRQ-flow, error-response, and random tests.
- **p8 mcu uart ip**: a UART IP (core, transmitter, receiver, baud generator, synchronous FIFO, APB wrapper) with loopback, baud, FIFO, error, register, and random tests.
- **p9 uart ip verif**: an automated UART environment with a byte scoreboard, receive-path predictor, self-generating coverage, and configuration-sweep tests.

## Highlights
- Covers **9** IP blocks in one coherent progression, from a single full adder to protocol-compliant APB and UART peripherals.
- Reusable layered verification architecture (driver, monitor, checker, scoreboard, coverage, reference model) reapplied across multiple IP.
- Protocol-level design and checking for both the **APB** bus and the **UART** serial interface.
- Coverage-driven and self-checking testbenches rather than waveform inspection.

## Files
- [Source code](src/) for all nine sub-projects (rtl, testbenches, and Makefiles)

This project is source only. No report PDF accompanies it.
