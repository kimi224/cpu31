set root_dir [file normalize [file join [file dirname [info script]] ".."]]
set src_dir [file join $root_dir "cpu31-test.srcs" "sources_1" "new"]
set constr_dir [file join $root_dir "cpu31-test.srcs" "constrs_1" "new"]
set work_xdc [file join $root_dir "tmp" "postsim_20ns.xdc"]

file mkdir [file join $root_dir "tmp"]
file delete -force [file join $root_dir "tmp" "postsim_impl_timing_summary_20ns.rpt"]

set fp [open $work_xdc "w"]
puts $fp {create_clock -period 20.000 -name clk_pin -waveform {0.000 10.000} [get_ports clk_in]}
puts $fp {set_false_path -from [get_ports reset]}
puts $fp {set_output_delay -clock [get_clocks clk_pin] 0.000 [get_ports -filter { NAME =~  "*" && DIRECTION == "OUT" }]}
close $fp

create_project -in_memory cpu31_postsim_20ns xc7a100tcsg324-1
cd $src_dir
read_verilog [file join $src_dir "regfile.v"]
read_verilog [file join $src_dir "scpc.v"]
read_verilog [file join $src_dir "scalu.v"]
read_verilog [file join $src_dir "sccontroller.v"]
read_verilog [file join $src_dir "scinstmem.v"]
read_verilog [file join $src_dir "scdatamem_postsim.v"]
read_verilog [file join $src_dir "sccpu.v"]
read_verilog [file join $src_dir "postsim_top.v"]
read_ip [file join $root_dir "cpu31-test.srcs" "sources_1" "ip" "imem" "imem.xci"]
read_xdc $work_xdc

synth_design -top postsim_top -part xc7a100tcsg324-1
opt_design
place_design
route_design
report_timing_summary -file [file join $root_dir "tmp" "postsim_impl_timing_summary_20ns.rpt"]
