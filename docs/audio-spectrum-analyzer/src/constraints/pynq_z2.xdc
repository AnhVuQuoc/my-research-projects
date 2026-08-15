
#CLOCK 125 MHz (onboard oscillator)
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -name sys_clk -period 8.000 [get_ports clk]


#SWITCHES
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_false_path -from [get_ports {sw[*]}]

#BUTTONS (btn[0] = reset)
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports {btn[1]}]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports {btn[2]}]
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports {btn[3]}]
set_false_path -from [get_ports {btn[*]}]

#LEDs
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

#RGB LEDs (LD4, LD5) 
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports {led4_rgb[0]}] ;# B
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {led4_rgb[1]}] ;# G
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {led4_rgb[2]}] ;# R
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {led5_rgb[0]}] ;# B
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports {led5_rgb[1]}] ;# G
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {led5_rgb[2]}] ;# R

#bitstream config
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO      [current_design]
