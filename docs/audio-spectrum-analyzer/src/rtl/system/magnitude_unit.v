`timescale 1ns / 1ps

module magnitude_unit #(
    parameter integer NUM_BINS   = 128,
    parameter integer DATA_WIDTH = 16,
    parameter integer ENABLE_LOG = 1
)(
    input  wire                              clk,
    input  wire                              rst_n,

    input  wire                              in_valid,
    input  wire signed [DATA_WIDTH-1:0]      in_re,
    input  wire signed [DATA_WIDTH-1:0]      in_im,
    input  wire                              in_sof,
    input  wire                              in_last,

    output reg                               out_valid,
    output reg  [DATA_WIDTH-1:0]             out_magnitude,
    output reg  [$clog2(NUM_BINS)-1:0]       out_bin_idx,
    output reg                               out_sof,
    output reg                               out_last,
    output reg  signed [15:0]                out_mag_log2
);

    localparam integer BIN_ADDR_W = $clog2(NUM_BINS);
    localparam [DATA_WIDTH-1:0] ALPHA_Q15 = 16'd31471;
    localparam [DATA_WIDTH-1:0] BETA_Q15  = 16'd13036;

    reg [BIN_ADDR_W-1:0] prev_idx;
    wire [BIN_ADDR_W-1:0] cur_idx = in_sof ? {BIN_ADDR_W{1'b0}} : (prev_idx + 1'b1);

    always @(posedge clk) begin
        if (!rst_n)
            prev_idx <= {BIN_ADDR_W{1'b0}};
        else if (in_valid)
            prev_idx <= cur_idx;
    end

    wire [DATA_WIDTH-1:0] abs_re = in_re[DATA_WIDTH-1] ? (~in_re + 1) : in_re;
    wire [DATA_WIDTH-1:0] abs_im = in_im[DATA_WIDTH-1] ? (~in_im + 1) : in_im;

    wire [DATA_WIDTH-1:0] mx = (abs_re > abs_im) ? abs_re : abs_im;
    wire [DATA_WIDTH-1:0] mn = (abs_re > abs_im) ? abs_im : abs_re;

    wire [2*DATA_WIDTH-1:0] prod_mx  = ALPHA_Q15 * mx;
    wire [2*DATA_WIDTH-1:0] prod_mn  = BETA_Q15  * mn;
    wire [2*DATA_WIDTH:0]   mag_full = prod_mx + prod_mn;

    localparam integer SHIFT = DATA_WIDTH - 1;

    function automatic [DATA_WIDTH-1:0] round_sat_unsigned;
        input [2*DATA_WIDTH:0] full;
        reg   [2*DATA_WIDTH:0] shifted;
        reg   [SHIFT-2:0]      lower_bits;
        begin
            lower_bits = full[SHIFT-2:0];

            if (full[SHIFT-1] == 1'b0) begin
                shifted = full >> SHIFT;
            end else if (lower_bits != 0) begin
                shifted = (full >> SHIFT) + 1;
            end else begin
                if (full[SHIFT] == 1'b0)
                    shifted = full >> SHIFT;
                else
                    shifted = (full >> SHIFT) + 1;
            end

            if (shifted > {DATA_WIDTH{1'b1}})
                round_sat_unsigned = {DATA_WIDTH{1'b1}};
            else
                round_sat_unsigned = shifted[DATA_WIDTH-1:0];
        end
    endfunction

    wire [DATA_WIDTH-1:0] mag_rounded = round_sat_unsigned(mag_full);

    function automatic [4:0] find_msb_pos;
        input [DATA_WIDTH-1:0] val;
        integer k;
        reg found;
        begin
            find_msb_pos = 5'd0;
            found = 1'b0;
            for (k = DATA_WIDTH-1; k >= 0; k = k - 1) begin
                if (!found && val[k]) begin
                    find_msb_pos = k[4:0];
                    found = 1'b1;
                end
            end
        end
    endfunction

    wire [4:0] msb_pos = find_msb_pos(mag_rounded);
    wire [DATA_WIDTH-1:0] normalized = mag_rounded << (DATA_WIDTH-1 - msb_pos);
    wire [7:0] frac_q8 = normalized[DATA_WIDTH-2 -: 8];
    wire signed [7:0] int_part = $signed({1'b0, msb_pos}) - SHIFT[7:0];
    wire signed [15:0] log2_q8_8 = (mag_rounded == 0)
                                    ? -16'sd32768  // sentinel cho log2(0) = -vo cung
                                    : ($signed({int_part, 8'd0}) + $signed({8'd0, frac_q8}));

    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid     <= 1'b0;
            out_magnitude <= {DATA_WIDTH{1'b0}};
            out_bin_idx   <= {BIN_ADDR_W{1'b0}};
            out_sof       <= 1'b0;
            out_last      <= 1'b0;
            out_mag_log2  <= 16'sd0;
        end else begin
            out_valid     <= in_valid;
            out_magnitude <= mag_rounded;
            out_bin_idx   <= cur_idx;
            out_sof       <= in_valid && in_sof;
            out_last      <= in_valid && in_last;
            out_mag_log2  <= ENABLE_LOG ? log2_q8_8 : 16'sd0;
        end
    end

endmodule
