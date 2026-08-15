`timescale 1ns / 1ps

module peak_detector #(
    parameter integer NUM_BINS   = 128,
    parameter integer DATA_WIDTH = 16
)(
    input  wire                          clk,
    input  wire                          rst_n,

    input  wire                          in_valid,
    input  wire [DATA_WIDTH-1:0]         in_magnitude,
    input  wire [$clog2(NUM_BINS)-1:0]   in_bin_idx,
    input  wire                          in_sof,
    input  wire                          in_last,

    output reg                           peak_valid,
    output reg  [DATA_WIDTH-1:0]         peak_magnitude,
    output reg  [$clog2(NUM_BINS)-1:0]   peak_bin_idx
);

    localparam integer BIN_ADDR_W = $clog2(NUM_BINS);

    reg [DATA_WIDTH-1:0]  running_max;
    reg [BIN_ADDR_W-1:0]  running_idx;
    reg                   frame_done_pending;

    always @(posedge clk) begin
        if (!rst_n) begin
            running_max        <= {DATA_WIDTH{1'b0}};
            running_idx        <= {BIN_ADDR_W{1'b0}};
            frame_done_pending <= 1'b0;

            peak_valid          <= 1'b0;
            peak_magnitude       <= {DATA_WIDTH{1'b0}};
            peak_bin_idx         <= {BIN_ADDR_W{1'b0}};
        end else begin
            peak_valid <= 1'b0;

            if (in_valid) begin
                if (in_sof) begin
                    running_max <= in_magnitude;
                    running_idx <= in_bin_idx;
                end else if (in_magnitude > running_max) begin
                    running_max <= in_magnitude;
                    running_idx <= in_bin_idx;
                end

                if (in_last) begin

                    frame_done_pending <= 1'b1;
                end
            end

            if (frame_done_pending) begin
                peak_valid     <= 1'b1;
                peak_magnitude <= running_max;
                peak_bin_idx   <= running_idx;
                frame_done_pending <= 1'b0;
            end
        end
    end

endmodule
