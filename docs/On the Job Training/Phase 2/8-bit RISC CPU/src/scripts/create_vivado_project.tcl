# =============================================================================
# File    : scripts/create_vivado_project.tcl
# Project : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
# Author  : Vu Quoc Anh (SE203519)
# Job     : Creates the Vivado project for Basys 3 (xc7a35tcpg236-1) with all
#           design sources, the include path, the program file, the board
#           constraints, all testbenches and test programs. tb_cpu is the
#           simulation top and the simulation runs to $finish ("Run All").
# Usage   : batch : vivado -mode batch -source scripts/create_vivado_project.tcl
#           GUI   : Tcl console -> cd <repository>; source scripts/create_vivado_project.tcl
# Result  : vivado/cpu8_pipeline_SE203519/cpu8_pipeline_SE203519.xpr
# =============================================================================
set proj_name "cpu8_pipeline_SE203519"
set part      "xc7a35tcpg236-1"
set root      [file normalize [file join [file dirname [info script]] ..]]
set proj_dir  [file join $root vivado $proj_name]
set rtl_dir   [file join $root rtl]

create_project $proj_name $proj_dir -part $part -force
set_property target_language    Verilog [current_project]
set_property simulator_language Verilog [current_project]

# ---- design sources (F2) ----------------------------------------------------
add_files -fileset sources_1 [glob [file join $rtl_dir *.v]]
add_files -fileset sources_1 [file join $rtl_dir cpu_defs.vh]
set_property file_type {Verilog Header} [get_files cpu_defs.vh]
add_files -fileset sources_1 [file join $rtl_dir program.mem]
set_property include_dirs [list $rtl_dir] [get_filesets sources_1]
set_property top cpu_top [get_filesets sources_1]

# ---- constraints --------------------------------------------------------------
add_files -fileset constrs_1 [file join $root constraints basys3_cpu_top.xdc]

# ---- simulation sources -------------------------------------------------------
add_files -fileset sim_1 [glob [file join $root tb *.v]]
add_files -fileset sim_1 [glob [file join $root tb *.mem]]
set_property include_dirs [list $rtl_dir] [get_filesets sim_1]
set_property top tb_cpu [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "INFO: project $proj_name created in $proj_dir"
