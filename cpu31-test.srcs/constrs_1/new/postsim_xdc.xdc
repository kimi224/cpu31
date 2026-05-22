create_clock -period 20.000 -name clk_pin -waveform {0.000 10.000} [get_ports clk_in]
set_false_path -from [get_ports reset]
set_output_delay -clock [get_clocks *] 0.000 [get_ports -filter { NAME =~  "*" && DIRECTION == "OUT" }]
