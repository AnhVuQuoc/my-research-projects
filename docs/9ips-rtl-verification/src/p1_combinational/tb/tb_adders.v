`timescale 1ns/1ps
`include "tb_utils.vh"

module tb_adders;

  `TB_DECLARE


  reg  [3:0] a4, b4;
  reg        c4;
  wire [3:0] rca4_sum, cla4_sum;
  wire       rca4_cout, cla4_cout, rca4_ovf, cla4_pg, cla4_gg;

  ripple_carry_adder #(.WIDTH(4)) u_rca4 (
    .a(a4), .b(b4), .cin(c4), .sum(rca4_sum), .cout(rca4_cout), .ovf(rca4_ovf));

  carry_lookahead_4b u_cla4 (
    .a(a4), .b(b4), .cin(c4), .sum(cla4_sum), .cout(cla4_cout),
    .pg(cla4_pg), .gg(cla4_gg));


  reg  [7:0] a8, b8;
  reg        c8;
  wire [7:0] rca8_sum;
  wire       rca8_cout, rca8_ovf;

  ripple_carry_adder #(.WIDTH(8)) u_rca8 (
    .a(a8), .b(b8), .cin(c8), .sum(rca8_sum), .cout(rca8_cout), .ovf(rca8_ovf));

  `TB_DUMP(tb_adders, "tb_adders.vcd")

  task ref_add8;
    input  [7:0] ta, tb_, tc;
    output [7:0] tsum;
    output       tcout, tovf;
    reg    [8:0] full;
    begin
      full  = {1'b0, ta} + {1'b0, tb_} + tc[0];
      tsum  = full[7:0];
      tcout = full[8];
      
      tovf  = (ta[7] == tb_[7]) && (tsum[7] != ta[7]);
    end
  endtask

  integer i, j, k, seed;
  reg [7:0] e_sum;
  reg       e_cout, e_ovf;

  initial begin
    seed = 32'hC0FFEE;
    `TB_BANNER("tb_adders")


    `INFO("phase 1 : exhaustive equivalence RCA-4 vs CLA-4 (512 vectors)")
    for (i = 0; i < 16; i = i + 1)
      for (j = 0; j < 16; j = j + 1)
        for (k = 0; k < 2; k = k + 1) begin
          a4 = i[3:0]; b4 = j[3:0]; c4 = k[0];
          #1;
          `CHECK_EQ("rca4_vs_cla4_sum",  cla4_sum,  rca4_sum )
          `CHECK_EQ("rca4_vs_cla4_cout", cla4_cout, rca4_cout)
        end


    `INFO("phase 2 : directed corner cases (8-bit)")
    for (i = 0; i < 8; i = i + 1) begin
      case (i)
        0: begin a8=8'h00; b8=8'h00; c8=1'b0; end  
        1: begin a8=8'hFF; b8=8'h01; c8=1'b0; end 
        2: begin a8=8'hFF; b8=8'hFF; c8=1'b1; end  
        3: begin a8=8'h7F; b8=8'h01; c8=1'b0; end  
        4: begin a8=8'h80; b8=8'hFF; c8=1'b0; end  
        5: begin a8=8'h7F; b8=8'h80; c8=1'b0; end  
        6: begin a8=8'h00; b8=8'h00; c8=1'b1; end  
        7: begin a8=8'hAA; b8=8'h55; c8=1'b0; end 
      endcase
      #1;
      ref_add8(a8, b8, {7'b0, c8}, e_sum, e_cout, e_ovf);
      `CHECK_EQ("rca8_sum",  rca8_sum,  e_sum )
      `CHECK_EQ("rca8_cout", rca8_cout, e_cout)
      `CHECK_EQ("rca8_ovf",  rca8_ovf,  e_ovf )
    end


    `INFO("phase 3 : 2000 random vectors (8-bit)")
    for (i = 0; i < 2000; i = i + 1) begin
      a8 = $random(seed);
      b8 = $random(seed);
      c8 = $random(seed);
      #1;
      ref_add8(a8, b8, {7'b0, c8}, e_sum, e_cout, e_ovf);
      `CHECK_EQ("rnd_sum",  rca8_sum,  e_sum )
      `CHECK_EQ("rnd_cout", rca8_cout, e_cout)
      `CHECK_EQ("rnd_ovf",  rca8_ovf,  e_ovf )
    end

    `TB_SUMMARY("tb_adders")
    $finish;
  end

endmodule
