`timescale 1ns/1ps

module hex7seg #(
  parameter COMMON_ANODE = 0
)(
  input  wire [3:0] val_i,
  input  wire       blank_i,
  output wire [6:0] seg_o
);

  reg [6:0] pat;

  always @(*) begin
    case (val_i)
      4'h0: pat = 7'h3F;   
      4'h1: pat = 7'h06;   
      4'h2: pat = 7'h5B;   
      4'h3: pat = 7'h4F;   
      4'h4: pat = 7'h66;   
      4'h5: pat = 7'h6D;   
      4'h6: pat = 7'h7D;   
      4'h7: pat = 7'h07;   
      4'h8: pat = 7'h7F;   
      4'h9: pat = 7'h6F;   
      4'hA: pat = 7'h77;   
      4'hB: pat = 7'h7C;   
      4'hC: pat = 7'h39;   
      4'hD: pat = 7'h5E;   
      4'hE: pat = 7'h79;   
      4'hF: pat = 7'h71;  
      default: pat = 7'h00;
    endcase
  end

  wire [6:0] drive = blank_i ? 7'h00 : pat;

  assign seg_o = COMMON_ANODE ? ~drive : drive;

endmodule
