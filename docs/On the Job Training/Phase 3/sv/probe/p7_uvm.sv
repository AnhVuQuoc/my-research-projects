// probe 7: UVM (needs -L uvm): component, config_db, sequence, driver, objection, report
`include "uvm_macros.svh"
module p7_uvm;
  import uvm_pkg::*;
  class itm extends uvm_sequence_item; rand int x; `uvm_object_utils(itm) function new(string n = "itm"); super.new(n); endfunction endclass
  class sq extends uvm_sequence #(itm); `uvm_object_utils(sq) function new(string n = "sq"); super.new(n); endfunction
    task body(); repeat (3) begin itm t = itm::type_id::create("t"); start_item(t); void'(t.randomize()); finish_item(t); end endtask endclass
  class dr extends uvm_driver #(itm); `uvm_component_utils(dr) int n; function new(string n, uvm_component p); super.new(n, p); endfunction
    task run_phase(uvm_phase ph); forever begin seq_item_port.get_next_item(req); n++; seq_item_port.item_done(); end endtask endclass
  class t extends uvm_test; `uvm_component_utils(t) dr d; uvm_sequencer #(itm) s;
    function new(string n, uvm_component p); super.new(n, p); endfunction
    function void build_phase(uvm_phase ph); d = dr::type_id::create("d", this); s = uvm_sequencer#(itm)::type_id::create("s", this); endfunction
    function void connect_phase(uvm_phase ph); d.seq_item_port.connect(s.seq_item_export); endfunction
    task run_phase(uvm_phase ph); sq q = sq::type_id::create("q"); ph.raise_objection(this); q.start(s); ph.drop_objection(this); endtask
    function void report_phase(uvm_phase ph); $display("PROBE p7_uvm %s", d.n == 3 ? "PASS" : "FAIL"); endfunction endclass
  initial run_test("t");
endmodule
