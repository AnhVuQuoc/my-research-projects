`timescale 1ns / 1ps
module sync_2ff (
    input  wire clk,
    input  wire rst_n,
    input  wire async_in,
    output wire sync_out
);
    (* ASYNC_REG = "TRUE" *) reg s1, s2;
    always @(posedge clk) begin
        if (!rst_n) begin s1 <= 1'b0; s2 <= 1'b0; end
        else        begin s1 <= async_in; s2 <= s1; end
    end
    assign sync_out = s2;
endmodule
