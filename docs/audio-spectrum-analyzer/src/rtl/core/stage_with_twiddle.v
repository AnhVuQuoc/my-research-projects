`timescale 1ns / 1ps

module stage_with_twiddle #(
    parameter integer N           = 256,
    parameter integer DATA_WIDTH  = 16,
    parameter integer J           = 0,
    parameter integer SCALE_EN    = 1,
    parameter integer HAS_TWIDDLE = 1,
    parameter         RE_FILE     = "twiddle_re.mem",
    parameter         IM_FILE     = "twiddle_im.mem"
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          in_valid,
    input  wire signed [DATA_WIDTH-1:0]  in_re,
    input  wire signed [DATA_WIDTH-1:0]  in_im,
    input  wire                          in_sof,

    output wire                          out_valid,
    output wire signed [DATA_WIDTH-1:0]  out_re,
    output wire signed [DATA_WIDTH-1:0]  out_im,
    output wire                          out_sof
);
    localparam integer LOG2N  = $clog2(N);
    localparam integer ADDR_W = LOG2N;
    localparam integer TW_AW  = $clog2(N/2);   // 7

    wire                        bf_valid, bf_sof, bf_sel;
    wire signed [DATA_WIDTH-1:0] bf_re, bf_im;
    wire [ADDR_W-1:0]           bf_cnt;

    butterfly_r2_stage #(
        .N(N), .DATA_WIDTH(DATA_WIDTH), .J(J), .SCALE_EN(SCALE_EN)
    ) u_bf (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_re(in_re), .in_im(in_im), .in_sof(in_sof),
        .out_valid(bf_valid), .out_re(bf_re), .out_im(bf_im), .out_sof(bf_sof),
        .sel_o(bf_sel), .cnt_o(bf_cnt)
    );

    generate
    if (HAS_TWIDDLE == 0) begin : g_notw
        assign out_valid = bf_valid;
        assign out_re    = bf_re;
        assign out_im    = bf_im;
        assign out_sof   = bf_sof;
    end else begin : g_tw
        wire en = bf_valid;

        wire [TW_AW-1:0] tw_addr = (bf_cnt << J);
        wire signed [DATA_WIDTH-1:0] tw_re, tw_im;
        twiddle_rom #(.N(N), .DATA_WIDTH(DATA_WIDTH), .RE_FILE(RE_FILE), .IM_FILE(IM_FILE)) u_rom (
            .clk(clk), .en(en), .addr(tw_addr), .tw_re(tw_re), .tw_im(tw_im)
        );
        reg signed [DATA_WIDTH-1:0] bf_re_d1, bf_im_d1;
        always @(posedge clk) begin
            if (!rst_n)   begin bf_re_d1<=0; bf_im_d1<=0; end
            else if (en)  begin bf_re_d1<=bf_re; bf_im_d1<=bf_im; end
        end
        wire signed [DATA_WIDTH-1:0] mul_re, mul_im;
        complex_multiplier #(.DW(DATA_WIDTH)) u_cmul (
            .clk(clk), .rst_n(rst_n), .en(en),
            .ar(bf_re_d1), .ai(bf_im_d1), .br(tw_re), .bi(tw_im),
            .pr(mul_re),   .pi(mul_im)
        );

        reg signed [DATA_WIDTH-1:0] byp_re [0:3];
        reg signed [DATA_WIDTH-1:0] byp_im [0:3];
        reg [3:0] byp_sel, byp_sof;
        integer i;
        always @(posedge clk) begin
            if (!rst_n) begin
                for (i=0;i<4;i=i+1) begin byp_re[i]<=0; byp_im[i]<=0; end
                byp_sel<=0; byp_sof<=0;
            end else if (en) begin
                byp_re[0]<=bf_re;  byp_im[0]<=bf_im;
                byp_re[1]<=byp_re[0]; byp_im[1]<=byp_im[0];
                byp_re[2]<=byp_re[1]; byp_im[2]<=byp_im[1];
                byp_re[3]<=byp_re[2]; byp_im[3]<=byp_im[2];
                byp_sel<={byp_sel[2:0], bf_sel};
                byp_sof<={byp_sof[2:0], bf_sof};
            end
        end
        wire sel_d4 = byp_sel[3];
        assign out_re    = sel_d4 ? byp_re[3] : mul_re;
        assign out_im    = sel_d4 ? byp_im[3] : mul_im;
        assign out_valid = bf_valid;
        assign out_sof   = byp_sof[3];
    end
    endgenerate
endmodule
