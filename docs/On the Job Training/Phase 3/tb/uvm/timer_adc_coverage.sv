// =============================================================================
// File        : tb/uvm/timer_adc_coverage.sv   5 coverage groups
// Author      : Vu Quoc Anh (SE203519)
// Note        : the bins are kept as counters (not covergroup) so that the same
//               file runs on Verilator and on commercial simulators.
// =============================================================================
`uvm_analysis_imp_decl(_capb)
`uvm_analysis_imp_decl(_cadc)
class timer_adc_coverage extends uvm_component;
    `uvm_component_utils(timer_adc_coverage)
    uvm_analysis_imp_capb #(apb_item, timer_adc_coverage) apb_imp;
    uvm_analysis_imp_cadc #(adc_event, timer_adc_coverage) adc_imp;
    bit [7:0] sh [16]; int level; bit[5:0] fl;
    int cg_set [string], cg_res [string], cg_fifo [string], cg_tmr [string], cg_irq [string];
    function new(string n, uvm_component p); super.new(n, p); apb_imp = new("apb_imp", this); adc_imp = new("adc_imp", this);
        foreach (sh[i]) sh[i] = timer_adc_reg_block::RESET[i]; level = 0; fl = 0; define_bins(); endfunction
    function void define_bins();
        string a [$];
        for (int t = 0; t < 4; t++) for (int c = 0; c < 4; c++) cg_set[$sformatf("trig%0d_ch%0d", t, c)] = 0;
        a = '{"smp0", "smp1_3", "smp4_15", "smp16p", "div0", "div1", "div2_7", "div8p"}; foreach (a[i]) cg_set[a[i]] = 0;
        a = '{"zero", "low", "midlow", "midhigh", "high", "full"};
        for (int c = 0; c < 4; c++) foreach (a[i]) cg_res[$sformatf("ch%0d_%s", c, a[i])] = 0;
        for (int l = 0; l <= 8; l++) cg_fifo[$sformatf("read_at_level%0d", l)] = 0;
        a = '{"overflow", "pop_empty", "wm1_on", "wm2_on", "wm4_on", "wm8_on"}; foreach (a[i]) cg_fifo[a[i]] = 0;
        a = '{"presc0", "presc_small", "presc_big", "load0", "load_small", "load_big", "load255", "cmp0", "cmp_gt_load", "oneshot", "ovf_seen", "cmp_seen"};
        foreach (a[i]) cg_tmr[a[i]] = 0;
        for (int b = 0; b < 6; b++) begin cg_irq[$sformatf("set%0d", b)] = 0; cg_irq[$sformatf("clear%0d", b)] = 0; end
        cg_irq["wm_irq_enabled"] = 0; cg_irq["irq_en_any"] = 0;
    endfunction
    function void hit(ref int cg [string], input string k); if (cg.exists(k)) cg[k]++; endfunction
    function void write_capb(apb_item t);
        if (t.write) begin
            if (timer_adc_reg_block::IS_RW[t.addr]) sh[t.addr] = t.data;
            if (t.addr == 4'h5 && (t.data[0])) begin
                hit(cg_set, $sformatf("trig%0d_ch%0d", t.data[3:2], t.data[5:4]));
                begin string k; if (sh[6] == 0) k = "smp0"; else if (sh[6] < 4) k = "smp1_3"; else if (sh[6] < 16) k = "smp4_15"; else k = "smp16p"; hit(cg_set, k); end
                begin string k; if (sh[7] == 0) k = "div0"; else if (sh[7] == 1) k = "div1"; else if (sh[7] < 8) k = "div2_7"; else k = "div8p"; hit(cg_set, k); end
            end
            if (t.addr == 4'h0 && t.data[0]) begin
                begin string k; if (sh[1] == 0) k = "presc0"; else if (sh[1] < 16) k = "presc_small"; else k = "presc_big"; hit(cg_tmr, k); end
                begin string k; if (sh[2] == 0) k = "load0"; else if (sh[2] < 16) k = "load_small"; else if (sh[2] == 255) k = "load255"; else k = "load_big"; hit(cg_tmr, k); end
                if (sh[3] == 0) hit(cg_tmr, "cmp0"); if (sh[3] > sh[2]) hit(cg_tmr, "cmp_gt_load"); if (t.data[1]) hit(cg_tmr, "oneshot");
            end
            if (t.addr == 4'hE) for (int b = 0; b < 6; b++) if (t.data[b] && fl[b]) begin hit(cg_irq, $sformatf("clear%0d", b)); fl[b] = 0; end
            if (t.addr == 4'hD) begin if (t.data[6]) hit(cg_irq, "wm_irq_enabled"); if (t.data != 0) hit(cg_irq, "irq_en_any"); end
        end
        else begin
            if (t.addr == 4'hC) begin level = t.data[3:0]; hit(cg_fifo, $sformatf("read_at_level%0d", level));
                if (t.data[7]) hit(cg_fifo, $sformatf("wm%0d_on", 1 << sh[5][7:6])); end
            if (t.addr == 4'hA && t.data == 0 && level == 0) hit(cg_fifo, "pop_empty");
        end
    endfunction
    function void write_cadc(adc_event e);
        bit [5:0] ev = {e.trig_miss, e.fifo_ovr, e.wd, e.eoc, e.tmr_cmp, e.tmr_ovf};
        for (int b = 0; b < 6; b++) if (ev[b]) begin hit(cg_irq, $sformatf("set%0d", b)); fl[b] = 1; end
        if (e.fifo_ovr) hit(cg_fifo, "overflow");
        if (e.tmr_ovf) hit(cg_tmr, "ovf_seen"); if (e.tmr_cmp) hit(cg_tmr, "cmp_seen");
        if (e.eoc) begin
            string r;                            // if/else, not a ternary of string literals of different lengths
            if (e.result == 0) r = "zero"; else if (e.result < 64) r = "low"; else if (e.result < 128) r = "midlow";
            else if (e.result < 192) r = "midhigh"; else if (e.result < 255) r = "high"; else r = "full";
            hit(cg_res, $sformatf("ch%0d_%s", e.ch, r));
        end
    endfunction
    function real pct(ref int cg [string], input string name);
        int h = 0; string miss = "";
        foreach (cg[k]) if (cg[k] > 0) h++; else if (miss.len() < 80) miss = {miss, " ", k};
        `uvm_info("COV", $sformatf("%-14s %6.1f %% (%0d of %0d bins)%s", name, 100.0 * h / cg.num(), h, cg.num(), miss.len() ? {"  missing:", miss} : ""), UVM_NONE)
        return 100.0 * h / cg.num();
    endfunction
    function void report_phase(uvm_phase phase);
        void'(pct(cg_set, "ADC settings")); void'(pct(cg_res, "ADC results")); void'(pct(cg_fifo, "FIFO")); void'(pct(cg_tmr, "Timer")); void'(pct(cg_irq, "Interrupts"));
    endfunction
endclass
