`timescale 1ns/1ps

module priority_encoder_8to3 (
  input  wire [7:0] d_i,
  output reg  [2:0] y_o,
  output reg        vld_o
);

  always @* begin
    y_o   = 3'd0;
    vld_o = 1'b0;
    casez (d_i)
      8'b1???_????: begin y_o = 3'd7; vld_o = 1'b1; end
      8'b01??_????: begin y_o = 3'd6; vld_o = 1'b1; end
      8'b001?_????: begin y_o = 3'd5; vld_o = 1'b1; end
      8'b0001_????: begin y_o = 3'd4; vld_o = 1'b1; end
      8'b0000_1???: begin y_o = 3'd3; vld_o = 1'b1; end
      8'b0000_01??: begin y_o = 3'd2; vld_o = 1'b1; end
      8'b0000_001?: begin y_o = 3'd1; vld_o = 1'b1; end
      8'b0000_0001: begin y_o = 3'd0; vld_o = 1'b1; end
      default:      begin y_o = 3'd0; vld_o = 1'b0; end
    endcase
  end

endmodule
