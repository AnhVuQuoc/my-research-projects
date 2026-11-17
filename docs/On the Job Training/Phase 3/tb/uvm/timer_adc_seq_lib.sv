// =============================================================================
// File        : tb/uvm/timer_adc_seq_lib.sv   helper tasks and 12 scenarios
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
class tadc_cfg extends uvm_object;                      // constrained-random configuration
    rand bit [7:0] smp, div, presc, load, cmp, thr_lo, thr_hi;
    rand bit [1:0] ch, trig, wm;
    rand bit       oneshot;
    constraint c_smp   { smp   dist {0 := 3, [1:3] := 3, [4:15] := 2, [16:40] := 1}; }
    constraint c_div   { div   dist {0 := 4, 1 := 2, [2:7] := 2, [8:20] := 1}; }
    constraint c_presc { presc dist {0 := 2, [1:15] := 3, [16:255] := 1}; }
    constraint c_load  { load  dist {0 := 1, [1:15] := 4, [16:254] := 2, 255 := 1}; }
    constraint c_cmp   { cmp <= load + 2; }
    constraint c_thr   { thr_lo <= thr_hi; }
    constraint c_os    { oneshot dist {0 := 4, 1 := 1}; }
    `uvm_object_utils(tadc_cfg)
    function new(string name = "tadc_cfg"); super.new(name); endfunction
endclass

class tadc_base_vseq extends uvm_sequence;
    `uvm_object_utils(tadc_base_vseq)
    timer_adc_reg_block rm; uvm_sequencer #(adc_item) adc_sqr; virtual apb_if vif;
    localparam TMR_CTRL = 0, TMR_PRESC = 1, TMR_LOAD = 2, TMR_CMP = 3, TMR_CNT = 4, ADC_CTRL = 5, ADC_SMP = 6, ADC_DIV = 7,
               THR_LO = 8, THR_HI = 9, ADC_DATA = 10, ADC_RCH = 11, ADC_STAT = 12, IRQ_EN = 13, IRQ_STAT = 14, ID = 15;
    function new(string name = "tadc_base_vseq"); super.new(name); endfunction
    task wr(int a, bit [7:0] d); uvm_status_e st; rm.regs[a].write(st, d); endtask
    task rd(int a, output bit [7:0] d); uvm_status_e st; uvm_reg_data_t v; rm.regs[a].read(st, v); d = v[7:0]; endtask
    task rd_(int a); bit [7:0] d; rd(a, d); endtask
    task clocks(int n); repeat (n) @(posedge vif.clk); endtask
    task vin(int c, int mv, real off = 0.0, real noise = 0.0);
        adc_item it = adc_item::type_id::create("it");
        start_item(it, -1, adc_sqr); it.ch = c; it.mv = mv; it.offset = off; it.noise = noise; finish_item(it);
    endtask
    task wait_level(int n, int limit = 4000); bit [7:0] s; int k = 0;
        do begin rd(ADC_STAT, s); k++; end while (s[3:0] < n && k < limit);
    endtask
    task drain(); bit [7:0] s; rd(ADC_STAT, s); while (!s[4]) begin rd_(ADC_RCH); rd_(ADC_DATA); rd(ADC_STAT, s); end endtask
    task conv_sw(int c); wr(ADC_CTRL, 8'h03 | (c << 4)); wait_level(1); rd_(ADC_RCH); rd_(ADC_DATA); rd_(ADC_RCH); endtask
    task clear_all(); wr(IRQ_STAT, 8'h3F); endtask
    task stop_all(); wr(TMR_CTRL, 0); wr(ADC_CTRL, 0); drain(); rd_(IRQ_STAT); clear_all(); endtask
endclass

class tadc_reg_vseq extends tadc_base_vseq;        // reset values, bit-bash, read-only protection
    `uvm_object_utils(tadc_reg_vseq)
    function new(string name = "tadc_reg_vseq"); super.new(name); endfunction
    task body(); bit [7:0] pat [4] = '{8'hFF, 8'h00, 8'h55, 8'hAA};
        for (int a = 0; a < 16; a++) rd_(a);
        foreach (pat[p]) for (int a = 0; a < 16; a++) if (a != ADC_CTRL && a != TMR_CTRL && a != ADC_DATA) begin wr(a, pat[p]); rd_(a); end
        wr(TMR_CTRL, 8'h02); rd_(TMR_CTRL); wr(TMR_CTRL, 0); wr(ADC_CTRL, 8'hF0); rd_(ADC_CTRL); wr(ADC_CTRL, 0); rd_(ADC_CTRL);
        wr(ADC_SMP, 4); wr(THR_HI, 8'hFF); wr(THR_LO, 0); wr(IRQ_EN, 0); clear_all();
    endtask
endclass

class tadc_timer_vseq extends tadc_base_vseq;      // 14 timer settings
    `uvm_object_utils(tadc_timer_vseq)
    function new(string name = "tadc_timer_vseq"); super.new(name); endfunction
    task body(); int s [14][4] = '{'{0,0,0,0}, '{0,1,1,0}, '{1,4,2,0}, '{3,24,10,0}, '{0,9,3,0}, '{7,7,8,0}, '{0,255,128,0},
                                   '{255,1,0,0}, '{2,5,0,1}, '{0,3,1,1}, '{15,15,15,0}, '{5,0,0,0}, '{1,100,50,0}, '{0,20,25,0}};
        foreach (s[i]) begin
            wr(TMR_CTRL, 0); wr(TMR_PRESC, s[i][0]); wr(TMR_LOAD, s[i][1]); wr(TMR_CMP, s[i][2]); wr(TMR_CTRL, 1 | (s[i][3] << 1));
            repeat (6) begin clocks(((s[i][0] + 1) * (s[i][1] + 1)) / 2 + 3 > 600 ? 600 : ((s[i][0] + 1) * (s[i][1] + 1)) / 2 + 3); rd_(TMR_CNT); rd_(TMR_CTRL); end
            rd_(IRQ_STAT); clear_all();
        end
        wr(TMR_CTRL, 0);
    endtask
endclass

class tadc_adc_sw_vseq extends tadc_base_vseq;     // corner voltages and random inputs
    `uvm_object_utils(tadc_adc_sw_vseq)
    function new(string name = "tadc_adc_sw_vseq"); super.new(name); endfunction
    task body(); int mv [9] = '{0, 6, 13, 26, 1111, 1650, 3274, 3300, 3400};
        wr(ADC_SMP, 2); wr(ADC_DIV, 0);
        for (int c = 0; c < 4; c++) foreach (mv[i]) begin vin(c, mv[i]); conv_sw(c); end
        repeat (40) begin vin($urandom_range(3), $urandom_range(3350)); wr(ADC_SMP, $urandom_range(6)); wr(ADC_DIV, $urandom_range(3)); conv_sw($urandom_range(3)); end
        for (int c = 0; c < 4; c++) for (int k = 0; k < 6; k++) begin vin(c, k * 640 + c * 37); conv_sw(c); end
        rd_(IRQ_STAT); clear_all();
    endtask
endclass

class tadc_adc_timer_vseq extends tadc_base_vseq;  // timer-started conversions of a ramp
    `uvm_object_utils(tadc_adc_timer_vseq)
    function new(string name = "tadc_adc_timer_vseq"); super.new(name); endfunction
    task body();
        for (int t = 1; t <= 2; t++) begin
            wr(ADC_SMP, 3); wr(ADC_DIV, 0); wr(TMR_PRESC, 3); wr(TMR_LOAD, 24); wr(TMR_CMP, 12);
            wr(ADC_CTRL, 8'h01 | (t << 2) | (2 << 4)); wr(TMR_CTRL, 1);
            for (int k = 0; k < 24; k++) begin vin(2, 100 + k * 130); wait_level(2); rd_(ADC_RCH); rd_(ADC_DATA); end
            stop_all();
        end
    endtask
endclass

class tadc_adc_cont_vseq extends tadc_base_vseq;   // continuous mode, overflow, abort, clear races
    `uvm_object_utils(tadc_adc_cont_vseq)
    function new(string name = "tadc_adc_cont_vseq"); super.new(name); endfunction
    task body();
        vin(1, 2222); wr(ADC_SMP, 0); wr(ADC_DIV, 0); wr(ADC_CTRL, 8'h1D);           // continuous, ch1
        clocks(300); rd_(ADC_STAT); rd_(IRQ_STAT);                                    // FIFO full, overflow
        repeat (5) begin rd_(ADC_DATA); clocks(4); end
        for (int k = 0; k < 60; k++) begin wr(IRQ_STAT, 8'h3F); rd_(IRQ_STAT); clocks($urandom_range(5)); end   // clears racing with eoc
        wr(ADC_CTRL, 0); drain();
        vin(2, 1234); wr(ADC_CTRL, 8'h2D); clocks(80); wr(ADC_CTRL, 0); drain();   // continuous on ch2
        repeat (20) begin wr(ADC_SMP, 3); wr(ADC_CTRL, 8'h03); clocks($urandom_range(14)); wr(ADC_CTRL, 0); clocks(3); rd_(ADC_STAT); end  // aborts
        drain(); rd_(IRQ_STAT); clear_all();
    endtask
endclass

class tadc_window_vseq extends tadc_base_vseq;     // window comparator at the exact boundary codes
    `uvm_object_utils(tadc_window_vseq)
    function new(string name = "tadc_window_vseq"); super.new(name); endfunction
    task body(); int lo [4] = '{50, 0, 100, 200}, hi [4] = '{150, 255, 100, 254};
        wr(ADC_SMP, 1);
        foreach (lo[i]) begin
            wr(THR_LO, lo[i]); wr(THR_HI, hi[i]);
            for (int d = -1; d <= 1; d++) begin
                if (lo[i] + d >= 0 && lo[i] + d <= 255) begin vin(0, int'(((lo[i] + d) + 0.5) * 3300.0 / 256.0)); conv_sw(0); rd_(IRQ_STAT); clear_all(); end
                if (hi[i] + d >= 0 && hi[i] + d <= 255) begin vin(0, int'(((hi[i] + d) + 0.5) * 3300.0 / 256.0)); conv_sw(0); rd_(IRQ_STAT); clear_all(); end
            end
        end
        wr(THR_LO, 0); wr(THR_HI, 8'hFF);
    endtask
endclass

class tadc_noise_vseq extends tadc_base_vseq;      // comparator offset and noise, checked with a tolerance
    `uvm_object_utils(tadc_noise_vseq)
    function new(string name = "tadc_noise_vseq"); super.new(name); endfunction
    task body();
        int o;                                   // signed: an unsigned $urandom_range minus 5 would wrap to a huge offset
        repeat (60) begin o = $urandom_range(10); o = o - 5; vin(3, $urandom_range(50, 3250), o / 1000.0, 0.004); conv_sw(3); end
        vin(3, 1000, 0.0, 0.0);
    endtask
endclass

class tadc_trig_miss_vseq extends tadc_base_vseq;  // triggers faster than conversions
    `uvm_object_utils(tadc_trig_miss_vseq)
    function new(string name = "tadc_trig_miss_vseq"); super.new(name); endfunction
    task body();
        vin(0, 700); wr(ADC_SMP, 4); wr(TMR_PRESC, 0); wr(TMR_LOAD, 5); wr(ADC_CTRL, 8'h05); wr(TMR_CTRL, 1);
        repeat (10) begin wait_level(3); rd_(IRQ_STAT); drain(); clear_all(); end
        stop_all();
    endtask
endclass

class tadc_wm_vseq extends tadc_base_vseq;         // NEW: watermark 1, 2, 4, 8 and its level-based flag
    `uvm_object_utils(tadc_wm_vseq)
    function new(string name = "tadc_wm_vseq"); super.new(name); endfunction
    task body();
        vin(2, 1500); wr(ADC_SMP, 1); wr(IRQ_EN, 8'h40);
        for (int w = 0; w < 4; w++) begin
            for (int n = 0; n < 9; n++) begin wr(ADC_CTRL, 8'h03 | (2 << 4) | (w << 6)); wait_level(n + 1 > 8 ? 8 : n + 1); rd_(ADC_STAT); rd_(IRQ_STAT); end
            wr(IRQ_STAT, 8'h40); rd_(IRQ_STAT);                                    // FIFO_WM is not W1C
            drain(); rd_(ADC_STAT); rd_(IRQ_STAT); clear_all();
        end
        wr(IRQ_EN, 0); wr(ADC_CTRL, 0);
    endtask
endclass

class tadc_latch_vseq extends tadc_base_vseq;      // NEW: channel latched by the pop (both read orders)
    `uvm_object_utils(tadc_latch_vseq)
    function new(string name = "tadc_latch_vseq"); super.new(name); endfunction
    task body();
        for (int c = 0; c < 4; c++) vin(c, 400 + 800 * c);
        wr(ADC_SMP, 0);
        repeat (6) begin
            for (int c = 0; c < 4; c++) begin wr(ADC_CTRL, 8'h03 | (c << 4)); wait_level(c + 1); end
            for (int c = 0; c < 4; c++) if (c % 2) begin rd_(ADC_DATA); rd_(ADC_RCH); end else begin rd_(ADC_RCH); rd_(ADC_DATA); end
            rd_(ADC_RCH); rd_(ADC_DATA); rd_(ADC_RCH);                               // read while empty: latch kept
        end
        wr(ADC_CTRL, 0);
    endtask
endclass

class tadc_random_vseq extends tadc_base_vseq;     // constrained-random settings and register traffic
    `uvm_object_utils(tadc_random_vseq)
    int unsigned rounds = 25;
    function new(string name = "tadc_random_vseq"); super.new(name); endfunction
    task body(); tadc_cfg cfg = tadc_cfg::type_id::create("cfg");
        repeat (rounds) begin
            if (!cfg.randomize()) `uvm_error("RAND", "randomize failed")
            wr(TMR_CTRL, 0); wr(ADC_CTRL, 0); drain();
            wr(ADC_SMP, cfg.smp); wr(ADC_DIV, cfg.div); wr(TMR_PRESC, cfg.presc); wr(TMR_LOAD, cfg.load); wr(TMR_CMP, cfg.cmp);
            wr(THR_LO, cfg.thr_lo); wr(THR_HI, cfg.thr_hi); wr(IRQ_EN, $urandom_range(127));
            for (int c = 0; c < 4; c++) vin(c, $urandom_range(3350));
            wr(ADC_CTRL, 8'h01 | (cfg.trig << 2) | (cfg.ch << 4) | (cfg.wm << 6)); wr(TMR_CTRL, 1 | (cfg.oneshot << 1));
            repeat (30) case ($urandom_range(7))
                0: rd_(ADC_DATA); 1: rd_(ADC_RCH); 2: rd_(ADC_STAT); 3: rd_(IRQ_STAT); 4: wr(IRQ_STAT, $urandom_range(63));
                5: wr(ADC_CTRL, 8'h03 | (cfg.ch << 4) | (cfg.trig << 2)); 6: clocks($urandom_range(60)); default: rd_($urandom_range(15));
            endcase
        end
        stop_all();
    endtask
endclass
