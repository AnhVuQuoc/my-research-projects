# =============================================================================
# run_probes.tcl: which SystemVerilog / UVM features does this XSim support?
# Usage (Vivado Tcl Console):
#   source "C:/.../risc8_soc_timer_adc_SE203519/sv/probe/run_probes.tcl"
# Each probe is compiled, elaborated and run in its own folder (sv/probe/xsim_probe_run).
# The table at the end shows PASS, FAIL, or the step that failed with its first ERROR line.
# Pure Tcl (no grep), works on Windows and Linux.
# =============================================================================
set here [file dirname [file normalize [info script]]]
set work [file join $here xsim_probe_run]
file mkdir $work
proc tool {name} { set p [auto_execok $name]; if {$p eq ""} { error "$name not found in PATH" }; return $p }
proc first_match {file pattern} {
    if {![file exists $file]} { return "" }
    set f [open $file]; set txt [read $f]; close $f
    foreach l [split $txt "\n"] { if {[string match $pattern $l]} { return [string range $l 0 150] } }
    return ""
}
set results {}
foreach p {p1_class p2_rand p3_cov p4_sva p5_vif p6_bind p7_uvm} {
    set d [file join $work $p]; file delete -force $d; file mkdir $d; cd $d
    set L [expr {$p eq "p7_uvm" ? {-L uvm} : {}}]
    if {[catch {exec {*}[tool xvlog] -sv {*}$L [file join $here $p.sv] >& compile.log}]} {
        lappend results [format "%-9s compile FAILED   %s" $p [first_match compile.log "ERROR*"]]; continue }
    if {[catch {exec {*}[tool xelab] {*}$L -debug off $p -s snap >& elab.log}]} {
        lappend results [format "%-9s elaborate FAILED %s" $p [first_match elab.log "ERROR*"]]; continue }
    catch {exec {*}[tool xsim] snap -R >& run.log}
    set r [first_match run.log "PROBE*"]
    set e [first_match run.log "*Error*"]
    if {$r eq ""} { set r "run FAILED (no PROBE line)" }
    lappend results [format "%-9s %s %s" $p $r [expr {$e ne "" ? "| $e" : ""}]]
}
cd $here
puts "\n================ XSim feature probes ================"
foreach r $results { puts $r }
puts "======================================================"
