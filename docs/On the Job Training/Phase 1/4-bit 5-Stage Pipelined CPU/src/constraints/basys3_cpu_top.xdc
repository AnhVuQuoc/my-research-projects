## =============================================================================
## File    : constraints/basys3_cpu_top.xdc
## Project : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
## Author  : Vu Quoc Anh (SE203519)
## Board   : Digilent Basys 3 (xc7a35tcpg236-1)
## Job     : Pins and clock for cpu_top so the full Vivado flow (synthesis,
##           implementation, bitstream) runs. Pin names follow the Digilent
##           Basys 3 master XDC; compare with your board's file before you
##           program the board.
## Note    : at 100 MHz the program finishes in nanoseconds, so the LEDs only
##           show the final loop. A visible step-by-step demo needs a clock
##           enable (planned for the next level), NOT a divided clock.
## =============================================================================

## ---- 100 MHz clock -------------------------------------------------------------
set_property -dict { PACKAGE_PIN W5  IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## ---- reset: center button btnC ---------------------------------------------------
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports rst]

## ---- LEDs LD0..LD3 = pc_out ----------------------------------------------------
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {pc_out[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {pc_out[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {pc_out[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {pc_out[3]}]
## ---- LEDs LD4..LD7 = wb_data_out -----------------------------------------------
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {wb_data_out[0]}]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {wb_data_out[1]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {wb_data_out[2]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {wb_data_out[3]}]
## ---- LEDs LD8..LD11 = alu_out --------------------------------------------------
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports {alu_out[0]}]
set_property -dict { PACKAGE_PIN V3  IOSTANDARD LVCMOS33 } [get_ports {alu_out[1]}]
set_property -dict { PACKAGE_PIN W3  IOSTANDARD LVCMOS33 } [get_ports {alu_out[2]}]
set_property -dict { PACKAGE_PIN U3  IOSTANDARD LVCMOS33 } [get_ports {alu_out[3]}]
## ---- LEDs LD12, LD13 = flags ----------------------------------------------------
set_property -dict { PACKAGE_PIN P3  IOSTANDARD LVCMOS33 } [get_ports zero_out]
set_property -dict { PACKAGE_PIN N3  IOSTANDARD LVCMOS33 } [get_ports carry_out]

## ---- Pmod JA (8 pins) + JB (4 pins) = instr_out[11:0] ------------------------------
set_property -dict { PACKAGE_PIN J1  IOSTANDARD LVCMOS33 } [get_ports {instr_out[0]}]
set_property -dict { PACKAGE_PIN L2  IOSTANDARD LVCMOS33 } [get_ports {instr_out[1]}]
set_property -dict { PACKAGE_PIN J2  IOSTANDARD LVCMOS33 } [get_ports {instr_out[2]}]
set_property -dict { PACKAGE_PIN G2  IOSTANDARD LVCMOS33 } [get_ports {instr_out[3]}]
set_property -dict { PACKAGE_PIN H1  IOSTANDARD LVCMOS33 } [get_ports {instr_out[4]}]
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports {instr_out[5]}]
set_property -dict { PACKAGE_PIN H2  IOSTANDARD LVCMOS33 } [get_ports {instr_out[6]}]
set_property -dict { PACKAGE_PIN G3  IOSTANDARD LVCMOS33 } [get_ports {instr_out[7]}]
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports {instr_out[8]}]
set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 } [get_ports {instr_out[9]}]
set_property -dict { PACKAGE_PIN B15 IOSTANDARD LVCMOS33 } [get_ports {instr_out[10]}]
set_property -dict { PACKAGE_PIN B16 IOSTANDARD LVCMOS33 } [get_ports {instr_out[11]}]

## ---- configuration bank voltage (removes the CFGBVS DRC warning) -------------------
set_property CFGBVS VCCO        [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
