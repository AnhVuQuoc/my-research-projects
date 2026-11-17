// probe 2: constrained randomization (rand, constraint, dist, inside, randomize with)
module p2_rand;
  class cfg; rand bit [7:0] a, b; constraint c1 { a dist {0 := 1, [1:15] := 4}; } constraint c2 { b inside {[10:20]}; b > a; } endclass
  initial begin
    cfg c = new; int ok = 1;
    repeat (200) begin
      if (!c.randomize()) ok = 0;
      if (c.a > 15 || c.b < 10 || c.b > 20 || c.b <= c.a) ok = 0;
    end
    if (!c.randomize() with { a == 3; }) ok = 0; if (c.a != 3) ok = 0;
    $display("PROBE p2_rand %s", ok ? "PASS" : "FAIL"); $finish;
  end
endmodule
