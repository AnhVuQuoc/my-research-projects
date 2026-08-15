create_clock -name clk -period 10.000 [get_ports clk]
set_input_delay  -clock clk 2.0 [get_ports {s_axis_tvalid s_axis_tdata[*] m_axis_tready}]
set_output_delay -clock clk 2.0 [get_ports {s_axis_tready m_axis_tvalid m_axis_tdata[*] \
                                            m_axis_tlast m_axis_tuser[*] \
                                            peak_valid peak_magnitude[*] peak_bin_idx[*] \
                                            busy core_en frame_count[*]}]
set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports start]

