// probe 5: interface, virtual interface in a class, mailbox, fork / join_none, events
interface p5_if (input logic clk); logic [7:0] d; logic v; endinterface
module p5_vif;
  logic clk = 0; always #5 clk = ~clk;
  p5_if bus (clk);
  class drv; virtual p5_if vif; mailbox #(int) mb; function new(virtual p5_if i, mailbox #(int) m); vif = i; mb = m; endfunction
    task run(); int x; forever begin mb.get(x); @(posedge vif.clk); vif.d <= x; vif.v <= 1; @(posedge vif.clk); vif.v <= 0; end endtask endclass
  initial begin
    mailbox #(int) mb = new; drv dr = new(bus, mb); int seen = 0;
    fork dr.run(); join_none
    fork forever begin @(posedge clk); if (bus.v) seen++; end join_none
    for (int i = 0; i < 5; i++) mb.put(i);
    repeat (20) @(posedge clk);
    $display("PROBE p5_vif %s (%0d transfers)", seen == 5 ? "PASS" : "FAIL", seen); $finish;
  end
endmodule
