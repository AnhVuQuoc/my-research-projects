// =============================================================================
// File        : tb/uvm/timer_adc_pkg.sv   includes every UVM file in order
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
package timer_adc_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "apb_agent.sv"
    `include "adc_agent.sv"
    `include "timer_adc_ral.sv"
    `include "timer_adc_scoreboard.sv"
    `include "timer_adc_coverage.sv"
    `include "timer_adc_env.sv"
    `include "timer_adc_seq_lib.sv"
    `include "timer_adc_tests.sv"
endpackage
