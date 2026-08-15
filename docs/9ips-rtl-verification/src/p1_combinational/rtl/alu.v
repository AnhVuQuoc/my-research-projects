`timescale 1ns/1ps
`include "alu_defs.vh"

module alu #(
  parameter WIDTH = 8
)(
  input  wire [WIDTH-1:0]      a,
  input  wire [WIDTH-1:0]      b,
  input  wire [`ALU_OP_W-1:0]  op,
  output reg  [WIDTH-1:0]      y,
  output reg                   carry,
  output reg                   overflow,
  output wire                  zero,
  output wire                  negative
);


  function integer clog2;
    input integer value;
    integer v;
    begin
      v = value - 1;
      for (clog2 = 0; v > 0; clog2 = clog2 + 1)
        v = v >> 1;
    end
  endfunction

  localparam SHW = clog2(WIDTH);  
  localparam MSB = WIDTH - 1;


  wire is_sub = (op == `ALU_SUB) || (op == `ALU_SLT) || (op == `ALU_SLTU);

  wire [WIDTH-1:0] b_eff   = is_sub ? ~b : b;
  wire             add_cin = is_sub;

  wire [WIDTH-1:0] add_sum;
  wire             add_cout, add_ovf;

  ripple_carry_adder #(.WIDTH(WIDTH)) u_add (
    .a    (a       ),
    .b    (b_eff   ),
    .cin  (add_cin ),
    .sum  (add_sum ),
    .cout (add_cout),
    .ovf  (add_ovf )
  );

  wire [SHW-1:0] shamt = b[SHW-1:0];
  wire           slt_s = add_sum[MSB] ^ add_ovf;   // signed   a < b
  wire           slt_u = ~add_cout;                // unsigned a < b


  always @(*) begin
    y        = {WIDTH{1'b0}};
    carry    = 1'b0;
    overflow = 1'b0;

    case (op)
      `ALU_ADD  : begin y = add_sum;  carry = add_cout; overflow = add_ovf; end
      `ALU_SUB  : begin y = add_sum;  carry = add_cout; overflow = add_ovf; end
      `ALU_AND  : y = a & b;
      `ALU_OR   : y = a | b;
      `ALU_XOR  : y = a ^ b;
      `ALU_NOT  : y = ~a;
      `ALU_SLL  : y = a << shamt;
      `ALU_SRL  : y = a >> shamt;
      `ALU_SRA  : y = $signed(a) >>> shamt;
      `ALU_SLT  : y = {{(WIDTH-1){1'b0}}, slt_s};
      `ALU_SLTU : y = {{(WIDTH-1){1'b0}}, slt_u};
      `ALU_PASSB: y = b;
      default   : y = {WIDTH{1'b0}};   // reserved opcodes read as 0
    endcase
  end

  assign zero     = (y == {WIDTH{1'b0}});
  assign negative = y[MSB];

endmodule
