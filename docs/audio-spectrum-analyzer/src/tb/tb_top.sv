`timescale 1ns / 1ps

module tb_top;
    localparam int N=256, DW=16, FS=48000, TONE_BIN=10, FRAMES=10;

    logic clk=0, rst_n=0, start=0;
    always #5 clk=~clk;

    logic                 s_tvalid=0;
    logic signed [DW-1:0] s_tdata=0;
    logic                 s_tready;
    logic                 m_tvalid, m_tlast, m_tready=1'b1;
    logic [DW-1:0]        m_tdata;
    logic [0:0]           m_tuser;
    logic                 pk_valid, ctrl_busy, ctrl_en;
    logic [DW-1:0]        pk_mag;
    logic [$clog2(N/2)-1:0] pk_bin;
    logic [31:0]          fcount;

    fft_analyzer_ip #(.N(N), .DATA_WIDTH(DW), .FFT_LATENCY(291)) dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .s_axis_tvalid(s_tvalid), .s_axis_tdata(s_tdata), .s_axis_tready(s_tready),
        .m_axis_tvalid(m_tvalid), .m_axis_tdata(m_tdata), .m_axis_tlast(m_tlast),
        .m_axis_tuser(m_tuser), .m_axis_tready(m_tready),
        .peak_valid(pk_valid), .peak_magnitude(pk_mag), .peak_bin_idx(pk_bin),
        .busy(ctrl_busy), .core_en(ctrl_en), .frame_count(fcount)
    );

    logic signed [DW-1:0] tone [0:N-1];
    integer n;
    initial for (n=0;n<N;n=n+1)
        tone[n] = $rtoi(0.7*$cos(2.0*3.14159265358979*TONE_BIN*n/N)*32767.0);
    integer last_peak = -1; integer npk = 0;
    always @(posedge clk) if (rst_n && pk_valid) begin
        last_peak <= pk_bin; npk <= npk+1;
        $display("TB t=%0t  peak_bin=%0d  peak_mag=%0d  frame_count=%0d", $time, pk_bin, pk_mag, fcount);
    end

    integer f, i;
    initial begin
        rst_n=0; start=0; s_tvalid=0; s_tdata=0;
        repeat (8) @(posedge clk);
        rst_n=1; start=1; @(posedge clk);

        for (f=0; f<FRAMES; f=f+1) begin
            for (i=0; i<N; i=i+1) begin
                s_tvalid <= 1'b1; s_tdata <= tone[i];
                @(posedge clk);
                while (!s_tready) @(posedge clk);
            end
        end
        s_tvalid <= 1'b0;
        repeat (600) @(posedge clk);

        $display("TB total peak_valid = %0d, peak_bin last = %0d (expected %0d)", npk, last_peak, TONE_BIN);
        if (npk>0 && last_peak==TONE_BIN) $display("TB: PASS ");
        else $display("TB: FAIL (kiem tone/latency/framing)");
        $finish;
    end

    initial begin #4000000; $display("TB TIMEOUT"); $finish; end
endmodule
