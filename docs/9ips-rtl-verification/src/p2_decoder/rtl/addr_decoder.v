`timescale 1ns/1ps

module addr_decoder #(
  parameter AW = 32,
  parameter NS = 4,
 
  parameter [NS*32-1:0] BASE_VEC = { 32'h4000_1000,    
                                     32'h4000_0000,    
                                     32'h2000_0000,    
                                     32'h0000_0000 },  
  parameter [NS*32-1:0] MASK_VEC = { 32'hFFFF_F000,    
                                     32'hFFFF_F000,    
                                     32'hFFFF_8000,    
                                     32'hFFFC_0000 }  
)(
  input  wire [AW-1:0]  addr_i,
  input  wire           valid_i,
  output wire [NS-1:0]  sel_o,
  output wire           err_o
);

  genvar i;
  generate
    for (i = 0; i < NS; i = i + 1) begin : g_region
      wire [AW-1:0] base = BASE_VEC[i*32 +: AW];
      wire [AW-1:0] mask = MASK_VEC[i*32 +: AW];
      assign sel_o[i] = valid_i && ((addr_i & mask) == (base & mask));
    end
  endgenerate

  assign err_o = valid_i && ~(|sel_o);

endmodule
