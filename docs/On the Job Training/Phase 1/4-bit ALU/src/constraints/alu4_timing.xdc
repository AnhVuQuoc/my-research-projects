## ============================================================================
## alu4_timing.xdc : timing constraints for ALU4 (Vu Quoc Anh, SE203519)
## Only a clock constraint is given. It is NOT needed to get the resource
## utilization, but it lets Vivado produce a real Timing Summary (WNS).
## No pin (PACKAGE_PIN / IOSTANDARD) constraints: the design is not mapped to
## a specific board, so stop after synthesis (or implementation) and do not
## generate a bitstream.
## ============================================================================

## 100 MHz clock on port clk (same period as the testbench: 10 ns)
create_clock -period 10.000 -name clk [get_ports clk]

## Optional: treat the asynchronous reset as a false path for timing
set_false_path -from [get_ports rst]
