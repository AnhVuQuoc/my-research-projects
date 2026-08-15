`timescale 1ns / 1ps

module twiddle_rom #(
    parameter integer N          = 256,
    parameter integer DATA_WIDTH = 16,
    parameter         RE_FILE    = "twiddle_re.mem",
    parameter         IM_FILE    = "twiddle_im.mem"
)(
    input  wire                          clk,
    input  wire                          en,
    input  wire [$clog2(N/2)-1:0]        addr,
    output reg  signed [DATA_WIDTH-1:0]  tw_re,
    output reg  signed [DATA_WIDTH-1:0]  tw_im
);
    reg signed [DATA_WIDTH-1:0] rom_re [0:N/2-1];
    reg signed [DATA_WIDTH-1:0] rom_im [0:N/2-1];

    initial begin
        $readmemh(RE_FILE, rom_re);
        $readmemh(IM_FILE, rom_im);
    end

    always @(posedge clk) begin
        if (en) begin
            tw_re <= rom_re[addr];
            tw_im <= rom_im[addr];
        end
    end
endmodule
