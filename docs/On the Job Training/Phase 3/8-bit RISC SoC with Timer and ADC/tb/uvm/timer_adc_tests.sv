// =============================================================================
// File        : tb/uvm/timer_adc_tests.sv   12 runnable tests
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
class tadc_base_test extends uvm_test;
    `uvm_component_utils(tadc_base_test)
    timer_adc_env env; virtual apb_if vif;
    function new(string n, uvm_component p); super.new(n, p); endfunction
    function void build_phase(uvm_phase phase);
        env = timer_adc_env::type_id::create("env", this);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif)) `uvm_fatal("NOVIF", "apb_if not set")
    endfunction
    virtual task run_vseqs(); endtask
    task start_v(tadc_base_vseq v); v.rm = env.rm; v.adc_sqr = env.adc.sqr; v.vif = vif; v.start(null); endtask
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        @(posedge vif.rst_n); repeat (3) @(posedge vif.clk);
        run_vseqs();
        repeat (20) @(posedge vif.clk);
        phase.drop_objection(this);
    endtask
    function void report_phase(uvm_phase phase);
        uvm_report_server rs = uvm_report_server::get_server();
        if (rs.get_severity_count(UVM_ERROR) + rs.get_severity_count(UVM_FATAL) == 0) `uvm_info("TEST", $sformatf("%s PASSED", get_type_name()), UVM_NONE)
        else `uvm_info("TEST", $sformatf("%s FAILED", get_type_name()), UVM_NONE)
    endfunction
endclass
`define TADC_TEST(NAME, BODY) class NAME extends tadc_base_test; `uvm_component_utils(NAME) \
    function new(string n, uvm_component p); super.new(n, p); endfunction  virtual task run_vseqs(); BODY endtask endclass
`TADC_TEST(tadc_reg_test,       begin tadc_reg_vseq v = new; start_v(v); end)
`TADC_TEST(tadc_timer_test,     begin tadc_timer_vseq v = new; start_v(v); end)
`TADC_TEST(tadc_adc_sw_test,    begin tadc_adc_sw_vseq v = new; start_v(v); end)
`TADC_TEST(tadc_adc_timer_test, begin tadc_adc_timer_vseq v = new; start_v(v); end)
`TADC_TEST(tadc_adc_cont_test,  begin tadc_adc_cont_vseq v = new; start_v(v); end)
`TADC_TEST(tadc_window_test,    begin tadc_window_vseq v = new; start_v(v); end)
`TADC_TEST(tadc_noise_test,     begin tadc_noise_vseq v = new; env.sb.tol_lsb = 2; start_v(v); end)
`TADC_TEST(tadc_trig_miss_test, begin tadc_trig_miss_vseq v = new; start_v(v); end)
`TADC_TEST(tadc_wm_test,        begin tadc_wm_vseq v = new; start_v(v); end)
`TADC_TEST(tadc_latch_test,     begin tadc_latch_vseq v = new; start_v(v); end)
`TADC_TEST(tadc_random_test,    begin tadc_random_vseq v = new; v.rounds = 40; start_v(v); end)
`TADC_TEST(tadc_all_test,       begin tadc_reg_vseq a = new; tadc_timer_vseq b = new; tadc_adc_sw_vseq c = new; tadc_adc_timer_vseq d = new;
                                      tadc_adc_cont_vseq e = new; tadc_window_vseq f = new; tadc_noise_vseq g = new; tadc_trig_miss_vseq h = new;
                                      tadc_wm_vseq i = new; tadc_latch_vseq j = new; tadc_random_vseq k = new;
                                      start_v(a); start_v(b); start_v(c); start_v(d); start_v(e); start_v(f); env.sb.tol_lsb = 2; start_v(g);
                                      env.sb.tol_lsb = 0; start_v(h); start_v(i); start_v(j); start_v(k); end)
