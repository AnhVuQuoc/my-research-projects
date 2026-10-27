# =============================================================================
# File    : scripts/synth_report.tcl
# Project : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
# Author  : Vu Quoc Anh (SE203519)
# Job     : Non-project batch flow that produces the numbers for the
#           "measure, then explain" step: utilization, timing summary,
#           critical path and an Fmax estimate, after synthesis and
#           (with "impl") after place and route.
# Usage   : vivado -mode batch -source scripts/synth_report.tcl
#           vivado -mode batch -source scripts/synth_report.tcl -tclargs impl
#           vivado -mode batch -source scripts/synth_report.tcl -tclargs impl 4.0
#             arg 1: synth (default) or impl
#             arg 2: clock period in ns used for the analysis (default 10.0)
# Output  : reports/*.rpt and a line "RESULT: ..." in the log
# Fmax    : Fmax = 1000 / (period - WNS) MHz (register-to-register paths)
# =============================================================================
set mode   "synth"
set period 10.0
if {$argc > 0} { set mode   [lindex $argv 0] }
if {$argc > 1} { set period [lindex $argv 1] }

set part    "xc7a35tcpg236-1"
set root    [file normalize [file join [file dirname [info script]] ..]]
set rtl_dir [file join $root rtl]
set out     [file join $root reports]
file mkdir $out
cd $rtl_dir                                  ;# $readmemh finds program.mem here

read_verilog [glob [file join $rtl_dir *.v]]
read_xdc [file join $root constraints basys3_cpu_top.xdc]
synth_design -top cpu_top -part $part -include_dirs [list $rtl_dir]
if {$period != 10.0} {
    create_clock -name sys_clk_pin -period $period [get_ports clk]   ;# override 10 ns
}

proc write_reports {tag period out} {
    report_utilization    -file [file join $out utilization_$tag.rpt]
    report_timing_summary -max_paths 5 -file [file join $out timing_summary_$tag.rpt]
    report_timing -max_paths 1 -nworst 1 -file [file join $out critical_path_$tag.rpt]
    set wns  [get_property SLACK [lindex [get_timing_paths -delay_type max -max_paths 1] 0]]
    set fmax [expr {1000.0 / ($period - $wns)}]
    puts [format "RESULT (%s): period %.3f ns, WNS %.3f ns, estimated Fmax %.1f MHz" $tag $period $wns $fmax]
}

write_reports synth $period $out
if {$mode eq "impl"} {
    opt_design
    place_design
    route_design
    write_reports impl $period $out
}
