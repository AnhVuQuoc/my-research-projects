## =============================================================================
## File    : constraints/basys3_cpu_top.xdc
## Project : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
## Author  : Vu Quoc Anh (SE203519)
## Board   : Digilent Basys 3 (xc7a35tcpg236-1)
## Job     : 43 debug outputs: pc_out on LD0..LD7, wb_data_out on LD8..LD15,
##           alu_out on Pmod JA, instr_out on JB (bits 7..0) and JC (bits 15..8),
##           zero_out, carry_out, halted on JXADC. Pin names follow the Digilent
##           Basys 3 master XDC; compare with your copy before programming.
## =============================================================================
set_property -dict { PACKAGE_PIN W5  IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports rst]

## ---- LD0..LD7 = pc_out, LD8..LD15 = wb_data_out ----------------------------
set led_pins {U16 E19 U19 V19 W18 U15 U14 V14 V13 V3 W3 U3 P3 N3 P1 L1}
for {set i 0} {$i < 8} {incr i} {
    set_property -dict [list PACKAGE_PIN [lindex $led_pins $i] IOSTANDARD LVCMOS33] [get_ports "pc_out[$i]"]
    set_property -dict [list PACKAGE_PIN [lindex $led_pins [expr {$i + 8}]] IOSTANDARD LVCMOS33] [get_ports "wb_data_out[$i]"]
}
## ---- Pmod JA = alu_out, JB = instr_out[7:0], JC = instr_out[15:8] -------------
set ja_pins {J1 L2 J2 G2 H1 K2 H2 G3}
set jb_pins {A14 A16 B15 B16 A15 A17 C15 C16}
set jc_pins {K17 M18 N17 P18 L17 M19 P17 R18}
for {set i 0} {$i < 8} {incr i} {
    set_property -dict [list PACKAGE_PIN [lindex $ja_pins $i] IOSTANDARD LVCMOS33] [get_ports "alu_out[$i]"]
    set_property -dict [list PACKAGE_PIN [lindex $jb_pins $i] IOSTANDARD LVCMOS33] [get_ports "instr_out[$i]"]
    set_property -dict [list PACKAGE_PIN [lindex $jc_pins $i] IOSTANDARD LVCMOS33] [get_ports "instr_out[[expr {$i + 8}]]"]
}
## ---- Pmod JXADC = flags and halted --------------------------------------------
set_property -dict { PACKAGE_PIN J3 IOSTANDARD LVCMOS33 } [get_ports zero_out]
set_property -dict { PACKAGE_PIN L3 IOSTANDARD LVCMOS33 } [get_ports carry_out]
set_property -dict { PACKAGE_PIN M2 IOSTANDARD LVCMOS33 } [get_ports halted]

set_property CFGBVS VCCO        [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
