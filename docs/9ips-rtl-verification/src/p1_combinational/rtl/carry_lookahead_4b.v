`timescale 1ns/1ps

module carry_lookahead_4b (
  input  wire [3:0] a,
  input  wire [3:0] b,
  input  wire       cin,
  output wire [3:0] sum,
  output wire       cout,
  output wire       pg,    
  output wire       gg      
);

  wire [3:0] g, p;
  wire [4:1] c;

  assign g = a & b;  
  assign p = a ^ b;  

  assign c[1] = g[0] | (p[0] & cin);
  assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0])
                     | (p[2] & p[1] & p[0] & cin);
  assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1])
                     | (p[3] & p[2] & p[1] & g[0])
                     | (p[3] & p[2] & p[1] & p[0] & cin);

  assign sum  = p ^ {c[3], c[2], c[1], cin};
  assign cout = c[4];

  assign pg   = &p;
  assign gg   = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1])
                     | (p[3] & p[2] & p[1] & g[0]);

endmodule
