// probe 4: concurrent assertions (|->, |=>, $past, $rose, disable iff, cover)
module p4_sva;
  logic clk = 0, rst_n = 0, req = 0, ack = 0; int hits = 0;
  always #5 clk = ~clk;
  always @(posedge clk) ack <= req;                 // ack follows req by 1 clock
  a_follow : assert property (@(posedge clk) disable iff (!rst_n) req |=> ack);
  a_past   : assert property (@(posedge clk) disable iff (!rst_n) ack |-> $past(req));
  c_rise   : cover  property (@(posedge clk) $rose(req)) hits++;
  initial begin
    #12 rst_n = 1;
    repeat (20) begin @(negedge clk); req = $urandom_range(1); end
    $display("PROBE p4_sva %s (cover hits %0d; an assertion failure above means FAIL)", hits > 0 ? "PASS" : "FAIL", hits); $finish;
  end
endmodule
