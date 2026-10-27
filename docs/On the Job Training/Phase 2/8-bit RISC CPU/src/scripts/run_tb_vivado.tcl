# =============================================================================
# File    : scripts/run_tb_vivado.tcl
# Project : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
# Author  : Vu Quoc Anh (SE203519)
# Job     : Helpers to run testbenches inside the open Vivado project.
# Usage   : (project open) source scripts/run_tb_vivado.tcl
#           run_tb tb_alu        ;# one testbench, waveform window stays open
#           run_all_tbs          ;# all 17 testbenches one after the other
# Note    : the project sets xsim.simulate.runtime = all, so each launch runs
#           to $finish (same as pressing "Run All"). Read the PASS line in the
#           Tcl console.
# =============================================================================
proc run_tb {tb} {
    set_property top $tb [get_filesets sim_1]
    update_compile_order -fileset sim_1
    launch_simulation -simset sim_1 -mode behavioral
}

proc run_all_tbs {} {
    foreach tb {tb_alu tb_mux2 tb_mux3 tb_register_file tb_program_counter
                tb_instruction_memory tb_instruction_register tb_control_unit
                tb_hazard_unit tb_halt_unit tb_forwarding_unit tb_id_ex_register
                tb_flag_register tb_ex_mem_register tb_data_memory tb_mem_wb_register tb_cpu} {
        puts "INFO: ===== $tb ====="
        run_tb $tb
        close_sim -force
    }
    set_property top tb_cpu [get_filesets sim_1]
}
