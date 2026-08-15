`timescale 1ns / 1ps

module window_unit #(
    parameter integer N          = 256,
    parameter integer DATA_WIDTH = 16,
    parameter         COEFF_FILE = "window_coeff.mem"
)(
    input  wire                          clk,
    input  wire                          rst_n,

    input  wire                          in_valid,
    input  wire signed [DATA_WIDTH-1:0]  in_data,
    input  wire                          in_sof,
    input  wire                          in_last,

    output reg                           out_valid,
    output reg  signed [DATA_WIDTH-1:0]  out_data,
    output reg                           out_sof,
    output reg                           out_last
);

    localparam integer ADDR_W = $clog2(N);

    reg [ADDR_W-1:0] prev_pos;

    wire [ADDR_W-1:0] cur_pos = in_sof ? {ADDR_W{1'b0}} : (prev_pos + 1'b1);

    always @(posedge clk) begin
        if (!rst_n) begin
            prev_pos <= {ADDR_W{1'b0}};
        end else if (in_valid) begin
            prev_pos <= cur_pos;
        end
    end

    wire signed [DATA_WIDTH-1:0] coeff;

    window_rom #(
        .N          (N),
        .DATA_WIDTH (DATA_WIDTH),
        .COEFF_FILE (COEFF_FILE)
    ) u_window_rom (
        .addr  (cur_pos),
        .coeff (coeff)
    );

    wire signed [2*DATA_WIDTH-1:0] product = $signed(in_data) * $signed(coeff);

    localparam integer SHIFT = DATA_WIDTH - 1;

    localparam signed [DATA_WIDTH:0] SAT_MAX =  (1 <<< (DATA_WIDTH-1)) - 1;
    localparam signed [DATA_WIDTH:0] SAT_MIN = -(1 <<< (DATA_WIDTH-1));

    function automatic signed [DATA_WIDTH-1:0] round_sat_shift;
        input signed [2*DATA_WIDTH-1:0] full;
        reg   signed [2*DATA_WIDTH-1:0] shifted;
        reg   [SHIFT-2:0]               lower_bits;
        begin
            lower_bits = full[SHIFT-2:0];

            if (full[SHIFT-1] == 1'b0) begin
                shifted = full >>> SHIFT;
            end else if (lower_bits != 0) begin
                shifted = (full >>> SHIFT) + 1;
            end else begin
                if (full[SHIFT] == 1'b0)
                    shifted = full >>> SHIFT;
                else
                    shifted = (full >>> SHIFT) + 1;
            end

            if (shifted > SAT_MAX)
                round_sat_shift = SAT_MAX[DATA_WIDTH-1:0];
            else if (shifted < SAT_MIN)
                round_sat_shift = SAT_MIN[DATA_WIDTH-1:0];
            else
                round_sat_shift = shifted[DATA_WIDTH-1:0];
        end
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_data  <= {DATA_WIDTH{1'b0}};
            out_sof   <= 1'b0;
            out_last  <= 1'b0;
        end else begin
            out_valid <= in_valid;
            out_data  <= round_sat_shift(product);
            out_sof   <= in_valid && in_sof;
            out_last  <= in_valid && in_last;
        end
    end

endmodule
