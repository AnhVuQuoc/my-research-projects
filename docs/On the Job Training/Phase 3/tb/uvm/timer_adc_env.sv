// =============================================================================
// File        : tb/uvm/timer_adc_env.sv   builds and connects every part
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
class timer_adc_env extends uvm_env;
    `uvm_component_utils(timer_adc_env)
    apb_agent apb; adc_agent adc; timer_adc_reg_block rm; apb_reg_adapter adapter;
    timer_adc_scoreboard sb; timer_adc_coverage cov;
    function new(string n, uvm_component p); super.new(n, p); endfunction
    function void build_phase(uvm_phase phase);
        apb = apb_agent::type_id::create("apb", this); adc = adc_agent::type_id::create("adc", this);
        sb = timer_adc_scoreboard::type_id::create("sb", this); cov = timer_adc_coverage::type_id::create("cov", this);
        rm = timer_adc_reg_block::type_id::create("rm"); rm.build(); adapter = apb_reg_adapter::type_id::create("adapter");
    endfunction
    function void connect_phase(uvm_phase phase);
        rm.default_map.set_sequencer(apb.sqr, adapter); rm.default_map.set_auto_predict(1);
        apb.mon.ap.connect(sb.apb_imp); adc.mon.ap.connect(sb.adc_imp);
        apb.mon.ap.connect(cov.apb_imp); adc.mon.ap.connect(cov.adc_imp);
    endfunction
endclass
