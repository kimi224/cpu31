set root_dir [file normalize [file join [file dirname [info script]] ".."]]
set work_dir [file join $root_dir "tmp" "xsim_postsynth_vivado"]
set proj_dir [file join $work_dir "proj"]
set src_dir [file join $root_dir "cpu31-test.srcs" "sources_1" "new"]
set sim_dir [file join $root_dir "cpu31-test.srcs" "sim_1" "new"]
set constr_dir [file join $root_dir "cpu31-test.srcs" "constrs_1" "new"]
set ip_dir [file join $root_dir "cpu31-test.srcs" "sources_1" "ip" "imem"]

file mkdir $work_dir
file mkdir $proj_dir
file delete -force [file join $root_dir "tmp" "postsim_result.txt"]

create_project -force cpu31_postsynth_xsim $proj_dir -part xc7a100tcsg324-1
set_property target_simulator XSim [current_project]

add_files -fileset sources_1 [file join $src_dir "regfile.v"]
add_files -fileset sources_1 [file join $src_dir "scpc.v"]
add_files -fileset sources_1 [file join $src_dir "scalu.v"]
add_files -fileset sources_1 [file join $src_dir "sccontroller.v"]
add_files -fileset sources_1 [file join $src_dir "scinstmem.v"]
add_files -fileset sources_1 [file join $src_dir "scdatamem_postsim.v"]
add_files -fileset sources_1 [file join $src_dir "sccpu.v"]
add_files -fileset sources_1 [file join $src_dir "postsim_top.v"]
add_files -fileset sources_1 [file join $ip_dir "imem.xci"]

add_files -fileset sim_1 [file join $sim_dir "postsim_tb.v"]
add_files -fileset constrs_1 [file join $constr_dir "postsim.xdc"]

set_property top postsim_top [get_filesets sources_1]
set_property top postsim_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property source_set sources_1 [get_filesets sim_1]

set_property XSIM.ELABORATE.DEBUG_LEVEL off [get_filesets sim_1]
set_property XSIM.ELABORATE.RELAX true [get_filesets sim_1]
set_property XSIM.ELABORATE.MT_LEVEL 4 [get_filesets sim_1]
set_property XSIM.SIMULATE.RUNTIME 250us [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_runs synth_1 -jobs 2
wait_on_run synth_1
open_run synth_1

report_timing_summary -file [file join $work_dir "postsim_synth_timing_summary_xsim.rpt"]

launch_simulation -mode post-synthesis -type timing -batch

close_project
