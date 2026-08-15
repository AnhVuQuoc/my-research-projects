`timescale 1ns / 1ps

module butterfly_r2_stage #(
    parameter integer N          = 256,
    parameter integer DATA_WIDTH = 16,
    parameter integer J          = 0,
    parameter integer SCALE_EN   = 1
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          in_valid,
    input  wire signed [DATA_WIDTH-1:0]  in_re,
    input  wire signed [DATA_WIDTH-1:0]  in_im,
    input  wire                          in_sof,

    output reg                           out_valid,
    output reg  signed [DATA_WIDTH-1:0]  out_re,
    output reg  signed [DATA_WIDTH-1:0]  out_im,
    output reg                           out_sof,
    output reg                           sel_o,
    output reg  [$clog2(N)-1:0]          cnt_o
);
    localparam integer LOG2N     = $clog2(N);
    localparam integer DELAY_LEN = N >> (J + 1);
    localparam integer ADDR_W    = LOG2N;
    localparam integer SEL_BIT   = (LOG2N - 1) - J;
    localparam [ADDR_W-1:0] INHALF_MASK = DELAY_LEN - 1;

    reg  [ADDR_W-1:0] cnt;
    wire [ADDR_W-1:0] cnt_cur = in_sof ? {ADDR_W{1'b0}} : (cnt + 1'b1);
    wire              sel      = cnt_cur[SEL_BIT];
    wire [ADDR_W-1:0] inhalf   = cnt_cur & INHALF_MASK;

    reg signed [DATA_WIDTH-1:0] dl_re [0:DELAY_LEN-1];
    reg signed [DATA_WIDTH-1:0] dl_im [0:DELAY_LEN-1];
    wire signed [DATA_WIDTH-1:0] d_re = dl_re[0];
    wire signed [DATA_WIDTH-1:0] d_im = dl_im[0];

    wire signed [DATA_WIDTH:0] s_re = $signed({d_re[DATA_WIDTH-1],d_re}) + $signed({in_re[DATA_WIDTH-1],in_re});
    wire signed [DATA_WIDTH:0] s_im = $signed({d_im[DATA_WIDTH-1],d_im}) + $signed({in_im[DATA_WIDTH-1],in_im});
    wire signed [DATA_WIDTH:0] f_re = $signed({d_re[DATA_WIDTH-1],d_re}) - $signed({in_re[DATA_WIDTH-1],in_re});
    wire signed [DATA_WIDTH:0] f_im = $signed({d_im[DATA_WIDTH-1],d_im}) - $signed({in_im[DATA_WIDTH-1],in_im});

    function automatic signed [DATA_WIDTH-1:0] scale_or_sat;
        input signed [DATA_WIDTH:0] full;
        reg   signed [DATA_WIDTH:0] q;
        begin
            if (SCALE_EN) begin
                if (full[0] == 1'b0)         q = full >>> 1;
                else if (full[1] == 1'b0)    q = full >>> 1;
                else                         q = (full >>> 1) + 1;
                scale_or_sat = q[DATA_WIDTH-1:0];
            end else begin
                if (full > $signed({1'b0,{(DATA_WIDTH-1){1'b1}}}))
                    scale_or_sat = {1'b0,{(DATA_WIDTH-1){1'b1}}};
                else if (full < $signed({1'b1,{(DATA_WIDTH-1){1'b0}}}))
                    scale_or_sat = {1'b1,{(DATA_WIDTH-1){1'b0}}};
                else
                    scale_or_sat = full[DATA_WIDTH-1:0];
            end
        end
    endfunction

    wire signed [DATA_WIDTH-1:0] sum_re  = scale_or_sat(s_re);
    wire signed [DATA_WIDTH-1:0] sum_im  = scale_or_sat(s_im);
    wire signed [DATA_WIDTH-1:0] diff_re = scale_or_sat(f_re);
    wire signed [DATA_WIDTH-1:0] diff_im = scale_or_sat(f_im);

    wire signed [DATA_WIDTH-1:0] o_re_n = sel ? sum_re  : d_re;
    wire signed [DATA_WIDTH-1:0] o_im_n = sel ? sum_im  : d_im;
    wire signed [DATA_WIDTH-1:0] to_re  = sel ? diff_re : in_re;
    wire signed [DATA_WIDTH-1:0] to_im  = sel ? diff_im : in_im;

    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt<={ADDR_W{1'b0}}; out_valid<=1'b0; out_re<=0; out_im<=0;
            out_sof<=1'b0; sel_o<=1'b0; cnt_o<={ADDR_W{1'b0}};
            for (i=0;i<DELAY_LEN;i=i+1) begin dl_re[i]<=0; dl_im[i]<=0; end
        end else begin
            out_valid <= in_valid;
            out_sof   <= in_valid && in_sof;
            if (in_valid) begin
                cnt    <= cnt_cur;
                out_re <= o_re_n;
                out_im <= o_im_n;
                sel_o  <= sel;
                cnt_o  <= inhalf;
                for (i=0;i<DELAY_LEN-1;i=i+1) begin
                    dl_re[i]<=dl_re[i+1]; dl_im[i]<=dl_im[i+1];
                end
                dl_re[DELAY_LEN-1]<=to_re; dl_im[DELAY_LEN-1]<=to_im;
            end
        end
    end
endmodule
