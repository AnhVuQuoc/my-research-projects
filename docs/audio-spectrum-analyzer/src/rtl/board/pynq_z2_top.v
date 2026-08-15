`timescale 1ns / 1ps

module pynq_z2_top #(
    parameter integer N          = 256,
    parameter integer DATA_WIDTH = 16,
    parameter integer FFT_LATENCY= 291
)(
    input  wire        clk,
    input  wire [1:0]  sw,
    input  wire [3:0]  btn,
    output wire [3:0]  led,
    output wire [2:0]  led4_rgb,
    output wire [2:0]  led5_rgb
);
 
    wire btn0_s, sw0_s;
    wire rst_n_pre = ~btn[0];
    reg  [7:0] rst_cnt = 8'h00;
    reg        rst_n_r = 1'b0;
    always @(posedge clk) begin
        if (!rst_n_pre) begin rst_cnt <= 8'h00; rst_n_r <= 1'b0; end
        else if (rst_cnt != 8'hFF) begin rst_cnt <= rst_cnt + 1'b1; rst_n_r <= 1'b0; end
        else rst_n_r <= 1'b1;
    end
    wire rst_n = rst_n_r;

    sync_2ff u_sync_sw0 (.clk(clk), .rst_n(rst_n), .async_in(sw[0]), .sync_out(sw0_s));

    wire                         tone_valid;
    wire signed [DATA_WIDTH-1:0] tone_data;
    tone_player #(.N(N), .DATA_WIDTH(DATA_WIDTH), .CLK_PER_SAMPLE(2604),
                  .TONE_FILE("tv_input.mem")) u_tone (
        .clk(clk), .rst_n(rst_n), .en(1'b1),
        .out_valid(tone_valid), .out_data(tone_data)
    );

    wire                    s_tready, m_tvalid, m_tlast;
    wire [DATA_WIDTH-1:0]   m_tdata;
    wire [0:0]              m_tuser;
    wire                    pk_valid, busy_w, coren_w;
    wire [DATA_WIDTH-1:0]   pk_mag;
    wire [$clog2(N/2)-1:0]  pk_bin;
    wire [31:0]             fcount;

    fft_analyzer_ip #(
        .N(N), .DATA_WIDTH(DATA_WIDTH), .FFT_LATENCY(FFT_LATENCY)
    ) u_ip (
        .clk(clk), .rst_n(rst_n), .start(1'b1),
        .s_axis_tvalid(tone_valid), .s_axis_tdata(tone_data), .s_axis_tready(s_tready),
        .m_axis_tvalid(m_tvalid), .m_axis_tdata(m_tdata), .m_axis_tlast(m_tlast),
        .m_axis_tuser(m_tuser), .m_axis_tready(1'b1),
        .peak_valid(pk_valid), .peak_magnitude(pk_mag), .peak_bin_idx(pk_bin),
        .busy(busy_w), .core_en(coren_w), .frame_count(fcount)
    );

    reg [6:0] pk_bin_hold;
    reg       pk_blink;
    always @(posedge clk) begin
        if (!rst_n) begin pk_bin_hold <= 7'd0; pk_blink <= 1'b0; end
        else if (pk_valid) begin
            pk_bin_hold <= pk_bin;
            pk_blink    <= ~pk_blink;
        end
    end

    assign led = sw0_s ? {1'b0, pk_bin_hold[6:4]}
                       : pk_bin_hold[3:0];

    assign led4_rgb = {1'b0, busy_w, 1'b0};
    assign led5_rgb = {pk_blink, 1'b0, 1'b0};
endmodule
