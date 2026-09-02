set root_dir [file normalize [file join [file dirname [info script]] ".."]]
set src_dir [file join $root_dir "cpu31-test.srcs" "sources_1" "new"]
set sim_dir [file join $root_dir "cpu31-test.srcs" "sim_1" "new"]
set constr_dir [file join $root_dir "cpu31-test.srcs" "constrs_1" "new"]
file delete -force [file join $root_dir "postsim_top_new.dcp"]
file delete -force [file join $root_dir "postsim_impl_timing_summary_new.rpt"]
file delete -force [file join $root_dir "postsim_timesim_new.v"]
file delete -force [file join $root_dir "postsim_timesim_new.sdf"]

create_project -in_memory cpu31_postsim xc7a100tcsg324-1
cd $src_dir
read_verilog [file join $src_dir "regfile.v"]
read_verilog [file join $src_dir "scpc.v"]
read_verilog [file join $src_dir "scalu.v"]
read_verilog [file join $src_dir "sccontroller.v"]
read_verilog [file join $src_dir "scinstmem.v"]
read_verilog [file join $src_dir "scdatamem.v"]
read_verilog [file join $src_dir "scdatamem_postsim.v"]
read_verilog [file join $src_dir "sccpu.v"]
read_verilog [file join $src_dir "sccomp_dataflow.v"]
read_verilog [file join $src_dir "cpu31_board.v"]
read_verilog [file join $src_dir "postsim_top.v"]
read_verilog [file join $src_dir "seg7x16.v"]
read_ip [file join $root_dir "cpu31-test.srcs" "sources_1" "ip" "imem" "imem.xci"]
read_xdc [file join $constr_dir "postsim.xdc"]

synth_design -top postsim_top -part xc7a100tcsg324-1
write_checkpoint -force [file join $root_dir "postsim_top_new.dcp"]

opt_design
place_design
route_design

report_timing_summary -file [file join $root_dir "postsim_impl_timing_summary_new.rpt"]
write_verilog -force -mode timesim -sdf_anno true [file join $root_dir "postsim_timesim_new.v"]
write_sdf -force [file join $root_dir "postsim_timesim_new.sdf"]
