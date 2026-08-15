`timescale 1ns / 1ps

module window_rom #(
    parameter integer N          = 256,
    parameter integer DATA_WIDTH = 16,
    parameter         COEFF_FILE = "window_coeff.mem"
)(
    input  wire [$clog2(N)-1:0]         addr,
    output wire signed [DATA_WIDTH-1:0] coeff
);

    reg signed [DATA_WIDTH-1:0] rom [0:N-1];

    initial begin
        $readmemh(COEFF_FILE, rom);
    end

    assign coeff = rom[addr];

endmodule
