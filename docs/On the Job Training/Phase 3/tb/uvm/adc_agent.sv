// =============================================================================
// File        : tb/uvm/adc_agent.sv   voltage item, driver, event monitor, agent
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
class adc_item extends uvm_sequence_item;
    rand int unsigned ch;                    // which input to change
    rand int unsigned mv;                    // new value in millivolts
    real offset = 0.0, noise = 0.0;
    constraint c_range { ch < 4; mv <= 3400; }
    `uvm_object_utils(adc_item)
    function new(string name = "adc_item"); super.new(name); endfunction
endclass

class adc_event extends uvm_object;           // what the monitor reports each clock with an event
    longint cycle; bit eoc, tmr_ovf, tmr_cmp, trig_miss, wd, fifo_ovr; bit [7:0] result; bit [1:0] ch; real vhold;
    `uvm_object_utils(adc_event)
    function new(string name = "adc_event"); super.new(name); endfunction
endclass

class adc_driver extends uvm_driver #(adc_item);
    `uvm_component_utils(adc_driver)
    virtual adc_if vif;
    function new(string n, uvm_component p); super.new(n, p); endfunction
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual adc_if)::get(this, "", "adc_vif", vif)) `uvm_fatal("NOVIF", "adc_if not set")
    endfunction
    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            vif.vin[req.ch] = req.mv / 1000.0; vif.offset = req.offset; vif.noise = req.noise;
            seq_item_port.item_done();
        end
    endtask
endclass

class adc_monitor extends uvm_monitor;
    `uvm_component_utils(adc_monitor)
    virtual adc_if vif; virtual apb_if bif;
    uvm_analysis_port #(adc_event) ap;
    real hold_at_eoc;
    function new(string n, uvm_component p); super.new(n, p); ap = new("ap", this); endfunction
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual adc_if)::get(this, "", "adc_vif", vif)) `uvm_fatal("NOVIF", "adc_if not set")
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", bif)) `uvm_fatal("NOVIF", "apb_if not set")
    endfunction
    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && (vif.eoc || vif.tmr_ovf || vif.tmr_cmp || vif.trig_miss || vif.fifo_ovr)) begin
                adc_event e = adc_event::type_id::create("e");
                e.cycle = bif.cycle; e.eoc = vif.eoc; e.tmr_ovf = vif.tmr_ovf; e.tmr_cmp = vif.tmr_cmp; e.trig_miss = vif.trig_miss;
                e.wd = vif.wd; e.fifo_ovr = vif.fifo_ovr; e.result = vif.result; e.ch = vif.result_ch; e.vhold = vif.vhold;
                ap.write(e);
            end
        end
    endtask
endclass

class adc_agent extends uvm_agent;
    `uvm_component_utils(adc_agent)
    adc_driver drv; adc_monitor mon; uvm_sequencer #(adc_item) sqr;
    function new(string n, uvm_component p); super.new(n, p); endfunction
    function void build_phase(uvm_phase phase);
        drv = adc_driver::type_id::create("drv", this); mon = adc_monitor::type_id::create("mon", this);
        sqr = uvm_sequencer#(adc_item)::type_id::create("sqr", this);
    endfunction
    function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
endclass
