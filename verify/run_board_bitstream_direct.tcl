set root_dir [file normalize [file join [file dirname [info script]] ".."]]
set src_dir [file join $root_dir "cpu31-test.srcs" "sources_1" "new"]
set ip_dir [file join $root_dir "cpu31-test.srcs" "sources_1" "ip" "imem"]
set constr_dir [file join $root_dir "cpu31-test.srcs" "constrs_1" "new"]
set out_dir [file join $root_dir "cpu31-test.runs" "board_direct"]

file mkdir $out_dir
cd $ip_dir

create_project -in_memory cpu31_board_bit xc7a100tcsg324-1
set_property target_language Verilog [current_project]

read_verilog [file join $src_dir "scpc.v"]
read_verilog [file join $src_dir "regfile.v"]
read_verilog [file join $src_dir "sccontroller.v"]
read_verilog [file join $src_dir "scalu.v"]
read_verilog [file join $src_dir "scdatamem.v"]
read_verilog [file join $src_dir "sccpu.v"]
read_verilog [file join $src_dir "scinstmem_board.v"]
read_verilog [file join $src_dir "cpu31_board.v"]
read_verilog [file join $src_dir "seg7x16.v"]
read_verilog [file join $src_dir "test.v"]
read_verilog [file join $ip_dir "imem_stub.v"]
read_xdc [file join $constr_dir "icf.xdc"]

synth_design -top test -part xc7a100tcsg324-1
read_checkpoint -cell cpu_board/imem/imem [file join $root_dir "cpu31-test.runs" "imem_synth_1" "imem.dcp"]
write_checkpoint -force [file join $out_dir "post_synth.dcp"]
report_utilization -file [file join $out_dir "post_synth_utilization.rpt"]

opt_design
place_design
route_design
report_timing_summary -file [file join $out_dir "timing_summary.rpt"]
write_bitstream -force [file join $out_dir "test.bit"]

puts "BITSTREAM=[file join $out_dir test.bit]"
