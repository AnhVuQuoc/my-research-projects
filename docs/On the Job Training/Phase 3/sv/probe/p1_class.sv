// probe 1: classes, inheritance, virtual methods, queues, associative arrays, strings
module p1_class;
  class base; int id; function new(int i); id = i; endfunction virtual function string name(); return "base"; endfunction endclass
  class child extends base; function new(int i); super.new(i); endfunction virtual function string name(); return "child"; endfunction endclass
  initial begin
    base b; child c = new(7); int q [$]; int aa [string];
    b = c; q.push_back(3); q.push_back(4); aa["x"] = 5;
    if (b.name() == "child" && b.id == 7 && q.size() == 2 && q.pop_front() == 3 && aa.exists("x")) $display("PROBE p1_class PASS");
    else $display("PROBE p1_class FAIL");
    $finish;
  end
endmodule
