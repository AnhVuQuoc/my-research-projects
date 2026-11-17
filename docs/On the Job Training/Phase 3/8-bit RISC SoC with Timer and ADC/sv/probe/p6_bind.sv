// probe 6: bind a checker into a module (the construct that failed on the SoC)
module p6_dut (input logic clk, input logic [3:0] a, output logic [3:0] y); always @(posedge clk) y <= a; endmodule
module p6_chk (input logic clk, input logic [3:0] a, input logic [3:0] y); int n = 0;
  always @(posedge clk) n++; a_hold : assert property (@(posedge clk) y == $past(a)); endmodule
bind p6_dut p6_chk u_chk (.clk(clk), .a(a), .y(y));
module p6_bind;
  logic clk = 0; logic [3:0] a = 0, y; always #5 clk = ~clk;
  p6_dut dut (.clk(clk), .a(a), .y(y));
  initial begin repeat (12) begin @(negedge clk); a = $urandom; end
    $display("PROBE p6_bind %s", dut.u_chk.n > 5 ? "PASS" : "FAIL"); $finish; end
endmodule
