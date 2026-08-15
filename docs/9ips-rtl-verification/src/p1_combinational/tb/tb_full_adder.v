`timescale 1ns/1ps
`include "tb_utils.vh"

module tb_full_adder;

  `TB_DECLARE

  reg  a, b, cin;
  wire sum, cout;

  full_adder u_dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

  `TB_DUMP(tb_full_adder, "tb_full_adder.vcd")

  integer i;
  reg [1:0] exp;

  initial begin
    `TB_BANNER("tb_full_adder - exhaustive")

    for (i = 0; i < 8; i = i + 1) begin
      {a, b, cin} = i[2:0];
      #1;                                   
      exp = a + b + cin;                    
      `CHECK_EQ("sum",  sum,  exp[0])
      `CHECK_EQ("cout", cout, exp[1])
    end

    `TB_SUMMARY("tb_full_adder")
    $finish;
  end

endmodule
