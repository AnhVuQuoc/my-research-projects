`timescale 1ns/1ps
`include "tb_utils.vh"
`include "alu_defs.vh"

module tb_alu;

  `TB_DECLARE

  localparam W = 8;

  reg  [W-1:0]          a, b;
  reg  [`ALU_OP_W-1:0]  op;
  wire [W-1:0]          y;
  wire                  carry, overflow, zero, negative;

  alu #(.WIDTH(W)) u_dut (
    .a(a), .b(b), .op(op),
    .y(y), .carry(carry), .overflow(overflow),
    .zero(zero), .negative(negative));

  `TB_DUMP(tb_alu, "tb_alu.vcd")


  task ref_alu;
    input  [W-1:0]         ta, tbb;
    input  [`ALU_OP_W-1:0] top;
    output [W-1:0]         ty;
    output                 tcarry, tovf;
    reg    [W:0]           acc;
    reg    [2:0]           sh;
    reg    [W-1:0]         sgn_mask;
    begin
      ty = {W{1'b0}}; tcarry = 1'b0; tovf = 1'b0;
      sh = tbb[2:0];
      case (top)
        `ALU_ADD : begin
          acc    = {1'b0, ta} + {1'b0, tbb};
          ty     = acc[W-1:0];
          tcarry = acc[W];
          tovf   = (ta[W-1] == tbb[W-1]) && (ty[W-1] != ta[W-1]);
        end
        `ALU_SUB : begin
          acc    = {1'b0, ta} + {1'b0, ~tbb} + 1'b1;
          ty     = acc[W-1:0];
          tcarry = acc[W];                       // 1 = no borrow
          tovf   = (ta[W-1] != tbb[W-1]) && (ty[W-1] != ta[W-1]);
        end
        `ALU_AND  : ty = ta & tbb;
        `ALU_OR   : ty = ta | tbb;
        `ALU_XOR  : ty = ta ^ tbb;
        `ALU_NOT  : ty = ~ta;
        `ALU_SLL  : ty = ta << sh;
        `ALU_SRL  : ty = ta >> sh;
        `ALU_SRA  : begin
          sgn_mask = ta[W-1] ? ~({W{1'b1}} >> sh) : {W{1'b0}};
          ty       = (ta >> sh) | sgn_mask;    
        end
        `ALU_SLT  : ty = ($signed(ta) <  $signed(tbb)) ? 1 : 0;
        `ALU_SLTU : ty = (ta < tbb) ? 1 : 0;
        `ALU_PASSB: ty = tbb;
        default   : ty = {W{1'b0}};
      endcase
    end
  endtask


  reg [W-1:0] e_y;
  reg         e_carry, e_ovf;

  task do_op;
    input [W-1:0]         ta, tbb;
    input [`ALU_OP_W-1:0] top;
    begin
      a = ta; b = tbb; op = top;
      #1;
      ref_alu(ta, tbb, top, e_y, e_carry, e_ovf);
      `CHECK_EQ("y",        y,        e_y            )
      `CHECK_EQ("carry",    carry,    e_carry        )
      `CHECK_EQ("overflow", overflow, e_ovf          )
      `CHECK_EQ("zero",     zero,     (e_y == 0)     )
      `CHECK_EQ("negative", negative, e_y[W-1]       )
    end
  endtask


  integer i, j, o, seed;
  reg [`ALU_OP_W-1:0] opv;         
  reg [W-1:0] corner [0:7];

  initial begin
    seed = 32'h1234_5678;

    corner[0] = 8'h00;   
    corner[1] = 8'h01;   
    corner[2] = 8'h7F;   
    corner[3] = 8'h80;   
    corner[4] = 8'hFF;   
    corner[5] = 8'hAA;   
    corner[6] = 8'h55;   
    corner[7] = 8'h40;   

    `TB_BANNER("tb_alu")


    `INFO("phase 1 : opcode sweep over corner operands")
    for (o = 0; o <= `ALU_PASSB; o = o + 1) begin
      opv = o;                      
      for (i = 0; i < 8; i = i + 1)
        for (j = 0; j < 8; j = j + 1)
          do_op(corner[i], corner[j], opv);
    end


    `INFO("phase 2 : flag corner cases")
    do_op(8'h7F, 8'h01, `ALU_ADD );  
    do_op(8'hFF, 8'h01, `ALU_ADD );  
    do_op(8'h80, 8'h80, `ALU_ADD );  
    do_op(8'h80, 8'h01, `ALU_SUB );
    do_op(8'h00, 8'h01, `ALU_SUB );  
    do_op(8'h05, 8'h05, `ALU_SUB );  
    do_op(8'h80, 8'h7F, `ALU_SLT );  
    do_op(8'h80, 8'h7F, `ALU_SLTU);  
    do_op(8'h80, 8'h07, `ALU_SRA );  
    do_op(8'h80, 8'h07, `ALU_SRL );  
    do_op(8'h01, 8'h07, `ALU_SLL );  


    `INFO("phase 3 : 20000 random transactions")
    for (i = 0; i < 20000; i = i + 1) begin
      a   = $random(seed);
      b   = $random(seed);
      o   = {$random(seed)} % (`ALU_PASSB + 1);
      opv = o;                       
      do_op(a, b, opv);
    end

    `TB_SUMMARY("tb_alu")
    $finish;
  end

endmodule
