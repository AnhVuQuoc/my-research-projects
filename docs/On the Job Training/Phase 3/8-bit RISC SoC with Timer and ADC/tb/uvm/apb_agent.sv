// =============================================================================
// File        : tb/uvm/apb_agent.sv   APB item, driver, monitor, agent
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
class apb_item extends uvm_sequence_item;
    rand bit       write;
    rand bit [3:0] addr;
    rand bit [7:0] data;
    longint        cycle;                               // access-phase clock (monitor)
    `uvm_object_utils(apb_item)
    function new(string name = "apb_item"); super.new(name); endfunction
    function string convert2string(); return $sformatf("%s addr %h data %h @%0d", write ? "WR" : "RD", addr, data, cycle); endfunction
endclass

class apb_driver extends uvm_driver #(apb_item);
    `uvm_component_utils(apb_driver)
    virtual apb_if vif;
    function new(string n, uvm_component p); super.new(n, p); endfunction
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif)) `uvm_fatal("NOVIF", "apb_if not set")
    endfunction
    task run_phase(uvm_phase phase);
        vif.psel <= 0; vif.penable <= 0; vif.pwrite <= 0; vif.paddr <= 0; vif.pwdata <= 0;
        forever begin
            seq_item_port.get_next_item(req);
            @(posedge vif.clk);                        // setup phase
            vif.psel <= 1; vif.penable <= 0; vif.pwrite <= req.write; vif.paddr <= req.addr; vif.pwdata <= req.data;
            @(posedge vif.clk);                        // access phase
            vif.penable <= 1;
            @(negedge vif.clk); if (!req.write) req.data = vif.prdata;
            @(posedge vif.clk);
            vif.psel <= 0; vif.penable <= 0;
            seq_item_port.item_done();
        end
    endtask
endclass

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)
    virtual apb_if vif;
    uvm_analysis_port #(apb_item) ap;
    function new(string n, uvm_component p); super.new(n, p); ap = new("ap", this); endfunction
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif)) `uvm_fatal("NOVIF", "apb_if not set")
    endfunction
    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.psel && vif.penable) begin
                apb_item t = apb_item::type_id::create("t");
                t.write = vif.pwrite; t.addr = vif.paddr; t.data = vif.pwrite ? vif.pwdata : vif.prdata; t.cycle = vif.cycle;
                ap.write(t);
            end
        end
    endtask
endclass

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)
    apb_driver drv; apb_monitor mon; uvm_sequencer #(apb_item) sqr;
    function new(string n, uvm_component p); super.new(n, p); endfunction
    function void build_phase(uvm_phase phase);
        drv = apb_driver::type_id::create("drv", this); mon = apb_monitor::type_id::create("mon", this);
        sqr = uvm_sequencer#(apb_item)::type_id::create("sqr", this);
    endfunction
    function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
endclass
