`timescale 1ns / 1ps

module tb_bin_ram_output;
    localparam integer N     = 256;
    localparam integer DW    = 16;
    localparam integer HALF  = N/2;
    localparam integer TOTAL_IN  = 1024;
    localparam integer TOTAL_ALL = 1164;

    reg clk = 0, rst_n = 0, in_valid = 0, in_sof = 0, in_last = 0;
    reg [DW-1:0] in_magnitude = 0;

    wire out_valid, out_sof, out_last;
    wire [DW-1:0] out_magnitude;
    wire [$clog2(N)-1:0] out_bin_idx;

    bin_ram_output #(.N(N), .DATA_WIDTH(DW)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_magnitude(in_magnitude), .in_sof(in_sof), .in_last(in_last),
        .out_valid(out_valid), .out_magnitude(out_magnitude), .out_bin_idx(out_bin_idx),
        .out_sof(out_sof), .out_last(out_last)
    );

    always #5 clk = ~clk;

    function [7:0] bitrev8;
        input [7:0] x;
        integer b;
        begin
            for (b = 0; b < 8; b = b + 1) bitrev8[b] = x[7-b];
        end
    endfunction

    reg [DW-1:0] vin_mag  [0:TOTAL_IN-1];
    reg          vin_sof  [0:TOTAL_IN-1];
    reg          vin_last [0:TOTAL_IN-1];

    reg          vexp_valid[0:TOTAL_ALL-1];
    reg [DW-1:0] vexp_mag  [0:TOTAL_ALL-1];
    reg [7:0]    vexp_bin  [0:TOTAL_ALL-1];
    reg          vexp_sof  [0:TOTAL_ALL-1];
    reg          vexp_last [0:TOTAL_ALL-1];

    integer t;
    integer mism_valid, mism_mag, mism_bin, mism_sof, mism_last;
    integer mark_check_count, mark_check_fail;

    initial begin
        $readmemh("br_in_mag.mem",  vin_mag);
        $readmemb("br_in_sof.mem",  vin_sof);
        $readmemb("br_in_last.mem", vin_last);

        $readmemb("br_exp_valid.mem", vexp_valid);
        $readmemh("br_exp_mag.mem",   vexp_mag);
        $readmemh("br_exp_bin.mem",   vexp_bin);
        $readmemb("br_exp_sof.mem",   vexp_sof);
        $readmemb("br_exp_last.mem",  vexp_last);

        mism_valid=0; mism_mag=0; mism_bin=0; mism_sof=0; mism_last=0;
        mark_check_count=0; mark_check_fail=0;

        rst_n = 0; in_valid = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        for (t = 0; t < TOTAL_ALL; t = t + 1) begin
            if (t < TOTAL_IN) begin
                in_magnitude <= vin_mag[t];
                in_sof       <= vin_sof[t];
                in_last      <= vin_last[t];
                in_valid     <= 1'b1;
            end else begin
                in_magnitude <= {DW{1'b0}};
                in_sof       <= 1'b0;
                in_last      <= 1'b0;
                in_valid     <= 1'b0;
            end
            @(posedge clk);
            #1;

            if (out_valid !== vexp_valid[t]) mism_valid = mism_valid + 1;
            if (out_valid && vexp_valid[t] && (out_magnitude !== vexp_mag[t])) begin
                mism_mag = mism_mag + 1;
                if (mism_mag <= 8)
                    $display("TB MISMATCH magnitude @cycle %0d: rtl=%0d exp=%0d", t, out_magnitude, vexp_mag[t]);
            end
            if (out_bin_idx !== vexp_bin[t]) mism_bin = mism_bin + 1;
            if (out_sof !== vexp_sof[t]) mism_sof = mism_sof + 1;
            if (out_last !== vexp_last[t]) mism_last = mism_last + 1;

            if (out_valid && (t >= TOTAL_IN - 40) && (t < TOTAL_ALL)) begin
                mark_check_count = mark_check_count + 1;
                if (out_magnitude[7:0] !== bitrev8(out_bin_idx[7:0])) begin
                    mark_check_fail = mark_check_fail + 1;
                    if (mark_check_fail <= 5)
                        $display("TB KIEM TRUC QUAN SAI @cycle %0d: bin=%0d magnitude=%0d (ky vong bitrev(bin)=%0d)",
                                  t, out_bin_idx, out_magnitude, bitrev8(out_bin_idx[7:0]));
                end
            end
        end

        $display("TB Da kiem %0d chu ky (4 khung, khung cuoi la khung danh dau magnitude[a]=a)", TOTAL_ALL);
        $display("TB Sai lech (mo hinh Python): valid=%0d magnitude=%0d bin_idx=%0d sof=%0d last=%0d",
                  mism_valid, mism_mag, mism_bin, mism_sof, mism_last);
        $display("TB Kiem truc quan bitrev (khung danh dau): %0d mau kiem, %0d sai lech", mark_check_count, mark_check_fail);

        if (mism_valid==0 && mism_mag==0 && mism_bin==0 && mism_sof==0 && mism_last==0 && mark_check_fail==0)
            $display("TB: PASS (bin_ram_output bit-exact + kiem truc quan bitrev dung)");
        else
            $display("TB: FAIL");

        $finish;
    end
endmodule
