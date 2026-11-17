// =============================================================================
// File        : tb/uvm/timer_adc_scoreboard.sv   reference model and checkers
// Author      : Vu Quoc Anh (SE203519)
// Method      : Every observation carries the clock it happened in. Changes
//               (register writes, W1C clears, events, FIFO push / pop) are kept
//               per clock and applied ("committed") only when a later clock is
//               seen, in the order the hardware applies them at that edge. A
//               read is compared with the state after all earlier clocks, which
//               is exactly what the combinational read mux shows.
// =============================================================================
`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_adc)
class timer_adc_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(timer_adc_scoreboard)
    uvm_analysis_imp_apb #(apb_item, timer_adc_scoreboard) apb_imp;
    uvm_analysis_imp_adc #(adc_event, timer_adc_scoreboard) adc_imp;
    real VREF = 3.3; int tol_lsb = 0;
    // committed model state
    bit [7:0] sh [16];
    bit [5:0] flags; bit [9:0] fifo [$]; bit [1:0] lch; bit lvalid;
    // pending changes of the current clock
    longint pc = -1; apb_item pw [$]; bit [5:0] pset, pclr; bit ppop, ppush, povf_hw; bit [9:0] pdin; bit pos_done;
    // timer checks
    longint last_ovf = -1, last_cmp = -1, last_tmr_wr = 0, last_ctrl_on = 0;
    int n_conv, n_reads, n_status, n_tmr, n_err, n_wd, n_ovf;
    function new(string n, uvm_component p); super.new(n, p); apb_imp = new("apb_imp", this); adc_imp = new("adc_imp", this); endfunction
    function void build_phase(uvm_phase phase);
        foreach (sh[i]) sh[i] = timer_adc_reg_block::RESET[i];
        flags = 0; lch = 0; lvalid = 0; pset = 0; pclr = 0; ppop = 0; ppush = 0; pos_done = 0;
    endfunction
    function void err(string m); n_err++; `uvm_error("SB", m) endfunction
    function bit wm(); return fifo.size() >= (1 << sh[5][7:6]); endfunction
    // ---- apply everything that happened in clock pc (hardware order at the edge)
    function void commit();
        if (pc < 0) return;
        foreach (pw[i]) begin
            case (pw[i].addr)
                4'h0: sh[0] = pw[i].data & 8'h03;  4'h5: sh[5] = pw[i].data & 8'hFD;  4'hD: sh[13] = pw[i].data & 8'h7F;
                4'hE: pclr |= pw[i].data[5:0];
                default: if (timer_adc_reg_block::IS_RW[pw[i].addr]) sh[pw[i].addr] = pw[i].data;
            endcase
            if (pw[i].addr <= 4'h3) last_tmr_wr = pc;
            if (pw[i].addr == 4'h0 && pw[i].data[0]) last_ctrl_on = pc;
        end
        if (pos_done && !(pw.size() > 0 && pw[0].addr == 4'h0)) sh[0][0] = 1'b0;   // one-shot clears EN
        flags = (flags & ~pclr) | pset;
        if (ppop && fifo.size() > 0) begin lch = fifo[0][9:8]; lvalid = 1; void'(fifo.pop_front()); end
        if (ppush) begin if (fifo.size() < 8) fifo.push_back(pdin); end
        pw.delete(); pset = 0; pclr = 0; ppop = 0; ppush = 0; pos_done = 0;
    endfunction
    function void advance(longint c); if (c != pc) begin commit(); pc = c; end endfunction
    function void chk(bit [7:0] got, bit [7:0] exp, string what);
        if (got !== exp) err($sformatf("%s: read %h, expected %h (clock %0d)", what, got, exp, pc));
    endfunction
    // ---- register bus
    function void write_apb(apb_item t);
        advance(t.cycle);
        if (t.write) begin pw.push_back(t); return; end
        n_reads++;
        case (t.addr)
            4'h4: if (sh[0][0] && t.data > sh[2] && last_tmr_wr < pc - 2) err($sformatf("TMR_CNT %0d above LOAD %0d", t.data, sh[2]));
            4'hA: begin chk(t.data, fifo.size() ? fifo[0][7:0] : 8'h00, "ADC_DATA"); ppop = 1; end
            4'hB: chk(t.data, {fifo.size() != 0, lvalid, lch, 2'b00, fifo.size() ? fifo[0][9:8] : 2'b00}, "ADC_RCH");
            4'hC: begin n_status++; chk(t.data & 8'hBF, {wm(), 1'b0, fifo.size() == 8, fifo.size() == 0, 4'(fifo.size())}, "ADC_STAT"); end
            4'hE: begin n_status++; chk(t.data, {1'b0, wm(), flags}, "IRQ_STAT"); end
            4'hF: chk(t.data, 8'hA8, "ID");
            default: chk(t.data, sh[t.addr], timer_adc_reg_block::NAMES[t.addr]);
        endcase
    endfunction
    // ---- events of the timer and the ADC
    function void write_adc(adc_event e);
        int exp, lo, hi; bit full_drop;
        advance(e.cycle);
        pset |= {e.trig_miss, e.fifo_ovr, e.wd, e.eoc, e.tmr_cmp, e.tmr_ovf};
        if (e.tmr_ovf && sh[0][1]) pos_done = 1;
        if (e.eoc) begin
            n_conv++;
            exp = $floor(e.vhold * 256.0 / VREF); if (exp > 255) exp = 255; if (exp < 0) exp = 0;
            lo = exp - tol_lsb; hi = exp + tol_lsb;
            if (int'(e.result) < lo || int'(e.result) > hi) err($sformatf("ADC result %0d for %0.4f V, expected %0d +/- %0d", e.result, e.vhold, exp, tol_lsb));
            if (e.wd !== (e.result < sh[8] || e.result > sh[9])) err($sformatf("window flag %b for result %0d in [%0d, %0d]", e.wd, e.result, sh[8], sh[9]));
            if (e.wd) n_wd++;
            full_drop = (fifo.size() == 8) && !ppop;
            if (e.fifo_ovr !== full_drop) err($sformatf("FIFO overflow flag %b, model expects %b", e.fifo_ovr, full_drop));
            if (full_drop) n_ovf++;
            ppush = 1; pdin = {e.ch, e.result};
        end
        if (e.tmr_ovf) begin
            if (last_ovf >= 0 && last_tmr_wr < last_ovf && last_ctrl_on < last_ovf && sh[0][0] && !sh[0][1]) begin
                n_tmr++;
                if (e.cycle - last_ovf != (sh[1] + 1) * (sh[2] + 1)) err($sformatf("timer period %0d, expected %0d", e.cycle - last_ovf, (sh[1] + 1) * (sh[2] + 1)));
            end
            if (last_cmp > last_ovf && last_ovf >= 0 && last_tmr_wr < last_ovf && sh[3] <= sh[2]) begin
                n_tmr++;
                if (e.cycle - last_cmp != (sh[2] - sh[3]) * (sh[1] + 1)) err($sformatf("compare-to-overflow %0d, expected %0d", e.cycle - last_cmp, (sh[2] - sh[3]) * (sh[1] + 1)));
            end
            last_ovf = e.cycle;
        end
        if (e.tmr_cmp) begin if (e.cycle - (last_ovf < 0 ? 0 : last_ovf) < 0) err("compare before overflow"); last_cmp = e.cycle; end
    endfunction
    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf("checked %0d conversions, %0d FIFO/register reads (%0d status), %0d timer intervals, %0d window hits, %0d overflows; %0d errors",
                                   n_conv, n_reads, n_status, n_tmr, n_wd, n_ovf, n_err), UVM_NONE)
    endfunction
endclass
