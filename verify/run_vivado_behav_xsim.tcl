set root_dir [file normalize [file join [file dirname [info script]] ".."]]
set work_dir [file join $root_dir "tmp" "xsim_behav_vivado"]
set proj_dir [file join $work_dir "proj"]
set src_dir [file join $root_dir "cpu31-test.srcs" "sources_1" "new"]
set sim_dir [file join $root_dir "cpu31-test.srcs" "sim_1" "new"]
set ip_dir [file join $root_dir "cpu31-test.srcs" "sources_1" "ip" "imem"]

file mkdir $work_dir
file mkdir $proj_dir
cd $work_dir

create_project -force cpu31_behav_xsim $proj_dir -part xc7a100tcsg324-1
set_property target_simulator XSim [current_project]

add_files -fileset sources_1 [file join $src_dir "regfile.v"]
add_files -fileset sources_1 [file join $src_dir "scpc.v"]
add_files -fileset sources_1 [file join $src_dir "scalu.v"]
add_files -fileset sources_1 [file join $src_dir "sccontroller.v"]
add_files -fileset sources_1 [file join $src_dir "scinstmem.v"]
add_files -fileset sources_1 [file join $src_dir "scdatamem.v"]
add_files -fileset sources_1 [file join $src_dir "sccpu.v"]
add_files -fileset sources_1 [file join $src_dir "sccomp_dataflow.v"]
add_files -fileset sources_1 [file join $ip_dir "imem.xci"]

add_files -fileset sim_1 [file join $sim_dir "_246tb_ex9_tb.v"]

set_property top sccomp_dataflow [get_filesets sources_1]
set_property top _246tb_ex9_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property source_set sources_1 [get_filesets sim_1]

set_property XSIM.ELABORATE.DEBUG_LEVEL off [get_filesets sim_1]
set_property XSIM.ELABORATE.RELAX true [get_filesets sim_1]
set_property XSIM.ELABORATE.MT_LEVEL 4 [get_filesets sim_1]
set_property XSIM.SIMULATE.RUNTIME 30us [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -mode behavioral
run all
close_sim

close_project
