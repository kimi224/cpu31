set root_dir [file normalize [file join [file dirname [info script]] ".."]]
set project_path [file join $root_dir "cpu31-test.xpr"]
set bit_path [file join $root_dir "cpu31-test.runs" "impl_1" "test.bit"]

open_project $project_path
set_property target_constrs_file [file join $root_dir "cpu31-test.srcs" "constrs_1" "new" "icf.xdc"] [current_fileset -constrset]
set_property top test [current_fileset]

set imem_ip [get_ips imem]
if {[llength $imem_ip] > 0} {
    set imem_xci [get_files -quiet [file join $root_dir "cpu31-test.srcs" "sources_1" "ip" "imem" "imem.xci"]]
    if {[llength $imem_xci] > 0} {
        set_property generate_synth_checkpoint false $imem_xci
    }
    generate_target all $imem_ip
    export_ip_user_files -of_objects $imem_ip -no_script -force -quiet
}

update_compile_order -fileset sources_1
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set run_status [get_property STATUS [get_runs impl_1]]
puts "IMPL_STATUS=$run_status"
if {![file exists $bit_path]} {
    error "Bitstream was not generated at $bit_path"
}
puts "BITSTREAM=$bit_path"
