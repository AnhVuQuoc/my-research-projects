// probe 3: functional coverage (covergroup, coverpoint, bins, cross, sample, get_coverage)
module p3_cov;
  bit [3:0] v; bit [1:0] m;
  covergroup cg; cp_v : coverpoint v { bins lo = {[0:7]}; bins hi = {[8:15]}; } cp_m : coverpoint m; x : cross cp_v, cp_m; endgroup
  initial begin
    cg g = new;
    for (int i = 0; i < 64; i++) begin v = i; m = i >> 4; g.sample(); end
    $display("PROBE p3_cov %s (coverage %0.1f %%)", g.get_coverage() > 99.0 ? "PASS" : "FAIL", g.get_coverage()); $finish;
  end
endmodule
